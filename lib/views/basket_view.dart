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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    fetchBasketItems();
  }

  void toggleStoreSelection(String sellerId, bool isSelected) {
    final storeItems = groupedBasketItems[sellerId];
    if (storeItems != null) {
      setState(() {
        if (isSelected) {
          storeItems.forEach((item) => selectedBatchIds.add(item['batchId']));
          selectedSellerId = sellerId; // Update the selected seller ID
        } else {
          storeItems.forEach((item) => selectedBatchIds.remove(item['batchId']));

          if (selectedBatchIds.isEmpty) {
            selectedSellerId = null;
          }
        }
        updateTotal();
      });
    }
  }

  void fetchBasketItems() async {
    if (user == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      final basketSnapshot = await FirebaseFirestore.instance.collection('baskets').doc(user!.uid).collection('cart_items').get();
      final batchIds = basketSnapshot.docs.map((doc) => doc.id).toList();
      final quantities = {for (var doc in basketSnapshot.docs) doc.id: doc['quantity']};

      // Fetch all batch details in a single query
      final batchSnapshots =
          await FirebaseFirestore.instance.collection('batches').where(FieldPath.documentId, whereIn: batchIds).get();

      final productIds = batchSnapshots.docs.map((doc) => doc['productId']).toSet();
      final sellerIds = batchSnapshots.docs.map((doc) => doc['sellerId']).toSet();

      // Fetch all product and store details concurrently
      final productSnapshotsFuture =
          FirebaseFirestore.instance.collection('products').where(FieldPath.documentId, whereIn: productIds.toList()).get();

      final storeSnapshotsFuture =
          FirebaseFirestore.instance.collection('stores').where(FieldPath.documentId, whereIn: sellerIds.toList()).get();

      final productSnapshots = await productSnapshotsFuture;
      final storeSnapshots = await storeSnapshotsFuture;

      final products = {for (var doc in productSnapshots.docs) doc.id: doc.data()};
      final stores = {for (var doc in storeSnapshots.docs) doc.id: doc.data()};

      Map<String, List<Map<String, dynamic>>> groupedItems = {};

      for (var batchDoc in batchSnapshots.docs) {
        final batchData = batchDoc.data();
        final batchId = batchDoc.id;
        final quantity = quantities[batchId] ?? 0;

        final productId = batchData['productId'];
        final sellerId = batchData['sellerId'];

        final productData = products[productId];
        final storeData = stores[sellerId];

        if (productData != null && storeData != null) {
          if (!groupedItems.containsKey(sellerId)) {
            groupedItems[sellerId] = [];
          }

          groupedItems[sellerId]!.add({
            'batchId': batchId,
            'quantity': quantity,
            'batchPrice': batchData['price'],
            'batchDiscount': batchData['discount'],
            'batchStock': batchData['stock'],
            'productName': productData['name'],
            'productMainImageUrl': productData['mainImageUrl'],
            'productQuantifier': productData['quantifier'],
            'storeName': storeData['store_name'],
            'storeImageUrl': storeData['store_image_url'],
          });
        }
      }

      setState(() {
        groupedBasketItems = groupedItems;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching basket items: $e");
      setState(() {
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E9E57),
        elevation: 0,
        toolbarHeight: 65,
        title: const Text(
          "Basket",
          style: TextStyle(color: Colors.white, fontSize: 25.0),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: const Color.fromARGB(255, 200, 221, 150),
              height: 6.0,
            )),
      ),
      body: Stack(
        children: [
          if (!isLoading)
            ListView(
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
                                    if (selectedSellerId == null || selectedSellerId == sellerId) {
                                      selectedBatchIds.add(batchId);
                                      selectedSellerId = sellerId;
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('You can only order from one store at a time.'),
                                      ));
                                    }
                                  } else {
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
                                  image: CachedNetworkImageProvider(productMainImageUrl),
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
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
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

                      final cleanBasketItems = selectedItems.map((item) {
                        return {
                          'batchId': item['batchId'],
                          'productName': item['productName'],
                          'productMainImageUrl': item['productMainImageUrl'],
                          'batchPrice':
                              (item['batchPrice'] * (1 - item['batchDiscount'] / 100) as num).toDouble(), // Explicit double cast
                          'quantity': item['quantity'],
                        };
                      }).toList();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutView(basketItems: cleanBasketItems, sellerId: selectedSellerId),
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
