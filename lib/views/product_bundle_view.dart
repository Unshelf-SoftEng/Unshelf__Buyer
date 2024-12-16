import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class BundleView extends StatefulWidget {
  final String bundleId;

  BundleView({required this.bundleId});

  @override
  _BundleViewState createState() => _BundleViewState();
}

class _BundleViewState extends State<BundleView> {
  int _quantity = 1;
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
                      backgroundColor: Colors.white.withOpacity(0.6),
                      mini: true,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
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
                      backgroundColor: Colors.white.withOpacity(0.6),
                      mini: true,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.shopping_basket, color: Colors.black),
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
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'P ${bundleData['price']}',
                            style: const TextStyle(fontSize: 20, color: const Color(0xFF0AB68B), fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Distance: 6 km', // TODO : Calculate Dynamically + Ask for location access on splash
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),

                      Text(
                        'Stock: ${bundleData['stock']}',
                        style: const TextStyle(fontSize: 16, color: const Color(0xFF0AB68B)),
                      ),
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
                      // Divider
                      Divider(color: Colors.grey[200]),
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        bundleData['description'],
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
                      // Divider
                      Divider(color: Colors.grey[200]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quantity:', style: TextStyle(fontSize: 18)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              ),
                              Text(
                                _quantity.toString(),
                                style: const TextStyle(fontSize: 18),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Divider
                      Divider(color: Colors.grey[200]),
                      // Products in Bundle (Carousel)
                      const Text(
                        'Products in this bundle',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('batches')
                            .where(FieldPath.documentId, whereIn: bundleData['items'].map((item) => item['batchId']).toList())
                            .get(),
                        builder: (context, batchSnapshot) {
                          if (!batchSnapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          var batches = batchSnapshot.data!.docs;

                          if (batches.isEmpty) {
                            return const Text('No products found in this bundle.');
                          }

                          return SizedBox(
                            height: 200.0,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: batches.length,
                              itemBuilder: (context, index) {
                                var batch = batches[index].data() as Map<String, dynamic>;

                                // Fetch product details using the productId from the batch
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('products').doc(batch['productId']).get(),
                                  builder: (context, productSnapshot) {
                                    if (!productSnapshot.hasData) {
                                      return const CircularProgressIndicator();
                                    }

                                    var product = productSnapshot.data!.data() as Map<String, dynamic>;

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProductPage(productId: batch['productId']),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        margin: const EdgeInsets.only(right: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CachedNetworkImage(
                                              imageUrl: product['mainImageUrl'] ?? '',
                                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                                              width: 120.0,
                                              height: 120.0,
                                              fit: BoxFit.cover,
                                            ),
                                            const SizedBox(height: 8.0),
                                            Padding(
                                              padding: const EdgeInsets.all(3.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product['name'] ?? 'No Name',
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    'P ${batch['price'] ?? 0}',
                                                    style: const TextStyle(fontSize: 14, color: const Color(0xFF0AB68B)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
        child: Center(
          child: ElevatedButton(
            onPressed: () => _addToCart(context, widget.bundleId, _quantity),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0AB68B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text("ADD TO CART", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _addToCart(BuildContext context, String bundleId, int quantity) async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('baskets')
          .doc(user.uid)
          .collection('cart_items')
          .doc(bundleId)
          .set({'quantity': quantity});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Cart')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to add items to cart')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add to cart: $e')),
    );
  }
}
