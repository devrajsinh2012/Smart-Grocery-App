import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../service/firestore_service.dart';
import 'SearchScreen.dart';
import '../service/product_model.dart';
import 'HomePage.dart';
import 'CartScreen.dart';
import 'ProductDetailScreen.dart';

class Categoriesscreen extends StatefulWidget {
  @override
  State<Categoriesscreen> createState() => _CategoriesscreenState();
}

class _CategoriesscreenState extends State<Categoriesscreen> {
  int _selectedIndex = 1;
  bool _showLoader = true;

  List<String> categoryList = [];
  Map<String, List<Map<String, dynamic>>> itemsByCategory = {};

  final FirestoreService _firestoreService = FirestoreService();
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    fetchCategoriesAndItems();
    fetchProducts();
  }

  //For Search Bar Product Fetching
  Future<void> fetchProducts() async {
    List<Product> products = await _firestoreService.fetchAllProducts();

    setState(() {
      allProducts = products;
      filteredProducts = products;
    });
  }

  Future<void> fetchCategoriesAndItems() async {
    final snapshot = await FirebaseFirestore.instance.collection('products').get();

    final categories = snapshot.docs.map((doc) => doc['category'] as String).toSet().toList();

    Map<String, List<Map<String, dynamic>>> categoryItems = {};

    for (String category in categories) {
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .get();

      final items = itemsSnapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();

      categoryItems[category] = items;
    }

    setState(() {
      categoryList = categories;
      itemsByCategory = categoryItems;
      _showLoader = false;
    });
  }

  void _onNavTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _showLoader = true;
    });

    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Categoriesscreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CartScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("Categories", style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(allProducts: allProducts,),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.green.shade100,
      body: _showLoader
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitThreeBounce(color: Colors.white, size: 30),
            SizedBox(height: 10),
            Text("loading...", style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      )
          : ListView.builder(
        itemCount: categoryList.length,
        itemBuilder: (context, index) {
          final category = categoryList[index];
          final items = itemsByCategory[category] ?? [];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (items.isEmpty) Text("No items available.") else SizedBox(
                  height: 165,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, itemIndex) {
                      final item = items[itemIndex];
                      final image = (item['variants'] != null &&
                          item['variants'].isNotEmpty &&
                          item['variants'][0]['images'] != null &&
                          item['variants'][0]['images'].isNotEmpty)
                          ? item['variants'][0]['images'][0]
                          : '';

                      return GestureDetector(
                        onTap: () {
                          final product = Product.fromMap(item);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              image.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image,
                                  height: 80,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Icon(Icons.image_not_supported, size: 60),
                              SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                child: Text(
                                  item['name'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onNavTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
        ],
      ),
    );
  }
}