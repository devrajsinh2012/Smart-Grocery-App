import 'Variant.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final String about;
  final List<Variant> variants;
  Variant? selectedVariant;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.about,
    required this.variants,
    this.selectedVariant,
  });

  // ✅ Get first image from selectedVariant (if available)
  String get image => (selectedVariant?.images.isNotEmpty ?? false)
      ? selectedVariant!.images.first
      : '';

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? about,
    List<Variant>? variants,
    Variant? selectedVariant,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      about: about ?? this.about,
      variants: variants ?? this.variants,
      selectedVariant: selectedVariant ?? this.selectedVariant,
    );
  }

  factory Product.fromFirestore(Map<String, dynamic> data) {
    var variantList = (data['variants'] as List<dynamic>?)
        ?.map((variant) => Variant.fromFirestore(variant))
        .toList() ??
        [];

    return Product(
      id: data['id'] ?? '',
      name: data['name'] ?? 'No Name',
      category: data['category'] ?? 'Uncategorized',
      about: data['about'] ?? 'No description available',
      variants: variantList,
      selectedVariant: variantList.isNotEmpty ? variantList.first : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'about': about,
      'variants': variants.map((variant) => variant.toFirestore()).toList(),
      'selectedVariant': selectedVariant?.toFirestore(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'about': about,
      'variants': variants.map((variant) => variant.toMap()).toList(),
      'selectedVariant': selectedVariant?.toMap(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    var variantList = (map['variants'] as List<dynamic>?)
        ?.map((variant) => Variant.fromMap(variant))
        .toList() ??
        [];

    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'] ?? 'Uncategorized',
      about: map['about'] ?? 'No description available',
      variants: variantList,
      selectedVariant: map['selectedVariant'] != null
          ? Variant.fromMap(map['selectedVariant'])
          : (variantList.isNotEmpty ? variantList.first : null),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
