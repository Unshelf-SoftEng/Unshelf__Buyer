import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/login_view.dart';

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
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    String name = userDoc['name'];

    return {'name': name, 'profileImageUrl': userDoc['profileImageUrl']};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile data"));
          }

          final userData = snapshot.data!;
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: CachedNetworkImageProvider(userData['profileImageUrl']),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['name'],
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileOption(context, Icons.list_alt, "Activity", 1),
                        _buildProfileOption(context, Icons.payment, "Payment", 2),
                        _buildProfileOption(context, Icons.track_changes, "Order Tracking", 3),
                        _buildProfileOption(context, Icons.favorite, "Favorites", 4),
                        const Divider(),
                        _buildProfileOption(context, Icons.location_on, "Addresses", 5),
                        _buildProfileOption(context, Icons.subscriptions, "Subscriptions", 6),
                        _buildProfileOption(context, Icons.share, "Referrals", 7),
                        _buildProfileOption(context, Icons.card_giftcard, "Vouchers", 8),
                        const Divider(),
                        _buildProfileOption(context, Icons.help, "Help Center", 9),
                        _buildProfileOption(context, Icons.settings, "Settings", 10),
                        _buildProfileOption(context, Icons.support, "Customer Support", 11),
                        _buildProfileOption(context, Icons.logout, "Log Out", 12),
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
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeView(),
                          fullscreenDialog: true,
                        ));
                  },
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
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, num index) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      onTap: () {
        switch (index) {
          case 1:
            break;
          case 2:
            break;
          case 3:
            break;
          case 4:
            break;
          case 5:
            break;
          case 6:
            break;
          case 7:
            break;
          case 8:
            break;
          case 9:
            break;
          case 10:
            break;
          case 11:
            break;
          case 12:
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginView(),
                fullscreenDialog: true,
              ),
            );
            break;
          default:
            Navigator.push(context, MaterialPageRoute(builder: (context) => HomeView()));
            break;
        }
      },
    );
  }
}
