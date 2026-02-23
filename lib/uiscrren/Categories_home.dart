import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project5/service/product_model.dart';
import 'package:project5/uiscrren/ProductDetailScreen.dart';
import '../service/firestore_service.dart';
import 'product_card.dart';
import 'CartScreen.dart';
import 'package:project5/service/cart_provider.dart';
import 'SearchScreencart.dart'; // Import the new SearchScreen

class CategoriesHome extends ConsumerStatefulWidget {
  final String categoryName;

  const CategoriesHome({super.key, required this.categoryName});

  @override
  ConsumerState<CategoriesHome> createState() => _CategoriesHomeState();
}

class _CategoriesHomeState extends ConsumerState<CategoriesHome> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    List<Product> products =
    await _firestoreService.fetchProductsByCategory(widget.categoryName);

    setState(() {
      allProducts = products;
      filteredProducts = products;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(widget.categoryName, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreenCart(allProducts: allProducts,selectedCategory: widget.categoryName,),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.green.shade100,
      body: Stack(
        children: [
          isLoading
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitThreeBounce(color: Colors.white70, size: 30),
                SizedBox(height: 10),
                Text("Loading...",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          )
              : filteredProducts.isEmpty
              ? const Center(
            child: Text("No products found",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          )
              : Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              itemCount: filteredProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(product: filteredProducts[index]),
                      ),
                    );
                  },
                  child: ProductCard(product: filteredProducts[index]),
                );
              },
            ),
          ),

          // Floating Cart Container (only if cart is not empty)
          Consumer(builder: (context, ref, child) {
            final totalItems = ref.watch(cartProvider).totalItemCount;

            return totalItems > 0
                ? Positioned(
              bottom: 30,
              right: 10,
              child: _buildFloatingCart(context, totalItems),
            )
                : const SizedBox(); // If cart is empty, don't show anything
          }),
        ],
      ),
    );
  }

  Widget _buildFloatingCart(BuildContext context, int totalItems) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CartScreen()),
        );
      },
      child: Container(
        width: 150,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.redAccent, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text(
              "$totalItems Products",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
