import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Addproduct extends StatefulWidget {
  const Addproduct({super.key});

  @override
  State<Addproduct> createState() => _AddProductState();
}

class _AddProductState extends State<Addproduct> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  List<Map<String, dynamic>> variants = [
    {
      'price': TextEditingController(),
      'quantity': TextEditingController(),
      'discount': TextEditingController(),
      'images': [TextEditingController()],
    }
  ];

  void addVariant() {
    setState(() {
      variants.add({
        'price': TextEditingController(),
        'quantity': TextEditingController(),
        'discount': TextEditingController(),
        'images': [TextEditingController()],
      });
    });
  }

  Future<void> uploadProduct() async {
    if (_formKey.currentState!.validate()) {
      List<Map<String, dynamic>> variantData = variants.map((variant) {
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
          .set({
        'name': nameController.text,
        'id': idController.text,
        'category': categoryController.text,
        'about': aboutController.text,
        'variants': variantData,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Product uploaded successfully")),
      );

      Navigator.pop(context);
    }
  }

  Widget buildVariantCard(int index) {
    final variant = variants[index];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text("Variant ${index + 1}",
                    style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (variants.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        variants.removeAt(index);
                      });
                    },
                  )
              ],
            ),
            const SizedBox(height: 10),
            buildTextField("Price", variant['price'],
                keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            buildTextField("Quantity", variant['quantity'],),
            const SizedBox(height: 10),
            buildTextField("Discount (%)", variant['discount'],
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Image URLs",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: variant['images'].length,
              itemBuilder: (_, imgIndex) {
                return Row(
                  children: [
                    Expanded(
                      child: buildTextField(
                        "Image URL ${imgIndex + 1}",
                        variant['images'][imgIndex],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          variant['images'].removeAt(imgIndex);
                        });
                      },
                    )
                  ],
                );
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Image URL"),
                onPressed: () {
                  setState(() {
                    variant['images'].add(TextEditingController());
                  });
                },
              ),
            ),
          ],
        ),
      ),
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
      validator: (value) => value!.isEmpty ? 'Enter $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        title: const Text("Add Product"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTextField("Product Name", nameController,),
              const SizedBox(height: 12),
              buildTextField("Product ID", idController,),
              const SizedBox(height: 12),
              buildTextField("Category", categoryController,),
              const SizedBox(height: 12),
              TextFormField(
                controller: aboutController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "About Product",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                value!.isEmpty ? 'Enter product description' : null,
              ),
              const SizedBox(height: 20),
              const Divider(height: 32),
              const Text(
                "Variants",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ...variants.asMap().entries.map((e) => buildVariantCard(e.key)),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add,color: Colors.white,),
                  label: const Text("Add Another Variant",style: TextStyle(color: Colors.white),),
                  onPressed: addVariant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload,color: Colors.white,),
                  label: const Text("Upload Product to Firestore",style: TextStyle(color: Colors.white),),
                  onPressed: uploadProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
