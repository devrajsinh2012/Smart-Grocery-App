import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:project5/service/product_model.dart';
import 'package:project5/service/cart_provider.dart';
import 'package:project5/service/Variant.dart';
import 'CartScreen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Product selectedProduct;
  late Variant selectedVariant;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    selectedProduct = widget.product;
    selectedVariant = selectedProduct.variants.first;
  }


  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final totalItems = ref.watch(cartProvider).totalItemCount;

    double discountedPrice = selectedVariant.price;
    if (selectedVariant.discount > 0) {
      discountedPrice = selectedVariant.price - (selectedVariant.price * (selectedVariant.discount / 100));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedProduct.name),
        backgroundColor: Colors.green,
      ),
      backgroundColor: Colors.green.shade100,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Image Slider with Dot Indicators
                      Container(
                        height: 372,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              spreadRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 330,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: selectedVariant.images.length,
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      selectedVariant.images[index],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            SmoothPageIndicator(
                              controller: _pageController,
                              count: selectedVariant.images.length,
                              effect: WormEffect(
                                activeDotColor: Colors.green,
                                dotHeight: 10,
                                dotWidth: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          selectedProduct.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Pack sizes: ${selectedVariant.quantity}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Wrap(
                          spacing: 10,
                          children: selectedProduct.variants.map((variant) {
                            bool isSelected = variant == selectedVariant;
                            double discountedPrice = variant.price - (variant.price * (variant.discount / 100));

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedVariant = variant;
                                  _pageController.jumpToPage(0);
                                });
                              },
                              child: Container(
                                height: 120,
                                width: 95,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? Colors.green : Colors.grey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isSelected ? Colors.green.shade50 : Colors.white,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      variant.quantity,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.green.shade900 : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    // Original price with strikethrough (only if discount exists)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (variant.discount == 0) ...[
                                          // 👉 No discount — show only original price
                                          Text(
                                            "₹${variant.price.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ] else ...[
                                          // 👉 Discount available — show discounted price, original price, and discount badge
                                          Text(
                                            "₹${discountedPrice.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "₹${variant.price.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              decoration: TextDecoration.lineThrough,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              "${variant.discount}% OFF",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ]
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "About the Product",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          selectedProduct.about,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Add to Cart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "₹${(selectedVariant.price - (selectedVariant.price * (selectedVariant.discount / 100))).toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "Inclusive of all taxes",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          final cartKey = '${widget.product.id}_${selectedVariant.quantity}';
                          if (cartNotifier.state.cartItems.containsKey(cartKey)) {
                            Fluttertoast.showToast(
                              msg: "${widget.product.name} is already in the cart",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.TOP,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 14.0,
                            );
                          } else {
                            cartNotifier.addToCart(widget.product, selectedVariant);
                            Fluttertoast.showToast(
                              msg: "${widget.product.name} (${selectedVariant.quantity}) added to cart",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.TOP,
                              backgroundColor: Colors.green,
                              textColor: Colors.white,
                              fontSize: 14.0,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade400,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Add to Cart", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating Cart Container (only if cart is not empty)
          if (totalItems > 0)
            Positioned(
              bottom: 90,
              right: 10,
              child: _buildFloatingCart(context, totalItems),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingCart(BuildContext context, int totalItems) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CartScreen()),
        );
      },
      child: Container(
        width: 150,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.redAccent, Colors.red],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text(
              "$totalItems Products",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
