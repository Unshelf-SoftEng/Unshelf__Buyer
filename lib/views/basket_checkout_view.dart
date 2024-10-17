import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_buyer/views/chat_screen.dart';
import 'package:unshelf_buyer/views/order_address_view.dart';
import 'package:unshelf_buyer/views/order_payment_view.dart';
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
  Map<String, String> selectedOptions = {};
  double totalAmount = 0.0;
  String storeName = '';
  String storeImageUrl = '';

  @override
  void initState() {
    super.initState();
    fetchStoreDetails();
    calculateTotalAmount();
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

  void onDeliveryOrPickupChanged(String sellerId, String value) {
    setState(() {
      selectedOptions[sellerId] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sellerId = widget.sellerId;
    final displayedStoreName = storeName ?? 'Loading...';
    final displayedStoreImageUrl = storeImageUrl;
    final orderViewModel = Provider.of<OrderViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E9E57),
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.message,
                color: Color(0xFF6E9E57),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
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
                  backgroundImage: displayedStoreImageUrl.isNotEmpty ? NetworkImage(displayedStoreImageUrl) : null,
                ),
                const SizedBox(width: 10),
                Text(displayedStoreName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: DropdownButton<String>(
              value: selectedOptions[sellerId] ?? 'For delivery',
              items: <String>['For delivery', 'For pickup'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) => onDeliveryOrPickupChanged(sellerId!, value!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListTile(
              title: Text(selectedOptions[sellerId] == 'For delivery' ? 'Delivery Details' : 'Pickup Details'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                if (selectedOptions[sellerId] == 'For delivery') {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditOrderAddressView(),
                      ));
                } else {
                  // Show a Cupertino dialog for selecting date and time
                }
              },
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 200.0,
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
                        Text('₱${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
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
              onPressed: () async {
                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    // Initiate the payment process via ViewModel
                    bool paymentSuccess = await orderViewModel.processOrderAndPayment(
                      user.uid,
                      widget.basketItems,
                      widget.sellerId!,
                      totalAmount,
                    );

                    debugPrint("WHAT THE HELL IS THIS?${paymentSuccess}");
                    // Only navigate to OrderPlacedView if the payment is successful
                    if (paymentSuccess) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderPlacedView()),
                      );
                    }
                  } catch (e) {
                    // Handle payment error (e.g., show an error dialog)
                    print('Payment error: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 106, 153, 78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text(
                  "CONFIRM",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
