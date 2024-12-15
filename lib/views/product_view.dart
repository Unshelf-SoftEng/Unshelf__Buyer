import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class ProductPage extends StatefulWidget {
  final String productId;

  ProductPage({required this.productId});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int _quantity = 1;
  Map<String, dynamic>? sellerData;
  bool isFavorite = false;

  List<DocumentSnapshot>? _batches;
  DocumentSnapshot? _selectedBatch;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
    _checkIfFavorite();
    _fetchBatches();
  }

  Future<void> _fetchSellerData() async {
    var productSnapshot = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
    var productData = productSnapshot.data() as Map<String, dynamic>;

    var sellerSnapshot = await FirebaseFirestore.instance.collection('stores').doc(productData['sellerId']).get();
    setState(() {
      sellerData = sellerSnapshot.data();
    });
  }

  Future<void> _checkIfFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var favoriteDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(widget.productId).get();

      setState(() {
        isFavorite = favoriteDoc.exists;
      });
    }
  }

  Future<void> _fetchBatches() async {
    var batchDocs = await FirebaseFirestore.instance
        .collection('batches')
        .where('productId', isEqualTo: widget.productId)
        .where('isListed', isEqualTo: true)
        .get();

    setState(() {
      _batches = batchDocs.docs;
      if (_batches!.isNotEmpty) {
        _selectedBatch = _batches!.first; // Default batch
      }
    });
  }

  void _onBatchSelected(DocumentSnapshot? batch) {
    setState(() {
      _selectedBatch = batch;
    });
  }

  Future<void> _toggleFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var favoriteRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(widget.productId);

      if (isFavorite) {
        await favoriteRef.delete();
      } else {
        await favoriteRef.set({'added_at': FieldValue.serverTimestamp(), 'is_bundle': false});
      }

      setState(() {
        isFavorite = !isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFavorite ? 'Added to Favorites' : 'Removed from Favorites')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('products').doc(widget.productId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var productData = snapshot.data!.data() as Map<String, dynamic>;
          final batchData = _selectedBatch?.data() as Map<String, dynamic>?;

          return Column(
            children: [
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: productData['mainImageUrl'],
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.cover,
                  ),
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
                          MaterialPageRoute(
                            builder: (context) => BasketView(),
                            fullscreenDialog: true,
                          ),
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            productData['name'],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: Colors.green,
                            ),
                            onPressed: _toggleFavorite,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      if (_batches != null && _batches!.isNotEmpty)
                        DropdownButton<DocumentSnapshot>(
                          value: _selectedBatch,
                          isExpanded: true,
                          onChanged: _onBatchSelected,
                          items: _batches!.map((batch) {
                            final batchInfo = batch.data() as Map<String, dynamic>;
                            return DropdownMenuItem<DocumentSnapshot>(
                              value: batch,
                              child: Text(
                                'Batch: ${batchInfo['batchNumber']} (${batchInfo['stock']})',
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₱${batchData?['price']?.toStringAsFixed(2) ?? productData['price']} / ${productData['quantifier']}',
                            style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Distance: 6 km',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      GestureDetector(
                        onTap: () {
                          if (sellerData != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreView(storeId: productData['sellerId']),
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
                        'Expiration: ${DateFormat('MMMM d, yyyy').format((batchData!['expiryDate']).toDate())}',
                        style: const TextStyle(fontSize: 16, color: Colors.green),
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        productData['description'],
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8.0),
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
            onPressed: () => _addToCart(context, _selectedBatch!.id, _quantity),
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
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, String batchId, int quantity) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('baskets')
            .doc(user.uid)
            .collection('cart_items')
            .doc(batchId)
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
}
