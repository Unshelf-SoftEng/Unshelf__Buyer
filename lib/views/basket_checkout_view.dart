import 'dart:ffi';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_buyer/views/chat_screen.dart';
import 'package:unshelf_buyer/views/order_placed_view.dart';
import 'package:unshelf_buyer/viewmodels/order_viewmodel.dart';
import 'package:unshelf_buyer/widgets/datetime_picker.dart';
import 'package:unshelf_buyer/widgets/my_switch.dart';

class CheckoutView extends StatefulWidget {
  final List<Map<String, dynamic>> basketItems;
  final String? sellerId;

  const CheckoutView({super.key, required this.basketItems, required this.sellerId});

  @override
  _CheckoutViewState createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  Map<String, Map<String, dynamic>> storeDetails = {};
  double totalAmount = 0.0;
  double totalRegular = 0.0;
  double totalWithDisc = 0.0;
  String storeName = '';
  String storeImageUrl = '';
  DateTime? selectedPickupDateTime;
  String selectedPaymentMethod = 'Cash'; // Default to 'Cash'
  String orderId = '';
  int points = 0;

  bool usePoints = false;

  @override
  void initState() {
    super.initState();
    fetchStoreDetails();
    fetchUserDetails();
    calculateTotalAmount();
    generateOrderId();
  }

  void fetchStoreDetails() async {
    String name = '';
    String image = '';
    for (var item in widget.basketItems) {
      final sellerId = widget.sellerId;
      final storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(sellerId).get();
      if (storeSnapshot.exists) {
        final storeData = storeSnapshot.data();
        name = storeData?['store_name'];
        image = storeData?['store_image_url'];
      }
    }
    setState(() {
      storeName = name;
      storeImageUrl = image;
    });
  }

  void fetchUserDetails() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    int userPoints = 0;
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userSnapshot.exists) {
      userPoints = userSnapshot.data()?['points'];
    }

    setState(() {
      points = userPoints;
    });
  }

  void calculateTotalAmount() {
    totalRegular = (widget.basketItems.fold(0, (sum, item) => sum + item['batchPrice'] * item['quantity']));
    totalAmount = totalRegular;
  }

  void updateTotal() {
    double newTotal = totalRegular;
    if (usePoints) {
      newTotal = totalRegular - points;
    }
    setState(() {
      totalAmount = newTotal;
    });
  }

  Future<void> generateOrderId() async {
    // Get current date in YYYYMMDD format
    String currentDate = DateFormat('yyyyMMdd').format(DateTime.now());

    // Reference to the Firebase collection where orders are stored
    CollectionReference ordersRef = FirebaseFirestore.instance.collection('orders');

    // Query to count orders with the current date
    QuerySnapshot querySnapshot = await ordersRef.where('orderDate', isEqualTo: currentDate).get();

    // Get the number of orders already made today
    int orderCount = querySnapshot.size;

    // Generate the next order number by incrementing the order count
    String nextOrderNumber = (orderCount + 1).toString().padLeft(3, '0');

    // Combine date and order number to create the order ID
    orderId = '$currentDate-$nextOrderNumber';
  }

  Future<void> _selectPickupDateTime() async {
    final DateTime? pickedDateTime = await showDateTimePicker(context: context);

    if (pickedDateTime != null) {
      setState(() {
        selectedPickupDateTime = pickedDateTime;
      });
    }
  }

  void selectPaymentMethod(String method) {
    setState(() {
      selectedPaymentMethod = method;
    });
  }

  Future<void> _confirmOrder() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Create the order document in Firestore
        if (selectedPaymentMethod == 'Card') {
          final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
          bool paymentSuccess = await orderViewModel.processOrderAndPayment(
              user.uid, widget.basketItems, widget.sellerId!, orderId, totalAmount, selectedPickupDateTime!, usePoints, points);
          if (paymentSuccess) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderPlacedView()),
            );
          }
        } else {
          await FirebaseFirestore.instance.collection('orders').add({
            'buyerId': user.uid,
            'completedAt': null,
            'createdAt': DateTime.now(),
            'isPaid': selectedPaymentMethod == 'Card',
            'orderId': orderId,
            'orderItems': widget.basketItems
                .map((item) => {
                      'batchId': item['batchId'],
                      'quantity': item['quantity'],
                      'price': item['batchPrice'],
                    })
                .toList(),
            'sellerId': widget.sellerId,
            'status': "Pending",
            'totalPrice': totalAmount,
            'pickupTime': Timestamp.fromDate(selectedPickupDateTime!),
            'pointsDiscount': usePoints ? points : 0
          });

          // Process each item in the basket
          for (var item in widget.basketItems) {
            String batchId = item['batchId'];
            int quantity = item['quantity'];

            // Fetch the batch document
            DocumentSnapshot batchSnapshot = await FirebaseFirestore.instance.collection('batches').doc(batchId).get();

            if (batchSnapshot.exists) {
              Map<String, dynamic>? batchData = batchSnapshot.data() as Map<String, dynamic>?;
              int currentStock = batchData?['stock'] ?? 0;

              // Update the stock for the batch
              int newStock = currentStock - quantity;
              if (newStock < 0) {
                throw Exception('Insufficient stock for batch $batchId');
              }

              await FirebaseFirestore.instance.collection('batches').doc(batchId).update({'stock': newStock});
            }

            // Remove the item from the user's cart
            await FirebaseFirestore.instance.collection('baskets').doc(user.uid).collection('cart_items').doc(batchId).delete();
          }

          // Navigate to OrderPlacedView
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderPlacedView()),
          );
        }
      } catch (e) {
        print('Order confirmation error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E9E57),
        elevation: 0,
        toolbarHeight: 60,
        title: const Text("Checkout", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.message, color: Color(0xFF6E9E57)),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: storeImageUrl.isNotEmpty ? NetworkImage(storeImageUrl) : null,
                ),
                const SizedBox(width: 10),
                Text(storeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _selectPickupDateTime,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6E9E57)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                  ),
                  child: const Text('Pickup Time', style: TextStyle(color: Color(0xFF6E9E57))),
                ),
                const SizedBox(width: 10),
                if (selectedPickupDateTime != null)
                  Text(
                    DateFormat('EEE MM-dd-yyyy | h:mm a').format(selectedPickupDateTime!),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              children: [
                _buildPaymentButton('Cash'),
                const SizedBox(width: 10),
                _buildPaymentButton('Card'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.basketItems.length,
              itemBuilder: (context, index) {
                final item = widget.basketItems[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Image.network(item['productMainImageUrl'], width: 80, height: 80, fit: BoxFit.cover),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['productName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Text('₱${item['batchPrice']} x ${item['quantity']}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        '₱${(item['batchPrice'] * item['quantity']).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Switch(
                    onChanged: (value) {
                      setState(() {
                        usePoints = !usePoints;
                      });

                      updateTotal();
                    },
                    value: usePoints,
                    activeColor: Colors.green),
                const SizedBox(width: 10),
                Text(
                  "Use points: -${points.toString()}.00 PHP",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            const Spacer(),
            Text("Total: ₱${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              onPressed: selectedPickupDateTime == null ? null : _confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A994E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text("CONFIRM", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton(String method) {
    final bool isSelected = selectedPaymentMethod == method;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => selectPaymentMethod(method),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF6E9E57) : Colors.transparent,
          side: const BorderSide(color: Color(0xFF6E9E57)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        ),
        child: Text(
          method,
          style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF6E9E57)),
        ),
      ),
    );
  }
}
