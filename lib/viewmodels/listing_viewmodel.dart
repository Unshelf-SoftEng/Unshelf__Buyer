// viewmodels/item_view_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/models/bundle_model.dart';
import 'package:unshelf_buyer/models/product_model.dart';
import 'package:unshelf_buyer/models/item_model.dart';

class ListingViewModel extends ChangeNotifier {
  List<ItemModel> _items = [];
  bool _isLoading = true;
  bool _showingProducts = true;

  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get showingProducts => _showingProducts;

  ListingViewModel() {
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    _isLoading = true;
    notifyListeners();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch products
        final productSnapshot =
            await FirebaseFirestore.instance.collection('products').where('sellerId', isEqualTo: user.uid).get();

        print('Mapping products');
        final products = productSnapshot.docs
            .map((doc) {
              try {
                return ProductModel.fromSnapshot(doc) as ItemModel?;
              } catch (e) {
                print('Error mapping product: $e');
                return null;
              }
            })
            .where((product) => product != null)
            .cast<ItemModel>()
            .toList();

        // Fetch bundles
        final bundleSnapshot =
            await FirebaseFirestore.instance.collection('bundles').where('sellerId', isEqualTo: user.uid).get();

        final bundles = bundleSnapshot.docs
            .map((doc) {
              try {
                return BundleModel.fromSnapshot(doc) as ItemModel?;
              } catch (e) {
                print('Error mapping bundle: $e');
                return null;
              }
            })
            .where((bundle) => bundle != null)
            .cast<ItemModel>()
            .toList();

        _items = showingProducts ? products : bundles;
      } catch (e) {
        print('Error fetching items: $e');
        _items = [];
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      _items = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    await FirebaseFirestore.instance.collection('products').add(productData);
    _fetchItems(); // Refresh the list
  }

  Future<void> addBundle(Map<String, dynamic> bundleData) async {
    await FirebaseFirestore.instance.collection('bundles').add(bundleData);
    _fetchItems(); // Refresh the list
  }

  Future<void> deleteItem(String itemId, bool isProduct) async {
    final collection = isProduct ? 'products' : 'bundles';
    await FirebaseFirestore.instance.collection(collection).doc(itemId).delete();
    _fetchItems(); // Refresh the list
  }

  void toggleView() {
    _showingProducts = !_showingProducts;
    _fetchItems(); // Refresh the list based on the selected view
  }

  void refreshItems() {
    _fetchItems();
  }

  void clear() {
    _items = [];
    _isLoading = true;
    notifyListeners();
  }
}
