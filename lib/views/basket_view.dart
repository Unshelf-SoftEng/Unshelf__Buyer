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
  Set<String> selectedBatchIds = {};
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
      final batchId = doc.id;
      final quantity = doc['quantity'];

      // Fetch batch details
      final batchSnapshot = await FirebaseFirestore.instance.collection('batches').doc(batchId).get();

      if (batchSnapshot.exists) {
        final batchData = batchSnapshot.data();
        final productId = batchData?['productId'];
        final sellerId = batchData?['sellerId'];

        // Fetch product details
        final productSnapshot = await FirebaseFirestore.instance.collection('products').doc(productId).get();

        if (productSnapshot.exists) {
          final productData = productSnapshot.data();

          // Fetch store details
          final storeSnapshot = await FirebaseFirestore.instance.collection('stores').doc(sellerId).get();

          if (storeSnapshot.exists) {
            final storeData = storeSnapshot.data();

            if (!groupedItems.containsKey(sellerId)) {
              groupedItems[sellerId] = [];
            }

            groupedItems[sellerId]!.add({
              'batchId': batchId,
              'quantity': quantity,
              'batchPrice': batchData?['price'],
              'batchDiscount': batchData?['discount'],
              'batchStock': batchData?['stock'],
              'productName': productData?['name'],
              'productMainImageUrl': productData?['mainImageUrl'],
              'productQuantifier': productData?['quantifier'],
              'storeName': storeData?['store_name'],
              'storeImageUrl': storeData?['store_image_url'],
            });
          }
        }
      }
    }

    setState(() {
      groupedBasketItems = groupedItems;
    });
  }

  void updateTotal() {
    double newTotal = 0.0;
    selectedBatchIds.forEach((batchId) {
      groupedBasketItems.forEach((sellerId, items) {
        for (var item in items) {
          if (item['batchId'] == batchId) {
            final discount = item['batchDiscount'] ?? 0;
            final priceAfterDiscount = item['batchPrice'] * (1 - discount / 100);
            newTotal += priceAfterDiscount * item['quantity'];
          }
        }
      });
    });

    setState(() {
      total = newTotal;
    });
  }

  void toggleStoreSelection(String sellerId, bool isSelected) {
    final storeItems = groupedBasketItems[sellerId];
    if (storeItems != null) {
      setState(() {
        if (isSelected) {
          // Add all items from the store to the selected list
          storeItems.forEach((item) => selectedBatchIds.add(item['batchId']));
          selectedSellerId = sellerId; // Update the selected seller ID
        } else {
          // Remove all items from the store from the selected list
          storeItems.forEach((item) => selectedBatchIds.remove(item['batchId']));

          // Reset selectedSellerId only if no items remain selected
          if (selectedBatchIds.isEmpty) {
            selectedSellerId = null;
          }
        }
        updateTotal();
      });
    }
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
          ),
        ),
      ),
      body: ListView(
        children: groupedBasketItems.entries.map((entry) {
          final sellerId = entry.key;
          final storeItems = entry.value;
          final storeName = storeItems[0]['storeName'];
          final storeImageUrl = storeItems[0]['storeImageUrl'];

          final allStoreItemsSelected = storeItems.every((item) => selectedBatchIds.contains(item['batchId']));
          final someStoreItemsSelected = storeItems.any((item) => selectedBatchIds.contains(item['batchId']));

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
                    Checkbox(
                      value: allStoreItemsSelected,
                      tristate: someStoreItemsSelected && !allStoreItemsSelected,
                      onChanged: (isChecked) {
                        toggleStoreSelection(sellerId, isChecked ?? false);
                      },
                    ),
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
                final batchId = item['batchId'];
                final productName = item['productName'];
                final productMainImageUrl = item['productMainImageUrl'];
                final productQuantifier = item['productQuantifier'];
                final batchPrice = item['batchPrice'];
                final batchDiscount = item['batchDiscount'] ?? 0;
                final priceAfterDiscount = batchPrice * (1 - batchDiscount / 100);
                final batchStock = item['batchStock'];
                final batchQuantity = item['quantity'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: selectedBatchIds.contains(batchId),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              // Add the batch to selectedBatchIds
                              if (selectedSellerId == null || selectedSellerId == sellerId) {
                                selectedBatchIds.add(batchId);
                                selectedSellerId = sellerId; // Update the selected seller ID
                              } else {
                                // Show error if trying to select from a different seller
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('You can only order from one store at a time.'),
                                ));
                              }
                            } else {
                              // Remove the batch from selectedBatchIds
                              selectedBatchIds.remove(batchId);

                              // Reset selectedSellerId only if no items remain selected
                              final storeItems = groupedBasketItems[sellerId];
                              final storeBatchesStillSelected = storeItems!.any(
                                (item) => selectedBatchIds.contains(item['batchId']),
                              );

                              if (!storeBatchesStillSelected) {
                                selectedSellerId = null;
                              }
                            }
                            updateTotal();
                          });
                        },
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(productMainImageUrl),
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
                            Text('${productQuantifier}: ₱${priceAfterDiscount.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.grey)),
                            Row(
                              children: [
                                const Text("Qty: "),
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: batchQuantity > 1
                                      ? () {
                                          setState(() {
                                            item['quantity']--;
                                            updateTotal();
                                          });
                                        }
                                      : null,
                                ),
                                Text('$batchQuantity'),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: batchQuantity < batchStock
                                      ? () {
                                          setState(() {
                                            item['quantity']++;
                                            updateTotal();
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text('₱${(priceAfterDiscount * batchQuantity).toStringAsFixed(2)}',
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
            Text("Total: ₱${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              onPressed: selectedBatchIds.isEmpty
                  ? null
                  : () {
                      final selectedItems = groupedBasketItems[selectedSellerId]!
                          .where((item) => selectedBatchIds.contains(item['batchId']))
                          .toList();

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
                child: Text(
                  "CHECKOUT",
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
