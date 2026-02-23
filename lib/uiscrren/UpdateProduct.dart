import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Updateproduct extends StatefulWidget {
  const Updateproduct({super.key});

  @override
  State<Updateproduct> createState() => _UpdateproductState();
}

class _UpdateproductState extends State<Updateproduct> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  List<Map<String, dynamic>> variants = [];

  bool isLoading = false;
  bool productFound = false;

  Future<void> searchProduct() async {
    setState(() {
      isLoading = true;
      productFound = false;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: searchController.text)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var productData = snapshot.docs.first.data() as Map<String, dynamic>;

        nameController.text = productData['name'];
        idController.text = productData['id'];
        categoryController.text = productData['category'];
        aboutController.text = productData['about'];

        variants = List<Map<String, dynamic>>.from(productData['variants'].map((v) {
          return {
            'price': TextEditingController(text: v['price'].toString()),
            'quantity': TextEditingController(text: v['quantity']),
            'discount': TextEditingController(text: v['discount'].toString()),
            'images': List<TextEditingController>.from(v['images'].map<TextEditingController>((img) => TextEditingController(text: img))),
          };
        }));

        setState(() {
          productFound = true;
        });
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

  Future<void> updateProduct() async {
    List<Map<String, dynamic>> updatedVariants = variants.map((variant) {
      return {
        'price': int.parse(variant['price'].text),
        'quantity': variant['quantity'].text,
        'discount': int.parse(variant['discount'].text),
        'images': variant['images'].map((c) => c.text).toList(),
      };
    }).toList();

    await FirebaseFirestore.instance
        .collection('products')
        .doc(idController.text)
        .update({
      'name': nameController.text,
      'id': idController.text,
      'category': categoryController.text,
      'about': aboutController.text,
      'variants': updatedVariants,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Product updated successfully")),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget buildVariantCard(int index) {
    final variant = variants[index];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Variant ${index + 1}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildTextField("Price", variant['price'],
                keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            buildTextField("Quantity", variant['quantity']),
            const SizedBox(height: 10),
            buildTextField("Discount", variant['discount'],
                keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Image URLs",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 8),
            ...variant['images'].asMap().entries.map((img) {
              return Row(
                children: [
                  Expanded(
                    child: buildTextField(
                        "Image URL ${img.key + 1}", img.value),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        variant['images'].removeAt(img.key);
                      });
                    },
                  )
                ],
              );
            }).toList(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Image"),
                onPressed: () {
                  setState(() {
                    variant['images'].add(TextEditingController());
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        title: const Text(
          "Update Product",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => searchProduct(),
              decoration: InputDecoration(
                hintText: "Search Product by Name",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitThreeBounce(
                    color: Colors.white,
                    size: 30.0,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Loading...",
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ],
              ),
            )
                : productFound
                ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildTextField("Product Name", nameController),
                  const SizedBox(height: 10),
                  buildTextField("Product ID", idController),
                  const SizedBox(height: 10),
                  buildTextField("Category", categoryController),
                  const SizedBox(height: 10),
                  buildTextField("About", aboutController),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    "Variants",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...variants
                      .asMap()
                      .entries
                      .map((e) => buildVariantCard(e.key)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.update, color: Colors.white),
                    label: const Text("Update Product", style: TextStyle(color: Colors.white)),
                    onPressed: updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            )
                : const Center(
              child: Text("Search for a product to update."),
            ),
          ),
        ],
      ),
    );
  }
}
