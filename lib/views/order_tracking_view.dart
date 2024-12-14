import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/order_details_view.dart';
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
        'docId': orderId,
        'orderId': orderData['orderId'],
        'orderItems': orderItemsDetails,
        'status': orderData['status'],
        'isPaid': orderData['isPaid'],
        'createdAt': orderData['createdAt'].toDate(),
        'cancelledAt': orderData['cancelledAt'] ?? null,
        'completedAt': orderData['completedAt'] ?? null,
        'totalPrice': orderData['totalPrice'],
        'pickupTime': orderData['pickupTime'].toDate(),
        'pickupCode': orderData['pickupCode'] ?? '...',
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
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: _auth.currentUser!.uid)
            .where('status', isNotEqualTo: 'Completed')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderId = orders[index].id;
              final isDarkBackground = index % 2 == 0;

              return FutureBuilder<Map<String?, dynamic>>(
                future: fetchOrderDetails(orderId),
                builder: (context, orderSnapshot) {
                  if (!orderSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orderDetails = orderSnapshot.data!;
                  final storeName = orderDetails['storeName'];
                  final storeImageUrl = orderDetails['storeImageUrl'];
                  final isPaid = orderDetails['isPaid'];
                  final status = orderDetails['status'];
                  final total = orderDetails['totalPrice'];
                  final pickupTime = orderDetails['pickupTime'];
                  final pickupCode = orderDetails['pickupCode'];
                  final orderItems = orderDetails['orderItems'];
                  final createdAt = orderDetails['createdAt'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsView(orderDetails: orderDetails),
                        ),
                      );
                    },
                    child: Container(
                      color: isDarkBackground ? Colors.grey[200] : Colors.grey[100],
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Middle Section: Order Info
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order ID: $orderId',
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    createdAt.toString().split(' ')[0],
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Status: $status',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Right Section: Price and Payment Status
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₱ ${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                decoration: BoxDecoration(
                                  color: isPaid ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  isPaid ? 'Paid' : 'Unpaid',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
