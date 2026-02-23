import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Removeproduct extends StatefulWidget {
  const Removeproduct({super.key});

  @override
  State<Removeproduct> createState() => _RemoveproductState();
}

class _RemoveproductState extends State<Removeproduct> {
  final TextEditingController searchController = TextEditingController();
  Map<String, dynamic>? productData;
  String? docId;
  bool isLoading = false;

  Future<void> searchProduct() async {
    setState(() {
      isLoading = true;
      productData = null;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: searchController.text.trim())
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        productData = doc.data() as Map<String, dynamic>;
        docId = doc.id;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product not found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> removeVariant(int index) async {
    if (docId == null || productData == null) return;

    List<dynamic> variants = List.from(productData!['variants']);
    variants.removeAt(index);

    await FirebaseFirestore.instance.collection('products').doc(docId).update({
      'variants': variants,
    });

    setState(() {
      productData!['variants'] = variants;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Variant removed")),
    );
  }

  Future<void> removeFullProduct() async {
    if (docId == null) return;

    await FirebaseFirestore.instance.collection('products').doc(docId).delete();

    setState(() {
      productData = null;
      searchController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ Product deleted from Firestore")),
    );
  }

  Widget buildVariantCard(Map<String, dynamic> variant, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        title: Text("Quantity: ${variant['quantity']}"),
        subtitle: Text("Price: ₹${variant['price']} | Discount: ${variant['discount']}%"),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => removeVariant(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Remove Product", style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => searchProduct(),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  hintText: "Search Product by Name",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SpinKitThreeBounce(
              color: Colors.white,
              size: 30.0,
            ),
            SizedBox(height: 20),
            Text(
              "Loading...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )
            : productData != null
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Product Name: ${productData!['name']}",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Variants:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: productData!['variants'].length,
                itemBuilder: (context, index) =>
                    buildVariantCard(productData!['variants'][index], index),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text(
                  "Delete Entire Product",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => removeFullProduct(),
              ),
            ),
          ],
        )
            : const SizedBox(),
      ),
    );
  }
}
