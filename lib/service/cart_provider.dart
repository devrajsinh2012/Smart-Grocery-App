import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'product_model.dart';
import 'Variant.dart';

// 🔹 Cart State
class CartState {
  final Map<String, CartItem> cartItems; // Using product ID as key
  final bool isLoading;

  CartState({required this.cartItems, required this.isLoading});

  CartState copyWith({Map<String, CartItem>? cartItems, bool? isLoading}) {
    return CartState(
      cartItems: cartItems ?? this.cartItems,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Get total item count (for Floating Cart)
  int get totalItemCount {
    return cartItems.length; // Counts unique product-variant pairs
  }
}

// 🔹 Cart Item Model
class CartItem {
  final Product product;
  final Variant variant;
  int quantity;

  CartItem({required this.product, required this.variant, required this.quantity});

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'variant': variant.toMap(),
      'quantity': quantity,
      'totalPrice': variant.price * quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromMap(map['product']),
      variant: Variant.fromMap(map['variant']),
      quantity: map['quantity'],
    );
  }
}

// 🔹 Cart Notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState(cartItems: {}, isLoading: true)) {
    loadCart();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Add Product Variant to Cart (Ensuring Unique Entry)
  void addToCart(Product product, Variant variant) {
    final cartKey = '${product.id}_${variant.quantity}';
    final updatedCart = Map<String, CartItem>.from(state.cartItems);

    updatedCart[cartKey] = CartItem(product: product, variant: variant, quantity: 1);

    state = state.copyWith(cartItems: updatedCart);
    saveCart();
    _saveToFirestore(product, variant, 1);
  }
  //increment function
  void incrementQuantity(Product product, Variant variant) {
    final cartKey = '${product.id}_${variant.quantity}';
    if (state.cartItems.containsKey(cartKey)) {
      state.cartItems[cartKey]!.quantity += 1;
      final quantity = state.cartItems[cartKey]!.quantity;
      state = state.copyWith(cartItems: Map.from(state.cartItems));
      saveCart();
      _saveToFirestore(product, variant, quantity);
    }
  }

  //decrement fuction
  void decrementQuantity(Product product, Variant variant) {
    final cartKey = '${product.id}_${variant.quantity}';
    if (state.cartItems.containsKey(cartKey)) {
      final quantity = state.cartItems[cartKey]!.quantity;

      if (quantity > 1) {
        state.cartItems[cartKey]!.quantity -= 1;
        final updatedQuantity = state.cartItems[cartKey]!.quantity;
        saveCart();
        _saveToFirestore(product, variant, updatedQuantity);
      } else {
        _removeFromFirestore(product, variant);
        state.cartItems.remove(cartKey);
      }

      state = state.copyWith(cartItems: Map.from(state.cartItems));
    }
  }

  // 🔹 Save Cart Data to SharedPreferences
  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> cartList =
    state.cartItems.values.map((cartItem) => cartItem.toMap()).toList();
    await prefs.setString('cart', jsonEncode(cartList));
  }

  // 🔹 Load Cart Data from SharedPreferences
  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart');

    if (cartJson != null && cartJson.isNotEmpty) {
      try {
        final List<dynamic> cartList = jsonDecode(cartJson);
        final updatedCart = <String, CartItem>{};

        for (var item in cartList) {
          final cartItem = CartItem.fromMap(item);
          final cartKey = '${cartItem.product.id}_${cartItem.variant.quantity}';
          updatedCart[cartKey] = cartItem;
        }

        state = state.copyWith(cartItems: updatedCart, isLoading: false);
      } catch (e) {
        print("Error loading cart: $e");
        state = state.copyWith(isLoading: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<DocumentReference<Map<String, dynamic>>?> _getSharedDocByUserUid(String uid) async {
    final snapshot = await _firestore
        .collection('SharedCode')
        .where('sender.uid', isEqualTo: uid)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.reference;
    }

    final receiverSnapshot = await _firestore
        .collection('SharedCode')
        .where('receiver.uid', isEqualTo: uid)
        .get();

    if (receiverSnapshot.docs.isNotEmpty) {
      return receiverSnapshot.docs.first.reference;
    }

    return null;
  }
  // 🔹 Save to Firestore
  Future<void> _saveToFirestore(Product product, Variant variant, int quantity) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final sharedDoc = await _getSharedDocByUserUid(user.uid);

      // Prepare cart item
      final String uniqueItemId = '${product.id}_${variant.quantity}';
      double discountedPrice = variant.price * (1 - (variant.discount / 100));
      double totalPrice = double.parse((discountedPrice * quantity).toStringAsFixed(2));

      final newItem = {
        'uniqueItemId': uniqueItemId,
        'name': product.name,
        'price': variant.price,
        'image': product.image,
        'quantity': quantity,
        'discount': variant.discount,
        'totalPrice': totalPrice,
      };

      if (sharedDoc != null) {
        // 🔹 If user is in a shared cart
        final cartItemsRef = sharedDoc.collection('cartItems');
        final itemDoc = cartItemsRef.doc(uniqueItemId);

        if (quantity <= 0) {
          await itemDoc.delete();
        } else {
          await itemDoc.set(newItem);
        }

        // Fetch updated shared cart
        final snapshot = await cartItemsRef.get();
        final updatedSharedCart = snapshot.docs.map((doc) => doc.data()).toList();

        // Compute total
        final sharedTotal = updatedSharedCart.fold<double>(0.0, (sum, item) => sum + (item['totalPrice'] as num).toDouble());
        final totalCartPrice = double.parse(sharedTotal.toStringAsFixed(2));

        // 🔁 Update both users' UserDetail
        final sharedData = await sharedDoc.get();
        final senderUid = sharedData['sender']['uid'];
        final receiverUid = sharedData['receiver']['uid'];

        final batch = _firestore.batch();
        final senderRef = _firestore.collection('UserDetail').doc(senderUid);
        final receiverRef = _firestore.collection('UserDetail').doc(receiverUid);

        batch.set(senderRef, {
          'cartItems': updatedSharedCart,
          'totalCartPrice': totalCartPrice,
        }, SetOptions(merge: true));

        batch.set(receiverRef, {
          'cartItems': updatedSharedCart,
          'totalCartPrice': totalCartPrice,
        }, SetOptions(merge: true));

        await batch.commit();
      } else {
        // 🔸 If no shared cart, update personal cart
        final docRef = _firestore.collection('UserDetail').doc(user.uid);
        final docSnapshot = await docRef.get();

        List<dynamic> existingCartItems = [];
        double totalCartPrice = 0.0;

        if (docSnapshot.exists && docSnapshot.data()!.containsKey('cartItems')) {
          existingCartItems = List.from(docSnapshot.data()!['cartItems']);
        }

        int index = existingCartItems.indexWhere((item) => item['uniqueItemId'] == uniqueItemId);

        if (quantity <= 0) {
          if (index >= 0) existingCartItems.removeAt(index);
        } else {
          if (index >= 0) {
            existingCartItems[index] = newItem;
          } else {
            existingCartItems.add(newItem);
          }
        }

        totalCartPrice = existingCartItems.fold(
          0.0,
              (sum, item) => sum + (item['totalPrice'] as num).toDouble(),
        );
        totalCartPrice = double.parse(totalCartPrice.toStringAsFixed(2));

        await docRef.set({
          'cartItems': existingCartItems,
          'totalCartPrice': totalCartPrice,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("❌ Firestore update error: $e");
    }
  }


  Future<void> _removeFromFirestore(Product product, Variant variant) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uniqueItemId = '${product.id}_${variant.quantity}';
    final sharedDoc = await _getSharedDocByUserUid(user.uid);

    try {
      if (sharedDoc != null) {
        // 🔁 Remove from shared cart
        final cartItemsRef = sharedDoc.collection('cartItems');
        await cartItemsRef.doc(uniqueItemId).delete();

        // Fetch updated shared cart
        final snapshot = await cartItemsRef.get();
        final updatedSharedCart = snapshot.docs.map((doc) => doc.data()).toList();

        final sharedTotal = updatedSharedCart.fold<double>(
          0.0,
              (sum, item) => sum + (item['totalPrice'] as num).toDouble(),
        );
        final totalCartPrice = double.parse(sharedTotal.toStringAsFixed(2));

        final sharedData = await sharedDoc.get();
        final senderUid = sharedData['sender']['uid'];
        final receiverUid = sharedData['receiver']['uid'];

        final batch = _firestore.batch();
        final senderRef = _firestore.collection('UserDetail').doc(senderUid);
        final receiverRef = _firestore.collection('UserDetail').doc(receiverUid);

        batch.set(senderRef, {
          'cartItems': updatedSharedCart,
          'totalCartPrice': totalCartPrice,
        }, SetOptions(merge: true));

        batch.set(receiverRef, {
          'cartItems': updatedSharedCart,
          'totalCartPrice': totalCartPrice,
        }, SetOptions(merge: true));

        await batch.commit();
      } else {
        // 🔸 Remove from personal cart
        final docRef = _firestore.collection('UserDetail').doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) return;

        List<dynamic> existingCartItems = [];
        double totalCartPrice = 0.0;

        if (docSnapshot.data()!.containsKey('cartItems')) {
          existingCartItems = List.from(docSnapshot.data()!['cartItems']);
        }

        // Remove the item
        existingCartItems.removeWhere((item) => item['uniqueItemId'] == uniqueItemId);

        // Recalculate total
        totalCartPrice = existingCartItems.fold(
          0.0,
              (sum, item) => sum + (item['totalPrice'] as num).toDouble(),
        );
        totalCartPrice = double.parse(totalCartPrice.toStringAsFixed(2));

        // Update Firestore
        await docRef.set({
          'cartItems': existingCartItems,
          'totalCartPrice': totalCartPrice,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("❌ Error removing item from Firestore: $e");
    }
  }



  // 🔹 Clear cart after order is placed
  Future<void> clearCartAfterOrder() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('UserDetail').doc(user.uid).set({
        'cartItems': [],
        'totalCartPrice': 0.0,
      }, SetOptions(merge: true));

      state = state.copyWith(cartItems: {});
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cart');

      print("✅ Cart cleared after order confirmation.");
    } catch (e) {
      print("❌ Error clearing cart after order: $e");
    }
  }

  //To fully clean the cart on logout or when manually clearing it
  void clearCart() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('UserDetail').doc(user.uid).set({
        'cartItems': [],
        'totalCartPrice': 0.0,
      }, SetOptions(merge: true));
    }

    state = state.copyWith(cartItems: {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
  }


  // 🔹 Get Total Unique Items Count for Floating Cart
  int getTotalItemCount() {
    return state.cartItems.length; // Unique product-variant count
  }
}

// 🔹 Riverpod Provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});