import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/models/product_model.dart';

class RestockViewModel extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _error = '';

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('products').get();
      _products =
          snapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();
    } catch (e) {
      _error = 'Failed to fetch products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> batchRestock(List<ProductModel> productsToRestock) async {
    _isLoading = true;
    notifyListeners();

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var product in productsToRestock) {
        final docRef = FirebaseFirestore.instance
            .collection('products')
            .doc(product.productId);
        batch.update(docRef, {'quantity': product.stock});
      }
      await batch.commit();
    } catch (e) {
      _error = 'Failed to restock products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
