import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/chat_screen.dart';
import 'package:unshelf_buyer/views/basket_checkout_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

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

      // Fetch product details
      final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(productId).get();

      if (productSnapshot.exists) {
        final productData = productSnapshot.data();
        final sellerId = productData?['sellerId'];

        // Fetch store details
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
        backgroundColor: const Color(0xFF6E9E57),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: const Color.fromARGB(255, 200, 221, 150),
              height: 6.0,
            )),
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
              GestureDetector(
                onTap: () {
                  if (sellerId != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoreView(storeId: sellerId),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: sellerId != null ? CachedNetworkImageProvider(storeImageUrl) : null,
                      radius: 20,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      sellerId != null ? storeName : 'Loading...',
                      style: const TextStyle(fontSize: 16),
                    ),
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
                                // Notify user they can only order from one store
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('You can only order from one store at a time.'),
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Text('₱$productPrice', style: const TextStyle(color: Colors.grey)),
                            Row(
                              children: [
                                const Text("Qty: "),
                                IconButton(
                                  icon: const Icon(Icons.remove),
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
                                  icon: const Icon(Icons.add),
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
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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
            const Spacer(),
            Text("Total: ₱$total", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              onPressed: selectedProductIds.isEmpty
                  ? null
                  : () {
                      // filter selected items based on selectedProductIds
                      final selectedItems = groupedBasketItems[selectedSellerId]!
                          .where((item) => selectedProductIds.contains(item['productId']))
                          .toList();

                      // navigate and send selected items to CheckoutView
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutView(basketItems: selectedItems, sellerId: selectedSellerId),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 106, 153, 78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text("CHECKOUT",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
