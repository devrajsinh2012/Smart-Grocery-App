import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project5/service/product_model.dart';
import 'package:project5/uiscrren/ProductDetailScreen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final List<Product> allProducts;

  const SearchScreen({super.key, required this.allProducts});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      searchProducts(searchController.text);
    });
  }

  void searchProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = [];
      } else {
        filteredProducts = widget.allProducts
            .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 2),
            child: TextField(
              controller: searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Search for product",
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
      body: filteredProducts.isEmpty
          ? const Center(
        child: Text(
          "No products found",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          : ListView.builder(
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          final imageUrl = product.image;

          return ListTile(
            leading: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image),
            )
                : const Icon(Icons.image_not_supported, size: 50),
            title: Text(product.name),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
