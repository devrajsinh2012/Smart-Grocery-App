class Variant {
  final String quantity;
  final double price;
  final double discount;
  final List<String> images; // ✅ Use List<String> for multiple images

  Variant({
    required this.quantity,
    required this.price,
    required this.discount,
    required this.images, // ✅ Fix: initialize as List<String>
  });

  // ✅ Updated copyWith
  Variant copyWith({
    String? quantity,
    double? price,
    double? discount,
    List<String>? images,
  }) {
    return Variant(
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      images: images ?? this.images,
    );
  }

  // ✅ From Firestore
  factory Variant.fromFirestore(Map<String, dynamic> data) {
    return Variant(
      quantity: data['quantity'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      images: List<String>.from(data['images'] ?? []),
    );
  }

  // ✅ To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'images': images,
    };
  }

  // ✅ To Map (for SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'images': images,
    };
  }

  // ✅ From Map (for SharedPreferences)
  factory Variant.fromMap(Map<String, dynamic> map) {
    return Variant(
      quantity: map['quantity'],
      price: (map['price'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      images: List<String>.from(map['images'] ?? []),
    );
  }
}
