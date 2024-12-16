import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/order_details_view.dart';
import 'package:unshelf_buyer/views/profile_view.dart';
import 'package:unshelf_buyer/views/review_view.dart'; // Assuming ReviewPage exists

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
        // Fetch batch details from orderItems
        final batchSnapshot = await FirebaseFirestore.instance.collection('batches').doc(item['batchId']).get();
        final batchData = batchSnapshot.data();

        if (batchData != null) {
          // Fetch product details from batch
          final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(batchData['productId']).get();
          final productData = productSnapshot.data();

          if (productData != null) {
            // Add the combined batch and product details to the order items list.
            orderItemsDetails.add({
              'name': productData['name'],
              'price': batchData['price'],
              'mainImageUrl': productData['mainImageUrl'] ?? '',
              'quantity': item['quantity'],
              'quantifier': productData['quantifier'],
              'batchDiscount': batchData['discount'],
              'expiryDate': batchData['expiryDate'],
            });
          }
        }
      }

      return {
        'storeName': storeData?['store_name'] ?? '',
        'storeImageUrl': storeData?['store_image_url'] ?? '',
        'storeId': orderData['sellerId'],
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
        'isReviewed': orderData['isReviewed'].toString() ?? 'false',
      };
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0AB68B),
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          "Order History",
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color(0xFF92DE8B),
            height: 6.0,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: _auth.currentUser!.uid)
            .orderBy('createdAt', descending: true)
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
                  final isReviewed = orderDetails['isReviewed'];
                  final total = orderDetails['totalPrice'];
                  final pickupTime = orderDetails['pickupTime'];
                  final pickupCode = orderDetails['pickupCode'];
                  final createdAt = orderDetails['createdAt'];

                  debugPrint("? $isReviewed");
                  // Determine color based on order status
                  Color statusColor;
                  switch (status) {
                    case 'Pending':
                      statusColor = Colors.orange;
                      break;
                    case 'Cancelled':
                      statusColor = Colors.red;
                      break;
                    case 'Completed':
                      statusColor = Colors.green;
                      break;
                    default:
                      statusColor = Colors.grey;
                  }

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main Order Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order ID: ${orderDetails['orderId']}',
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
                                        color: statusColor, // Use color based on status
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₱ ${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0AB68B),
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      // Show Review Button for Completed Orders
                                      if (status == 'Completed')
                                        if (isReviewed == 'true')
                                          Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(255, 138, 255, 191),
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: const Text(
                                              'Reviewed',
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black,
                                              ),
                                            ),
                                          )
                                        else
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ReviewPage(
                                                    orderDocId: orderId,
                                                    orderId: orderDetails['orderId'],
                                                    storeId: orderDetails['storeId'], // Assuming storeId is available
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(255, 255, 255, 138),
                                                borderRadius: BorderRadius.circular(12.0),
                                              ),
                                              child: const Text(
                                                '+ Review',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      // ElevatedButton(
                                      //   onPressed: () {
                                      //     Navigator.push(
                                      //       context,
                                      //       MaterialPageRoute(
                                      //         builder: (context) => ReviewPage(
                                      //           orderId: orderId,
                                      //           storeId: orderDetails['sellerId'], // Assuming storeId is available
                                      //         ),
                                      //       ),
                                      //     );
                                      //   },
                                      //   style: ElevatedButton.styleFrom(
                                      //     fixedSize: Size(100, 60),
                                      //     backgroundColor: const Color.fromARGB(255, 233, 255, 234),
                                      //   ),
                                      //   child: const Text('+ Review'),
                                      // ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                                        decoration: BoxDecoration(
                                          color: isPaid ? const Color(0xFF0AB68B) : Colors.red,
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
        PageRouteBuilder(
          pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
            return HomeView();
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      break;
    case 1:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
            return MapPage();
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      break;
    case 2:
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (BuildContext context, Animation<double> animation1, Animation<double> animation2) {
            return ProfileView();
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      break;
  }
}
