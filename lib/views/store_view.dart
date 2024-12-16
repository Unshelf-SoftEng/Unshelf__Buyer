import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/viewmodels/store_viewmodel.dart';
import 'package:unshelf_buyer/views/chat_view.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/views/store_address_view.dart';

class StoreView extends StatefulWidget {
  final String storeId;

  StoreView({required this.storeId});

  @override
  _StoreViewState createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  late TextEditingController _searchController;
  String searchQuery = "";
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });

    _checkIfFollow();
    // Fetch store details
    Provider.of<StoreViewModel>(context, listen: false).fetchStoreDetails(widget.storeId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkIfFollow() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var followDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following').doc(widget.storeId).get();

      setState(() {
        isFollowing = followDoc.exists;
      });
    }
  }

  Future<void> _toggleFollow() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var followRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('following').doc(widget.storeId);
      var storeDoc = await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).get();
      var storeRef = FirebaseFirestore.instance.collection('stores').doc(widget.storeId);

      if (isFollowing) {
        await followRef.delete();
        await storeRef.update({'follower_count': storeDoc.data()!['follower_count'] - 1});
      } else {
        await followRef.set({'added_at': FieldValue.serverTimestamp()});
        await storeRef.update({'follower_count': storeDoc.data()!['follower_count'] + 1});
      }

      setState(() {
        isFollowing = !isFollowing;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFollowing ? 'You are now following the store!' : 'You have stopped following the store.')),
      );
    }
  }

  Widget _buildProductCard(Map<String, dynamic> productData, String productId, bool isBundle, BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('batches')
          .where('productId', isEqualTo: productId)
          .where('isListed', isEqualTo: true)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        var batch = snapshot.data!.docs.first; // Use the first batch as default.
        var batchData = batch.data() as Map<String, dynamic>;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductPage(productId: productId),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
              side: const BorderSide(color: Color(0xA7C957), width: 10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: productData['mainImageUrl'],
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    if (productData['discount'] != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                          child: Text(
                            '${productData['discount']}% off',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    productData['name'],
                    style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '  PHP${batchData['price'].toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0AB68B)),
                ),
                // Text(
                //   '  ${batchData['quantity']} in stock',
                //   style: const TextStyle(fontSize: 12, color: Colors.grey),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<StoreViewModel>(
        builder: (context, storeViewModel, child) {
          if (storeViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (storeViewModel.errorMessage != null) {
            return Center(
              child: Text(storeViewModel.errorMessage!),
            );
          }

          if (storeViewModel.storeDetails == null) {
            return const Center(child: Text('No store data available'));
          }

          var storeDetails = storeViewModel.storeDetails!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Header
                Container(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 30.0, bottom: 10.0),
                  color: const Color(0xFF0AB68B),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: CachedNetworkImageProvider(storeDetails.storeImageUrl ?? ''),
                      ),
                      const SizedBox(width: 16.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeDetails.storeName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Text(
                            'Cebu City, Cebu',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          // Row(
                          //   children: [
                          //     const Icon(Icons.star, color: Colors.amber, size: 16),
                          //     Text(
                          //       '${storeDetails.storeRating?.toStringAsFixed(1)} Rating',
                          //       style: const TextStyle(fontSize: 12, color: Colors.white),
                          //     ),
                          //     const SizedBox(width: 10),
                          //     Text(
                          //       '${storeDetails.storeFollowers ?? 0} Followers',
                          //       style: const TextStyle(fontSize: 12, color: Colors.white),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: _toggleFollow,
                            style: isFollowing
                                ? ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 105, 120, 106),
                                    side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 1.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  )
                                : ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF66BB6A),
                                    side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 1.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                  ),
                            child: isFollowing
                                ? const Text('Unfollow', style: TextStyle(color: Colors.white))
                                : const Text('Follow', style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatView(
                                    receiverName: storeDetails.storeName,
                                    receiverUserID: widget.storeId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD54F),
                              side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                            child: const Text('Chat', style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // View in Maps
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (storeDetails.storeLatitude != null && storeDetails.storeLongitude != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreAddressView(
                              latitude: storeDetails.storeLatitude!,
                              longitude: storeDetails.storeLongitude!,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location data is not available')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66BB6A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: Colors.white),
                        SizedBox(width: 8),
                        Text('View in Maps', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),

                // Category Listings: Offers, Grocery, Fruits, Veggies, Baked
                for (var category in ['Offers', 'Grocery', 'Fruits', 'Vegetables', 'Baked Goods'])
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('sellerId', isEqualTo: widget.storeId)
                        .where('category', isEqualTo: category)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox.shrink(); // Skip if no products
                      }

                      var productDocs = snapshot.data!.docs;

                      return Container(
                        height: 220,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0AB68B),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: productDocs.length,
                                itemBuilder: (context, index) {
                                  var productData = productDocs[index].data() as Map<String, dynamic>;
                                  var productId = productDocs[index].id;
                                  var isBundle = productData['isBundle'] ?? false;

                                  return Container(
                                    width: 160,
                                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: _buildProductCard(productData, productId, isBundle, context),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
