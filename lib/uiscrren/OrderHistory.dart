import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Orderhistory extends StatefulWidget {
  const Orderhistory({super.key});

  @override
  State<Orderhistory> createState() => _OrderhistoryState();
}

class _OrderhistoryState extends State<Orderhistory> {
  String formatDate(Timestamp timestamp) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  Future<String?> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint("❌ No user logged in");
      return null;
    }
    debugPrint("✅ Logged in userId: ${user.uid}");
    return user.uid;
  }

  /// Updates status to 'Delivered' if 2 hours have passed and deletes orders older than 1 month
  void _handleStatusAndCleanup(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    if (!data.containsKey('timestamp')) return;
    final timestamp = data['timestamp'] as Timestamp;
    final status = data['status'] ?? 'Pending';
    final now = DateTime.now();
    final orderTime = timestamp.toDate();

    // 1. Update to Delivered if 2 hours passed
    if (status != 'Delivered' && now.difference(orderTime).inHours >= 2) {
      await doc.reference.update({'status': 'Delivered'});
      debugPrint("✅ Order ${doc.id} marked as Delivered");
    }

    // 2. Delete if more than 30 days after delivery
    if (status == 'Delivered' && now.difference(orderTime).inDays >= 30) {
      await doc.reference.delete();
      debugPrint("🗑 Order ${doc.id} deleted after 1 month");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<String?>(
        future: _getUserId(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text("User not logged in."));
          }

          final String userId = userSnapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ItemBuy')
                .where('userId', isEqualTo: userId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No orders found."));
              }

              final orders = snapshot.data!.docs;

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final doc = orders[index];
                  final data = doc.data() as Map<String, dynamic>;

                  // Perform status update and auto-deletion
                  _handleStatusAndCleanup(doc);

                  final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                  final total = (data['totalPrice'] ?? 0).toDouble();
                  final payment = data['paymentMethod'] ?? 'Unknown';
                  final status = data['status'] ?? 'Pending';
                  final timestamp = data['timestamp'] as Timestamp;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🛒 Order placed on: ${formatDate(timestamp)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("💰 Total Price: ₹${total.toStringAsFixed(2)}"),
                          Text("💳 Payment: $payment"),
                          Text("📦 Status: $status"),
                          const Divider(height: 20),
                          const Text(
                            "Items Ordered:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['image'] ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                                ),
                              ),
                              title: Text(item['name'] ?? 'No name'),
                              subtitle: Text(
                                "Qty: ${item['quantity']} | ₹${item['price']} (-${item['discount']}%)",
                              ),
                              trailing: Text(
                                "₹${(item['totalPrice'] ?? 0).toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
