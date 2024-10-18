import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/profile_view.dart';

class OrderTrackingView extends StatelessWidget {
  const OrderTrackingView({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> fetchOrderDetails(String orderId) async {
    final orderSnapshot = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    final orderData = orderSnapshot.data();

    if (orderData != null) {
      final storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(orderData['sellerId']).get();
      final storeData = storeSnapshot.data();

      final List<Map<String?, dynamic>> orderItemsDetails = [];

      for (var item in orderData['orderItems']) {
        final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(item['productId']).get();
        final productData = productSnapshot.data();

        if (productData != null) {
          orderItemsDetails.add({
            'name': productData['name'],
            'price': productData['price'],
            'mainImageUrl': productData['mainImageUrl'],
            'quantity': item['quantity'],
            'quantifier': productData['quantifier'],
          });
        } else {}
      }

      // Here, we ensure that the total is returned as an int by using .toInt()
      final int total = orderItemsDetails.fold<num>(0, (sum, item) => sum + item['price'] * item['quantity']).toInt();

      return {
        'storeName': storeData?['store_name'] ?? '',
        'storeImageUrl': storeData?['store_image_url'] ?? '',
        'orderItems': orderItemsDetails,
        'status': orderData['status'],
        'isPaid': orderData['isPaid'],
        'createdAt': orderData['createdAt'].toDate(),
        'totalPrice': orderData['totalPrice'],
        'pickupTime': orderData['pickupTime']
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E9E57),
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          "Order Tracking",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('orders').where('buyerId', isEqualTo: _auth.currentUser!.uid).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderId = orders[index].id;
              return FutureBuilder<Map<String?, dynamic>>(
                future: fetchOrderDetails(orderId),
                builder: (context, orderSnapshot) {
                  if (!orderSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  debugPrint("Issue is inside listview");
                  final orderDetails = orderSnapshot.data!;
                  final storeName = orderDetails['storeName'];
                  final storeImageUrl = orderDetails['storeImageUrl'];
                  final isPaid = orderDetails['isPaid'];
                  final status = orderDetails['status'];
                  final total = orderDetails['totalPrice'];
                  final pickupTime = orderDetails['pickupTime'];
                  final orderItems = orderDetails['orderItems'];
                  final createdAt = orderDetails['createdAt'];

                  debugPrint("Issue is not inside listview");
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(storeImageUrl),
                          ),
                          title: Text(storeName),
                          subtitle: Text(
                            isPaid ? "Paid" : "To be Paid",
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text("Delivery details"),
                          subtitle: Text("Status: $status\nPickup Time: $pickupTime\nOrdered On: $createdAt"),
                        ),
                        const Divider(),
                        ...orderItems.map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Image.network(item['mainImageUrl'], width: 60, height: 60, fit: BoxFit.cover),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      Text(
                                        'PHP ${item['price']} / ${item['quantifier']}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        'x${item['quantity']}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₱${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("Total: ₱${total.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
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
        MaterialPageRoute(builder: (context) => MapPage()),
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
