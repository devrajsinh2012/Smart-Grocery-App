import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';
import 'Variant.dart';
import '../service/cart_provider.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch products by category
  Future<List<Product>> fetchProductsByCategory(String category) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return Product.fromFirestore(data);
        } else {
          throw Exception("Null data in Firestore document");
        }
      }).toList();
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  /// Fetch all products from Firestore
  Future<List<Product>> fetchAllProducts() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('products').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          return Product.fromFirestore(data);
        } else {
          throw Exception("Null data in Firestore document");
        }
      }).toList();
    } catch (e) {
      print("Error fetching all products: $e");
      return [];
    }
  }
}
