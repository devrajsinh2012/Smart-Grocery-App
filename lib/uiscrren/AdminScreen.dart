import 'package:flutter/material.dart';
import 'package:project5/uiscrren/AddProduct.dart';
import 'package:project5/uiscrren/RemoveProduct.dart';
import 'package:project5/uiscrren/UpdateProduct.dart';
import 'package:project5/uiscrren/sign_in.dart';

class Adminscreen extends StatefulWidget {
  const Adminscreen({super.key});

  @override
  State<Adminscreen> createState() => _AdminscreenState();
}

class _AdminscreenState extends State<Adminscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Admin",
          style: TextStyle(color: Colors.white),
        ),
        elevation: 2, // Add a subtle shadow to the app bar
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20), // Add some spacing
            SizedBox(
              width: 250, // Adjust width as needed
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Addproduct()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green, // Use primary color for text
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.green, width: 1), // Add a border
                  ),
                  elevation: 3, // Subtle shadow
                ),
                child: const Text(
                  'Add Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20), // Add some spacing
            SizedBox(
              width: 250, // Adjust width as needed
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Updateproduct()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green, // Use primary color for text
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.green, width: 1), // Add a border
                  ),
                  elevation: 3, // Subtle shadow
                ),
                child: const Text(
                  'Update Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20), // Add some spacing
            SizedBox(
              width: 250, // Adjust width as needed
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Removeproduct()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green, // Use primary color for text
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.green, width: 1), // Add a border
                  ),
                  elevation: 3, // Subtle shadow
                ),
                child: const Text(
                  'Remove Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}