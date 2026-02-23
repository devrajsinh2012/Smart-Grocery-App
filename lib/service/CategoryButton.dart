import 'package:flutter/material.dart';
import 'package:project5/uiscrren/Categories_home.dart';

class CategoryButton extends StatelessWidget {
  final String imagePath;
  final String label;

  const CategoryButton({required this.imagePath, required this.label, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to CategoriesScreen when clicked
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CategoriesHome(categoryName: label)),
        );
      },
      child: Column(
        children: [
          Container(
            width: 80, // Set fixed width
            height: 80, // Set fixed height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 8), // Space between image and text
          SizedBox(
            width: 80, // Ensure text does not exceed the width of the image
            child: Text(
              label,
              maxLines: 1, // Ensure text stays in a single line
              overflow: TextOverflow.ellipsis, // Adds "..." if text is too long
              textAlign: TextAlign.center, // Align text to center
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
