import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:project5/uiscrren/OrderHistory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../service/firestore_service.dart';
import '../service/product_model.dart';
import 'sign_in.dart';
import 'ProfileScreen.dart';
import 'Feedbackscreen.dart';
import '../service/CategoryButton.dart';
import 'CartScreen.dart';
import 'CategoriesScreen.dart';
import 'SearchScreen.dart';
import 'ProductDetailScreen.dart'; // <-- make sure this is your detail screen import

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String name = '';
  String _email = '';
  String? _userLocation;
  bool _showLoader = true;
  bool _isLoadingLocation = true;
  String? _savedLocation;

  User? currentUser;

  final FirestoreService _firestoreService = FirestoreService();
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  List<Product> topDiscountProducts = [];

  final List<String> _adImages = [
    'assets/images/download.jpeg',
    'assets/images/download.jpeg',
    'assets/images/download.jpeg',
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadStoredLocation();
    fetchProducts();
    _loadSavedLocation();
    currentUser = FirebaseAuth.instance.currentUser;
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showLoader = false;
      });
    });
  }

  Future<void> _loadSavedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? location = prefs.getString("user_location");
    setState(() {
      _savedLocation = location;
      _isLoadingLocation = false;
    });
  }

  Future<void> _loadStoredLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userLocation = prefs.getString("user_location");
    });
  }

  Future<void> fetchProducts() async {
    List<Product> products = await _firestoreService.fetchAllProducts();
    List<Product> discountProducts = products.where((product) {
      if (product.variants.isNotEmpty) {
        return product.variants.any((variant) => variant.discount > 30);
      }
      return false;
    }).toList();

    setState(() {
      allProducts = products;
      filteredProducts = products;
      topDiscountProducts = discountProducts;
    });
  }

  void _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email ?? "No email found";
        if (user.displayName != null) {
          final parts = user.displayName!.split('|');
          if (parts.length == 2) {
            name = parts[0];
          } else {
            name = user.displayName!;
          }
        }
      });
    }
  }

  Future<void> _navigateToProfile() async {
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Profilescreen()),
    );
    if (updated == true) {
      _fetchUserData();
    }
  }

  void _logout(BuildContext context) async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
    );
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.green,
        titleSpacing: 0.0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Selected Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.location_on, color: Colors.white, size: 15),
              ],
            ),
            SizedBox(height: 4),
            _isLoadingLocation
                ? SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Text(
              _userLocation ?? "Location not found",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.account_circle, color: Colors.white, size: 30),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(allProducts: allProducts),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Row(
                children: [
                  Icon(Icons.person, size: 60, color: Colors.white),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Hi, $name", style: TextStyle(color: Colors.white, fontSize: 20)),
                      SizedBox(height: 5),
                      Text(_email, style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(leading: Icon(Icons.person), title: Text("Profile"), onTap: _navigateToProfile),
            ListTile(leading: Icon(Icons.comment), title: Text("Feedback"), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => Feedbackscreen()));
            }),
            ListTile(leading: Icon(Icons.history), title: Text("Order History"), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => Orderhistory()));
            }),
            ListTile(leading: Icon(Icons.logout), title: Text("Logout"), onTap: () => _logout(context)),
          ],
        ),
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
          : SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 180.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  autoPlayInterval: Duration(seconds: 5),
                ),
                items: _adImages.map((imagePath) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(imagePath, width: double.infinity, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 10),
              child: Text("Shop by Categories", style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 10),
            Container(
              height: 230,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CategoryButton(imagePath: 'assets/images/Fruits.jpg', label: 'Fruits'),
                      CategoryButton(imagePath: 'assets/images/vegetable.jpg', label: 'Vegetables'),
                      CategoryButton(imagePath: 'assets/images/bakery.jpg', label: 'Bakery'),
                      CategoryButton(imagePath: 'assets/images/Chips&Biscuit.jpg', label: 'Chips & Biscuit'),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CategoryButton(imagePath: 'assets/images/Atta,Rice,Dals&Sugar.jpg', label: 'Atta,Rice,Dals & Sugar'),
                      CategoryButton(imagePath: 'assets/images/Cold&HotBeverages.jpg', label: 'Cold & Hot Beverages'),
                      CategoryButton(imagePath: 'assets/images/Chocolate&IceCream.jpg', label: 'Chocolate &  Ice Cream'),
                      CategoryButton(imagePath: 'assets/images/InstantandFrozan.jpeg', label: 'Instant & Frozan'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (topDiscountProducts.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text("Top Discounts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: topDiscountProducts.length,
                      itemBuilder: (context, index) {
                        final product = topDiscountProducts[index];
                        final variant = product.variants.firstWhere(
                              (v) => v.discount > 30,
                          orElse: () => product.variants[0],
                        );

                        final double originalPrice = double.tryParse(variant.price.toString()) ?? 0;
                        final double discountPercent = double.tryParse(variant.discount.toString()) ?? 0;
                        final double discountedPrice = originalPrice - (originalPrice * discountPercent / 100);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Stack(
                              children: [
                                Container(
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                        child: Image.network(
                                          product.image,
                                          height: 110,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          variant.quantity,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Row(
                                          children: [
                                            Text(
                                              "₹${discountedPrice.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "₹${variant.price}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                decoration: TextDecoration.lineThrough,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Discount ribbon
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      "${variant.discount}% OFF",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
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
              )

          ],
        ),
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
