// imports...
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:project5/service/cart_provider.dart';
import 'package:project5/uiscrren/AddressScreen.dart';
import 'HomePage.dart';
import 'CategoriesScreen.dart';


class CartScreen extends ConsumerStatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  int _selectedIndex = 2;
  bool _showLoader = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showLoader = false;
      });
    });
  }

  void _onNavTapped(int index) {
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

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> createShareCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String code = _generateRandomCode(10);
    await FirebaseFirestore.instance.collection('UserDetail').doc(user.uid).set(
      {'sharedCartCode': code},
      SetOptions(merge: true),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Generated Code"),
        content: Row(
          children: [
            Expanded(
              child: SelectableText(code, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.green),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Code copied to clipboard")),
                );
              },
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  Future<void> joinSharedCart(String enteredCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('UserDetail')
        .where('sharedCartCode', isEqualTo: enteredCode)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final matchedUser = snapshot.docs.first;
      final matchedUid = matchedUser.id;

      if (matchedUid == user.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can't enter your own code.")),
        );
        return;
      }

      final userDetailDoc = await FirebaseFirestore.instance.collection('UserDetail').doc(user.uid).get();
      final userData = userDetailDoc.data();
      final matchedUserData = matchedUser.data();

      final userName = userData?['name'] ?? 'Unknown';
      final userMobile = userData?['mobile'] ?? 'N/A';
      final matchedUserName = matchedUserData['name'] ?? 'Unknown';
      final matchedUserMobile = matchedUserData['mobile'] ?? 'N/A';
      final sharedCartCode = enteredCode;

      // 🔁 Link both users in their individual documents
      await FirebaseFirestore.instance.collection('UserDetail').doc(user.uid).set(
        {'sharedWith': matchedUid},
        SetOptions(merge: true),
      );
      await FirebaseFirestore.instance.collection('UserDetail').doc(matchedUid).set(
        {'sharedWith': user.uid},
        SetOptions(merge: true),
      );

      // ✅ Save full details in SharedCode collection
      await FirebaseFirestore.instance.collection('SharedCode').add({
        'sharedCartCode': sharedCartCode,
        'sender': {
          'uid': matchedUid,
          'name': matchedUserName,
          'mobile': matchedUserMobile,
        },
        'receiver': {
          'uid': user.uid,
          'name': userName,
          'mobile': userMobile,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shared cart linked successfully!")),
      );

      // Optionally: Sync cart logic here if needed
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user found with that code.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    double totalPrice = 0;
    cartState.cartItems.forEach((_, cartItem) {
      final variant = cartItem.variant;
      final discountedPrice = variant.price - (variant.price * (variant.discount / 100));
      totalPrice += discountedPrice * cartItem.quantity;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shopping Cart", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'generate') {
                await createShareCode();
              } else if (value == 'enter') {
                final controller = TextEditingController();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Enter Shared Cart Code"),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: "Enter code here"),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          joinSharedCart(controller.text.trim());
                        },
                        child: const Text("Submit"),
                      ),
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'generate', child: Text("Generate Code")),
              const PopupMenuItem(value: 'enter', child: Text("Enter Code")),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.green.shade100,
      body: Stack(
        children: [
          _showLoader
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SpinKitThreeBounce(color: Colors.white, size: 30),
                SizedBox(height: 10),
                Text("loading...", style: TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          )
              : cartState.isLoading
              ? const Center(child: SpinKitThreeBounce(color: Colors.white70, size: 30))
              : cartState.cartItems.isEmpty
              ? const Center(child: Text("Your cart is empty", style: TextStyle(fontSize: 20)))
              : Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: ListView.builder(
              itemCount: cartState.cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = cartState.cartItems.values.elementAt(index);
                final product = cartItem.product;
                final variant = cartItem.variant;
                final discountedPrice = variant.price - (variant.price * (variant.discount / 100));

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Image.network(product.image, width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(product.name),
                    subtitle: Text(
                      "₹${discountedPrice.toStringAsFixed(2)} x ${cartItem.quantity} (${variant.quantity})",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
                          onPressed: () => cartNotifier.decrementQuantity(product, variant),
                        ),
                        Text(cartItem.quantity.toString(), style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () => cartNotifier.incrementQuantity(product, variant),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_showLoader && !cartState.isLoading && cartState.cartItems.isNotEmpty)
            Positioned(
              bottom: 5,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: ₹${totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Order Now"),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                          ),
                          builder: (context) => FractionallySizedBox(
                            heightFactor: 0.75,
                            child: AddressScreen(),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
        ],
      ),
    );
  }
}
