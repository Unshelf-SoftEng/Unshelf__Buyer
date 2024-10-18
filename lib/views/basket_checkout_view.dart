import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_buyer/views/chat_screen.dart';
import 'package:unshelf_buyer/views/order_placed_view.dart';
import 'package:unshelf_buyer/viewmodels/order_viewmodel.dart';

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
  String storeName = '';
  String storeImageUrl = '';
  TimeOfDay? selectedPickupTime;
  String selectedPaymentMethod = 'Cash'; // Default to 'Cash'
  String orderId = '';

  @override
  void initState() {
    super.initState();
    fetchStoreDetails();
    calculateTotalAmount();
    setDefaultPickupTime();
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

  void calculateTotalAmount() {
    totalAmount = widget.basketItems.fold(0, (sum, item) => sum + item['price'] * item['quantity']);
  }

  void setDefaultPickupTime() {
    final now = DateTime.now();
    final newTime = now.add(const Duration(minutes: 30));
    final hour = newTime.hour % 12 == 0 ? 12 : newTime.hour % 12;
    final minute = newTime.minute;

    setState(() {
      selectedPickupTime = TimeOfDay(hour: hour, minute: minute);
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

  Future<void> _selectPickupTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedPickupTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        selectedPickupTime = pickedTime;
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
        if (selectedPaymentMethod == 'Card') {
          final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);

          await FirebaseFirestore.instance.collection('orders').add({
            'buyerId': user.uid,
            'completedAt': null,
            'createdAt': DateTime.now(),
            'isPaid': true,
            'orderId': orderId,
            'orderItems': widget.basketItems
                .map((item) => {
                      'productId': item['productId'],
                      'quantity': item['quantity'],
                    })
                .toList(),
            'sellerId': widget.sellerId,
            'status': "Pending",
            'totalPrice': totalAmount,
            'pickupTime': selectedPickupTime?.format(context),
          }).then((docRef) {
            debugPrint("Order created with ID: ${docRef.id}");
          });

          // Delete checked out items from the user's basket
          for (var item in widget.basketItems) {
            await FirebaseFirestore.instance
                .collection('baskets')
                .doc(user.uid)
                .collection('cart_items')
                .doc(item['productId'])
                .delete();
          }

          bool paymentSuccess = await orderViewModel.processOrderAndPayment(
            user.uid,
            widget.basketItems,
            widget.sellerId!,
            totalAmount,
            selectedPickupTime?.format(context),
          );
        } else {
          debugPrint("Initiating order creation");
          debugPrint(
              "buyerId: ${user.uid} createdAt: {$DateTime.now()}  \n orderId: ${orderId} sellerId: ${widget.sellerId} \n totalPrice ${totalAmount} \n pickupTime: ${selectedPickupTime?.format(context)}");
          await FirebaseFirestore.instance.collection('orders').add({
            'buyerId': user.uid,
            'completedAt': null,
            'createdAt': DateTime.now(),
            'isPaid': false,
            'orderId': orderId,
            'orderItems': widget.basketItems
                .map((item) => {
                      'productId': item['productId'],
                      'quantity': item['quantity'],
                    })
                .toList(),
            'sellerId': widget.sellerId,
            'status': "Pending",
            'totalPrice': totalAmount,
            'pickupTime': selectedPickupTime?.format(context),
          }).then((docRef) {
            debugPrint("Order created with ID: ${docRef.id}");
          });

          // Delete checked out items from the user's basket
          for (var item in widget.basketItems) {
            await FirebaseFirestore.instance
                .collection('baskets')
                .doc(user.uid)
                .collection('cart_items')
                .doc(item['productId'])
                .delete();
          }

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
                  onPressed: _selectPickupTime,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6E9E57)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                  ),
                  child: const Text('Pickup Time', style: TextStyle(color: Color(0xFF6E9E57))),
                ),
                const SizedBox(width: 10),
                if (selectedPickupTime != null)
                  Text(
                    selectedPickupTime!.format(context),
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
                      Image.network(item['mainImageUrl'], width: 80, height: 80, fit: BoxFit.cover),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Text('₱${item['price']} x ${item['quantity']}', style: const TextStyle(color: Colors.grey)),
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
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            const Spacer(),
            Text("Total: ₱$totalAmount", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              onPressed: _confirmOrder,
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
