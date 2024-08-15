import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // Add this line
import 'package:image_picker/image_picker.dart';
import 'package:unshelf_buyer/models/bundle_model.dart';
import 'package:unshelf_buyer/models/product_model.dart';

class BundleViewModel extends ChangeNotifier {
  final TextEditingController bundleNameController = TextEditingController();
  final TextEditingController bundlePriceController = TextEditingController();
  final TextEditingController bundleStockController = TextEditingController();
  final TextEditingController bundleDiscountController =
      TextEditingController();
  final formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  List<ProductModel> _products = [];
  Set<String> _selectedProductIds = {};
  int _maxStock = 0;

  List<ProductModel> get products => _products;
  Set<String> get selectedProductIds => _selectedProductIds;
  int get maxStock => _maxStock;

  Uint8List? _mainImageData;
  Uint8List? get mainImageData => _mainImageData;

  List<BundleModel> _suggestions = [];
  List<BundleModel> get suggestions => _suggestions;

  Future<void>? _fetchSuggestionsFuture;

  BundleViewModel() {
    _fetchProducts();
  }

  void initializeControllers(BundleModel bundle) {
    bundleNameController.text = bundle.name;
    bundlePriceController.text = bundle.price.toString();
    bundleStockController.text = bundle.stock.toString();
    bundleDiscountController.text = bundle.discount.toString();

    _selectedProductIds = bundle.productIds.toSet();
    _updateBundleStock();
  }

  Future<void> _fetchProducts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      _products = productSnapshot.docs
          .map((doc) => ProductModel.fromSnapshot(doc))
          .toList();

      print('Products: $_products');
      notifyListeners();
    }
  }

  void addProductToBundle(String productId) {
    _selectedProductIds.add(productId);
    _updateBundleStock();
    notifyListeners();
  }

  void removeProductFromBundle(String productId) {
    _selectedProductIds.remove(productId);
    _updateBundleStock();
    notifyListeners();
  }

  void _updateBundleStock() {
    if (_selectedProductIds.isEmpty) {
      _maxStock = 0;
    } else {
      final selectedProducts = _products
          .where((product) => _selectedProductIds.contains(product.id))
          .toList();
      _maxStock = selectedProducts
          .map((product) => product.stock)
          .reduce((min, stock) => stock < min ? stock : min);
    }
    notifyListeners();
  }

  Future<void> createBundle() async {
    try {
      final bundleName = bundleNameController.text;
      final bundlePrice = double.tryParse(bundlePriceController.text) ?? 0.0;
      final bundleStock = int.tryParse(bundleStockController.text) ?? 0;
      final bundleDiscount =
          double.tryParse(bundleDiscountController.text) ?? 0.0;

      if (bundleName.isEmpty || _selectedProductIds.isEmpty) {
        throw Exception('Bundle name or selected products cannot be empty');
      }

      User user = FirebaseAuth.instance.currentUser!;

      final mainImageRef = FirebaseStorage.instance
          .ref()
          .child('bundle_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await mainImageRef.putData(_mainImageData!);

      final mainImageUrl = await mainImageRef.getDownloadURL();

      final bundleData = {
        'name': bundleName,
        'productIds': _selectedProductIds.toList(),
        'price': bundlePrice,
        'stock': bundleStock,
        'discount': bundleDiscount,
        'mainImageUrl': mainImageUrl,
        'sellerId': user.uid,
      };

      await FirebaseFirestore.instance.collection('bundles').add(bundleData);

      notifyListeners();
    } catch (e) {
      // Handle errors appropriately
      print('Failed to create bundle: $e');
      // Optionally, you can show a user-friendly message using a dialog or a snackbar
    }
  }

  Future<void> loadImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        _mainImageData = response.bodyBytes;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  Future<void> pickImage() async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();

      _mainImageData = imageData;
      notifyListeners();
    }
  }

  void deleteMainImage() {
    _mainImageData = null;
    notifyListeners();
  }

  Future<void> fetchSuggestions() async {
    const url = 'http://localhost:8000/api/recommend-bundles/';
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(
      products.map((product) => product.toJson()).toList(),
    );

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Suggestions: $data');

        _suggestions = (data['bundles'] as List)
            .map<BundleModel>((bundle) => BundleModel.fromJson(bundle))
            .toList();

        notifyListeners();
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  Future<void> getSuggestions() {
    if (_fetchSuggestionsFuture != null) {
      return _fetchSuggestionsFuture!;
    }

    // Otherwise, start fetching and store the future
    _fetchSuggestionsFuture = fetchSuggestions();
    return _fetchSuggestionsFuture!;
  }

  @override
  void dispose() {
    bundleNameController.dispose();
    bundleStockController.dispose();
    bundlePriceController.dispose();
    super.dispose();
  }
}
