import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project5/uiscrren/BuyScreen.dart';

class PaymentMethodScreen extends StatefulWidget {
  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String userAddress = 'Fetching address...';
  String userId = '';
  String selectedMethod = 'Cash On Delivery';

  @override
  void initState() {
    super.initState();
    fetchUserAddress();
  }

  Future<void> fetchUserAddress() async {
    try {
      userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isNotEmpty) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('UserDetail')
            .doc(userId)
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            final address = data['address'] ?? '';
            final apartment = data['apartment'] ?? '';
            final landmark = data['landmark'] ?? '';
            final city = data['city'] ?? '';
            final pincode = data['pincode'] ?? '';
            final paymentMethod = data['paymentMethod'] ?? 'Cash On Delivery';

            final fullAddress = [
              address,
              apartment,
              landmark,
              city,
              pincode
            ].where((part) => part.isNotEmpty).join(', ');

            setState(() {
              userAddress = fullAddress.isEmpty ? 'No address found' : fullAddress;
              selectedMethod = paymentMethod;
            });
          }
        } else {
          setState(() {
            userAddress = 'No address found in Firestore.';
          });
        }
      }
    } catch (e) {
      setState(() {
        userAddress = 'Error fetching address: $e';
      });
    }
  }

  Future<void> updatePaymentMethod(String paymentMethod) async {
    try {
      if (userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('UserDetail')
            .doc(userId)
            .update({'paymentMethod': paymentMethod});

        setState(() {
          selectedMethod = paymentMethod;
        });
      }
    } catch (e) {
      print('Error updating payment method: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Select Payment Method', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(userAddress, style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 25),
            Text('Payment Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            buildPaymentTile(
              icon: Icons.money,
              label: 'Cash On Delivery',
              method: 'Cash On Delivery',
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
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
                      child: Buyscreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.black, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text("Proceed", style: TextStyle(color: Colors.black)),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildPaymentTile({
    required IconData icon,
    required String label,
    required String method,
  }) {
    bool isSelected = selectedMethod == method;

    return GestureDetector(
      onTap: () => updatePaymentMethod(method),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green),
            SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 16))),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
