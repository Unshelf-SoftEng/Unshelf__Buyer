import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/views/basket_view.dart';
import 'package:unshelf_buyer/views/bundle_view.dart';
import 'package:unshelf_buyer/views/category_row_widget.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/near_me_view.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/views/profile_view.dart';

class HomeView extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E9E57),
        elevation: 0,
        toolbarHeight: 60,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.search,
                  color: Color(0xFFA3C38C),
                ),
              ),
              Text(
                "Search",
                style: TextStyle(
                  color: Color(0xFFA3C38C),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.shopping_basket,
                color: Color(0xFF6E9E57),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BasketView(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.message,
                color: Color(0xFF6E9E57),
              ),
            ),
            onPressed: () {
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => ChatView()),
              // );
            },
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: const Color.fromARGB(255, 200, 221, 150),
              height: 4.0,
            )),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCarouselBanner(),
            CategoryIconsRow(),
            _buildSellingOutSection(),
            _buildBundleDealsSection(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Near Me',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeView()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MapView()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileView()),
        );
        break;
    }
  }

  Widget _buildCarouselBanner() {
    return FutureBuilder<List<String>>(
      future: _getBannerImageUrls(), // Fetch URLs from Firebase Storage
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No banners available.'));
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: CarouselSlider(
            options: CarouselOptions(height: 150.0, autoPlay: true),
            items: snapshot.data!.map((url) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<List<String>> _getBannerImageUrls() async {
    try {
      final ListResult result = await _storage.ref('banner_images').listAll();
      final List<String> imageUrls = await Future.wait(
        result.items.map((Reference ref) => ref.getDownloadURL()).toList(),
      );
      return imageUrls;
    } catch (e) {
      print('Error fetching banner images: $e');
      return [];
    }
  }

  Widget _buildCategories() {
    final categories = ['Offers', 'Grocery', 'Fruits', 'Vegetables', 'Baked Goods', 'Meals'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 80.0,
          viewportFraction: 0.3,
        ),
        items: categories.map((category) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.category, size: 40),
              Text(category, style: const TextStyle(fontSize: 12)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSellingOutSection() {
    return _buildProductCarousel('Selling Out', 'sellingOut');
  }

  Widget _buildBundleDealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Bundle Deals",
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('bundles').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final bundles = snapshot.data!.docs;

            return CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                viewportFraction: 0.5,
              ),
              items: bundles.map((bundle) {
                final data = bundle.data() as Map<String, dynamic>;
                final bundleId = bundle.id;
                return _buildProductCard(data, bundleId, true, context);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCarousel(String title, String collection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final products = snapshot.data!.docs;

            return CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                viewportFraction: 0.5,
              ),
              items: products.map((product) {
                final data = product.data() as Map<String, dynamic>;
                final productId = product.id;
                return _buildProductCard(data, productId, false, context);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String productId, bool isBundle, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isBundle ? BundleView(bundleId: productId) : ProductPage(productId: productId),
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
                  imageUrl: data['mainImageUrl'],
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (data['discount'] != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                      child: Text(
                        '${data['discount']}% off',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                data['name'],
                style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '  PHP${data['price'].toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            //   const SizedBox(height: 8),
            //   LinearProgressIndicator(
            //     value: timeLeftPercentage,
            //     backgroundColor: Colors.grey[300],
            //     color: Colors.green,
            //   ),
            //   const SizedBox(height: 4),
            //   Text(
            //     'Ends in $timeLeftText',
            //     style: const TextStyle(color: Colors.red, fontSize: 12),
            //   ),
          ],
        ),
      ),
    );
  }

  // double _calculateTimeLeftPercentage(Timestamp expiryDate) {
  //   final DateTime now = DateTime.now();
  //   final Duration totalDuration = expiryDate.toDate().difference(DateTime.now());
  //   final Duration remainingDuration = expiryDate.toDate().difference(DateTime.now());

  //   return remainingDuration.inSeconds / totalDuration.inSeconds;
  // }

  // String _formatTimeLeft(Timestamp expiryDate) {
  //   final Duration timeLeft = expiryDate.toDate().difference(DateTime.now());
  //   final int hours = timeLeft.inHours;
  //   final int minutes = timeLeft.inMinutes % 60;
  //   final int seconds = timeLeft.inSeconds % 60;

  //   return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  // }

  // String _calculateTimeLeft(Timestamp expiryDate) {
  //   final timeLeft = expiryDate.toDate().difference(DateTime.now());
  //   return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m';
  // }
}
