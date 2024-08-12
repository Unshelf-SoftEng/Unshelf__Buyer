import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Page',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  Future<Map<String, dynamic>> getUserData() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();

    String name = userDoc['name'];
    String profileImageUrl = await FirebaseStorage.instance.ref(userDoc['profileImageUrl']).getDownloadURL();
    return {'name': name, 'profileImageUrl': profileImageUrl};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading profile data"));
          }

          final userData = snapshot.data!;
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: CachedNetworkImageProvider(userData['profileImageUrl']),
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['name'],
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.emoji_events, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "FOOD HERO BADGE",
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        SizedBox(height: 20),
                        _buildProfileOption(context, Icons.list_alt, "Activity"),
                        _buildProfileOption(context, Icons.payment, "Payment"),
                        _buildProfileOption(context, Icons.track_changes, "Order Tracking"),
                        _buildProfileOption(context, Icons.favorite, "Favorites"),
                        Divider(),
                        _buildProfileOption(context, Icons.location_on, "Addresses"),
                        _buildProfileOption(context, Icons.subscriptions, "Subscriptions"),
                        _buildProfileOption(context, Icons.share, "Referrals"),
                        _buildProfileOption(context, Icons.card_giftcard, "Vouchers"),
                        Divider(),
                        _buildProfileOption(context, Icons.help, "Help Center"),
                        _buildProfileOption(context, Icons.settings, "Settings"),
                        _buildProfileOption(context, Icons.support, "Customer Support"),
                        _buildProfileOption(context, Icons.logout, "Log Out"),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: BottomNavigationBar(
                  currentIndex: 2,
                  onTap: (index) {
                    // Handle Bottom Navigation
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HomeView()));
                  },
                  items: [
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      onTap: () {
        // TEMPORARY: Navigate to HomeView on click
        Navigator.push(context, MaterialPageRoute(builder: (_) => HomeView()));
      },
    );
  }
}
