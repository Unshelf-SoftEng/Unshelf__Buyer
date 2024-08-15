import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/basket_view.dart';
import 'package:unshelf_buyer/map_view.dart';
import 'package:unshelf_buyer/product_view.dart';
import 'package:unshelf_buyer/profile_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomeView();
  }
}

class HomeView extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6E9E57), // Green color as in the image
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
                  color: Color(0xFFA3C38C), // Light green color for the icon
                ),
              ),
              Text(
                "Search",
                style: TextStyle(
                  color: Color(0xFFA3C38C), // Light green color for the text
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BasketView()),
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCarouselBanner(),
            _buildCategories(),
            _buildSellingOutSection(),

            // _buildBundleDealsSection(),
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CarouselSlider(
        options: CarouselOptions(height: 150.0, autoPlay: true),
        items: [1, 2, 3, 4, 5].map((i) {
          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: const BoxDecoration(
                  color: Colors.green,
                ),
                child: Center(
                  child: Text(
                    'Christmas Mega Sale Banner $i',
                    style: const TextStyle(fontSize: 16.0, color: Colors.white),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
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

  // Widget _buildBundleDealsSection() {
  //   return _buildProductCarousel('Bundle Deals', 'bundleDeals');
  // }

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
                return _buildProductCard(data, productId, context);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String productId, BuildContext context) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '₱${data['price']}',
                style: const TextStyle(fontSize: 14.0, color: Colors.green),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Ends in: ${_calculateTimeLeft(data['expiryDate'])}',
                style: const TextStyle(fontSize: 12.0, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateTimeLeft(Timestamp expiryDate) {
    final timeLeft = expiryDate.toDate().difference(DateTime.now());
    return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m';
  }
}
