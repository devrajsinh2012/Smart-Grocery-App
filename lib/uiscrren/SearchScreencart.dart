import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project5/service/product_model.dart';
import 'package:project5/uiscrren/ProductDetailScreen.dart';
import '../service/firestore_service.dart';

class SearchScreenCart extends ConsumerStatefulWidget {
  final List<Product> allProducts;
  final String selectedCategory;

  const SearchScreenCart({super.key, required this.allProducts, required this.selectedCategory});

  @override
  ConsumerState<SearchScreenCart> createState() => _SearchScreenCartState();
}

class _SearchScreenCartState extends ConsumerState<SearchScreenCart> {
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
        product.category.toLowerCase() == widget.selectedCategory.toLowerCase() &&
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
            padding: EdgeInsets.only(left: 20, bottom: 2),
            child: TextField(
              controller: searchController,
              autofocus: true,
              decoration: InputDecoration(
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
          return ListTile(
            leading: Image.network(filteredProducts[index].image,
                width: 50, height: 50, fit: BoxFit.cover),
            title: Text(filteredProducts[index].name),
            onTap: () {
              // Navigate to ProductDetailScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailScreen(product: filteredProducts[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
