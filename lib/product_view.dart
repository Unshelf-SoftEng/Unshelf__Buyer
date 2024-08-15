import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/basket_view.dart';
import 'package:unshelf_buyer/store_view.dart';

class ProductPage extends StatefulWidget {
  final String productId;

  ProductPage({required this.productId});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int _quantity = 1;
  Map<String, dynamic>? sellerData;

  @override
  void initState() {
    super.initState();
    _fetchSellerData();
  }

  Future<void> _fetchSellerData() async {
    var productSnapshot = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
    var productData = productSnapshot.data() as Map<String, dynamic>;

    var sellerSnapshot = await FirebaseFirestore.instance.collection('stores').doc(productData['sellerId']).get();
    setState(() {
      sellerData = sellerSnapshot.data() as Map<String, dynamic>?;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('products').doc(widget.productId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var productData = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              Stack(
                children: [
                  // Product image
                  CachedNetworkImage(
                    imageUrl: productData['mainImageUrl'],
                    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Center(child: Icon(Icons.error)),
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
                      backgroundColor: Color(0xFF6E9E57),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                      mini: true,
                      shape: CircleBorder(side: BorderSide(color: Colors.white, width: 2.0)),
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
                      backgroundColor: Color(0xFF6E9E57),
                      child: Icon(Icons.shopping_cart, color: Colors.white),
                      mini: true,
                      shape: CircleBorder(side: BorderSide(color: Colors.white, width: 2.0)),
                    ),
                  ),
                ],
              ),

              // Product Details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productData['name'],
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'P ${productData['price']}',
                            style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Distance: 6 km', // Modify or calculate dynamically if needed
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.0),
                      GestureDetector(
                        onTap: () {
                          if (sellerData != null) {
                            Navigator.push(
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
                            SizedBox(width: 8.0),
                            Text(
                              sellerData != null ? sellerData!['store_name'] : 'Loading...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'Expiration: ${DateFormat('MMMM d, yyyy').format((productData['expiryDate'] as Timestamp).toDate())}',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Description',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        productData['description'],
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        'Note: Store in room temperature',
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Quantity:', style: TextStyle(fontSize: 18)),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              ),
                              Text(
                                _quantity.toString(),
                                style: TextStyle(fontSize: 18),
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () => _addToFavorites(context, widget.productId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text("FAVORITE", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            ElevatedButton(
              onPressed: () => {_addToCart(context, widget.productId, _quantity)},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[500],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text("ADD TO CART", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToFavorites(BuildContext context, String productId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .doc(productId)
            .set({'added_at': FieldValue.serverTimestamp()});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to Favorites')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You need to be logged in to add favorites')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to favorites: $e')),
      );
    }
  }

  Future<void> _addToCart(BuildContext context, String productId, int quantity) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('baskets')
            .doc(user.uid)
            .collection('cart_items')
            .doc(productId)
            .set({'quantity': quantity});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to Cart')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You need to be logged in to add items to cart')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart: $e')),
      );
    }
  }
}
