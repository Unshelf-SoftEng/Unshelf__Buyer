import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class BundleView extends StatefulWidget {
  final String bundleId;

  BundleView({required this.bundleId});

  @override
  _BundleViewState createState() => _BundleViewState();
}

class _BundleViewState extends State<BundleView> {
  Map<String, dynamic>? sellerData;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
  }

  Future<void> _fetchSellerData() async {
    var bundleSnapshot = await FirebaseFirestore.instance.collection('bundles').doc(widget.bundleId).get();
    var bundleData = bundleSnapshot.data() as Map<String, dynamic>;

    var sellerSnapshot = await FirebaseFirestore.instance.collection('stores').doc(bundleData['sellerId']).get();
    setState(() {
      sellerData = sellerSnapshot.data() as Map<String, dynamic>?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('bundles').doc(widget.bundleId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var bundleData = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              Stack(
                children: [
                  // Bundle image
                  CachedNetworkImage(
                    imageUrl: bundleData['mainImageUrl'],
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.cover,
                  ),

                  // Floating buttons
                  Positioned(
                    top: 40.0,
                    left: 16.0,
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      backgroundColor: const Color(0xFF6E9E57),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                      mini: true,
                      shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2.0)),
                    ),
                  ),
                  Positioned(
                    top: 40.0,
                    right: 16.0,
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => BasketView()),
                        );
                      },
                      backgroundColor: const Color(0xFF6E9E57),
                      child: const Icon(Icons.shopping_cart, color: Colors.white),
                      mini: true,
                      shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2.0)),
                    ),
                  ),
                ],
              ),

              // Bundle Details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bundleData['name'],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'P ${bundleData['price']}',
                            style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Distance: 6 km', // Modify or calculate dynamically if needed
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      GestureDetector(
                        onTap: () {
                          if (sellerData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreView(storeId: bundleData['sellerId']),
                              ),
                            );
                          }
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  sellerData != null ? CachedNetworkImageProvider(sellerData!['store_image_url']) : null,
                              radius: 20,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              sellerData != null ? sellerData!['store_name'] : 'Loading...',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'Stock: ${bundleData['stock']}',
                        style: const TextStyle(fontSize: 16, color: Colors.green),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'This is a bundle of products that offers great value. Enjoy a variety of items at a discounted price.',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16.0),

                      // Products in Bundle (Carousel)
                      const Text(
                        'Products in this bundle',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('products')
                            .where(FieldPath.documentId, whereIn: bundleData['productIds'])
                            .get(),
                        builder: (context, productSnapshot) {
                          if (!productSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          var products = productSnapshot.data!.docs;
                          return SizedBox(
                            height: 200.0,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                var product = products[index].data() as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: product['mainImageUrl'],
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        product['name'],
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        'P ${product['price']}',
                                        style: const TextStyle(fontSize: 14, color: Colors.green),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        '${product['discount']}% off',
                                        style: const TextStyle(fontSize: 12, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () => _addToFavorites(context, widget.bundleId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text("FAVORITE", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            ElevatedButton(
              onPressed: () => {_addToCart(context, widget.bundleId, 1)}, // Default quantity to 1 for bundles
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[500],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text("ADD TO CART", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToFavorites(BuildContext context, String bundleId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(bundleId)
            .set({'added_at': FieldValue.serverTimestamp(), 'is_bundle': true});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bundle added to favorites!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to favorites.')),
      );
    }
  }

  Future<void> _addToCart(BuildContext context, String bundleId, int quantity) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentReference userBasketRef = FirebaseFirestore.instance.collection('baskets').doc(user.uid);
        DocumentReference cartItemRef = userBasketRef.collection('cart_items').doc(bundleId);

        DocumentSnapshot cartItemSnapshot = await cartItemRef.get();

        if (cartItemSnapshot.exists) {
          // Update quantity if the item is already in the cart
          await cartItemRef.update({'quantity': FieldValue.increment(quantity)});
        } else {
          // Add new item to the cart
          await cartItemRef.set({'quantity': quantity});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bundle added to cart!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add to cart.')),
      );
    }
  }
}
