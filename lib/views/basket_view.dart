import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/checkout_view.dart';

class BasketView extends StatefulWidget {
  @override
  _BasketViewState createState() => _BasketViewState();
}

class _BasketViewState extends State<BasketView> {
  User? user;
  Map<String, List<Map<String, dynamic>>> groupedBasketItems = {};
  Set<String> selectedProductIds = {};
  double total = 0.0;
  String? selectedSellerId;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    fetchBasketItems();
  }

  void fetchBasketItems() async {
    if (user == null) return;

    final basketSnapshot = await FirebaseFirestore.instance.collection('baskets').doc(user!.uid).collection('cart_items').get();

    Map<String, List<Map<String, dynamic>>> groupedItems = {};

    for (var doc in basketSnapshot.docs) {
      final productId = doc.id;
      final quantity = doc['quantity'];

      // Fetch product details from products collection
      final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(productId).get();

      if (productSnapshot.exists) {
        final productData = productSnapshot.data();
        final sellerId = productData?['sellerId'];

        // Fetch store details from stores collection
        final storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(sellerId).get();

        if (storeSnapshot.exists) {
          final storeData = storeSnapshot.data();

          if (!groupedItems.containsKey(sellerId)) {
            groupedItems[sellerId] = [];
          }

          groupedItems[sellerId]!.add({
            'productId': productId,
            'quantity': quantity,
            'name': productData?['name'],
            'price': productData?['price'],
            'mainImageUrl': productData?['mainImageUrl'],
            'storeName': storeData?['store_name'],
            'storeImageUrl': storeData?['store_image_url'],
          });
        }
      }
    }

    setState(() {
      groupedBasketItems = groupedItems;
    });
  }

  void updateTotal() {
    double newTotal = 0.0;
    selectedProductIds.forEach((productId) {
      groupedBasketItems.forEach((sellerId, items) {
        for (var item in items) {
          if (item['productId'] == productId) {
            newTotal += item['price'] * item['quantity'];
          }
        }
      });
    });

    setState(() {
      total = newTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6E9E57), // Green color as in the image
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          "Basket",
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
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(builder: (context) => ChatView()),
              // );
            },
          ),
        ],
      ),
      body: ListView(
        children: groupedBasketItems.entries.map((entry) {
          final sellerId = entry.key;
          final storeItems = entry.value;
          final storeName = storeItems[0]['storeName'];
          final storeImageUrl = storeItems[0]['storeImageUrl'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(storeImageUrl),
                    ),
                    SizedBox(width: 10),
                    Text(storeName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ...storeItems.map((item) {
                final productId = item['productId'];
                final productName = item['name'];
                final productPrice = item['price'];
                final productQuantity = item['quantity'];
                final productImageUrl = item['mainImageUrl'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: selectedProductIds.contains(productId),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              if (selectedSellerId == null || selectedSellerId == sellerId) {
                                selectedProductIds.add(productId);
                                selectedSellerId = sellerId;
                              } else {
                                // Notify user
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('You can only select products from one store at a time.'),
                                ));
                              }
                            } else {
                              selectedProductIds.remove(productId);
                              if (selectedProductIds.isEmpty) {
                                selectedSellerId = null;
                              }
                            }
                            updateTotal(); // Update total price
                          });
                        },
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(productImageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Text('₱$productPrice', style: TextStyle(color: Colors.grey)),
                            Row(
                              children: [
                                Text("Qty: "),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: productQuantity > 1
                                      ? () {
                                          setState(() {
                                            item['quantity']--;
                                            updateTotal();
                                          });
                                        }
                                      : null,
                                ),
                                Text('$productQuantity'),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    setState(() {
                                      item['quantity']++;
                                      updateTotal();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text('₱${(productPrice * productQuantity).toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        }).toList(),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Text("Total: ₱$total"),
            Spacer(),
            ElevatedButton(
              onPressed: selectedProductIds.isEmpty
                  ? null
                  : () {
                      // filter selected items based on selectedProductIds
                      final selectedItems = groupedBasketItems[selectedSellerId]!
                          .where((item) => selectedProductIds.contains(item['productId']))
                          .toList();

                      // navigate and send selected items to CheckoutView
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutView(basketItems: selectedItems, sellerId: selectedSellerId),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text("CHECKOUT", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
