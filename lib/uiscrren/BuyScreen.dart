import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'CartScreen.dart';
import '../service/cart_provider.dart'; // Adjust path if needed

class Buyscreen extends ConsumerStatefulWidget {
  const Buyscreen({super.key});

  @override
  ConsumerState<Buyscreen> createState() => _BuyscreenState();
}

class _BuyscreenState extends ConsumerState<Buyscreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userDetails;
  List<dynamic> cartItems = [];
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserDetailsAndCart();
  }

  Future<void> fetchUserDetailsAndCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('UserDetail').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        userDetails = data;
        cartItems = List.from(data['cartItems'] ?? []);
        totalPrice = (data['totalCartPrice'] ?? 0.0).toDouble();
      });
    }
  }

  Future<void> confirmOrder() async {
    final user = _auth.currentUser;
    if (user == null || userDetails == null) return;

    try {
      final paymentMethod = userDetails!['paymentMethod'];

      if (paymentMethod == 'Cash On Delivery') {
        final List<Map<String, dynamic>> detailedItems = cartItems.map((item) {
          return {
            'name': item['name'],
            'quantity': item['quantity'],
            'price': item['price'],
            'discount': item['discount'],
            'totalPrice': double.parse(item['totalPrice'].toStringAsFixed(2)),
            'image': item['image'],
          };
        }).toList();

        await _firestore.collection('ItemBuy').add({
          'userId': user.uid,
          'name': userDetails?['name'] ?? '',
          'mobile': userDetails?['mobile'] ?? '',
          'email': userDetails?['email'] ?? '',
          'address': userDetails?['address'] ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'items': detailedItems,
          'totalPrice': double.parse(totalPrice.toStringAsFixed(2)),
          'status': 'Pending',
          'paymentMethod': paymentMethod,
        });

        // ✅ Clear cart using provider logic
        await ref.read(cartProvider.notifier).clearCartAfterOrder();

        Fluttertoast.showToast(
          msg: "Order placed successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => CartScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Payment method not supported yet.")),
        );
      }
    } catch (e) {
      print("❌ Error placing order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to place order: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: const [
            Icon(Icons.shopping_bag, color: Colors.white),
            SizedBox(width: 8),
            Text("Confirm Purchase"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "User Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(userDetails?['name'] ?? '', style: const TextStyle(fontSize: 16)),
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.phone, color: Colors.green),
                      title: Text(userDetails?['mobile'] ?? '', style: const TextStyle(fontSize: 16)),
                    ),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.email, color: Colors.orange),
                      title: Text(userDetails?['email'] ?? '', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  "Delivery Address",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.location_city, color: Colors.red),
                title: Text(
                  userDetails?['address'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.shopping_cart, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  "Your Cart",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...cartItems.map((item) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  title: Text(item['name']),
                  subtitle: Text(
                      "Qty: ${item['quantity'] ?? ''}  |  ₹${item['price'] ?? ''} (-${item['discount'] ?? ''}%)"
                  ),
                  trailing: Text(
                    "₹${(item['totalPrice'] as double).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              );
            }).toList(),
            const Divider(height: 30, thickness: 1),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Total Amount: ₹${totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Order Now"),
                onPressed: confirmOrder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
