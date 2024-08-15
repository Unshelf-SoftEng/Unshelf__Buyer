import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:unshelf_buyer/models/product_model.dart';

class ProductViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String? productId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Uint8List? _mainImageData;
  Uint8List? get mainImageData => _mainImageData;

  List<Uint8List?> _additionalImageDataList = List.generate(4, (_) => null);
  List<Uint8List?> get additionalImageDataList => _additionalImageDataList;

  bool _isMainImageNew = false;
  List<bool> _isAdditionalImageNewList = List.generate(4, (_) => false);

  bool _errorFound = false;
  bool get errorFound => _errorFound;

  ProductViewModel({required this.productId}) {
    if (productId != null) fetchProductData();
  }

  Future<void> fetchProductData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (productDoc.exists) {
        final product = ProductModel.fromSnapshot(productDoc);

        nameController.text = product.name;
        priceController.text = product.price.toString();
        quantityController.text = product.stock.toString();
        expiryDateController.text = product.expiryDate.toString();
        descriptionController.text = product.description;
        discountController.text = product.discount.toString();

        final mainImageUrl = product.mainImageUrl;
        final additionalImageUrls = product.additionalImageUrls;

        if (mainImageUrl != null) {
          await loadImageFromUrl(mainImageUrl, true);
        }

        for (int i = 0; i < additionalImageUrls!.length; i++) {
          if (i < _additionalImageDataList.length) {
            await loadImageFromUrl(additionalImageUrls[i], false, index: i);
          }
        }
      }
    } catch (e) {
      // Handle errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadImageFromUrl(String imageUrl, bool isMainImage,
      {int? index}) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        if (isMainImage) {
          _mainImageData = response.bodyBytes;
        } else if (index != null) {
          _additionalImageDataList[index] = response.bodyBytes;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  Future<void> pickImage(bool isMainImage, {int? index}) async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();

      if (isMainImage) {
        _mainImageData = imageData;
        _isMainImageNew = true;
      } else if (index != null) {
        _additionalImageDataList[index] = imageData;
        _isAdditionalImageNewList[index] = true;
      }
      notifyListeners();
    }
  }

  Future<List<String>> uploadImages() async {
    List<String> downloadUrls = [];

    if (_mainImageData != null && _isMainImageNew) {
      try {
        final mainImageRef = FirebaseStorage.instance.ref().child(
            'product_images/main_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await mainImageRef.putData(_mainImageData!);
        final mainImageUrl = await mainImageRef.getDownloadURL();
        downloadUrls.add(mainImageUrl);
      } catch (e) {
        // Handle error
      }
    }

    for (int i = 0; i < _additionalImageDataList.length; i++) {
      if (_additionalImageDataList[i] != null && _isAdditionalImageNewList[i]) {
        try {
          final additionalImageRef = FirebaseStorage.instance.ref().child(
              'product_images/additional_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
          await additionalImageRef.putData(_additionalImageDataList[i]!);
          final additionalImageUrl = await additionalImageRef.getDownloadURL();
          downloadUrls.add(additionalImageUrl);
        } catch (e) {
          // Handle error
        }
      }
    }

    return downloadUrls;
  }

  Future<void> addOrUpdateProductImages() async {
    if (_mainImageData == null) {
      _errorFound = true;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      User? user = FirebaseAuth.instance.currentUser;
      List<String> imageUrls = await uploadImages();

      final mainImageUrl = imageUrls.isNotEmpty ? imageUrls.removeAt(0) : null;

      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
        'main_image_url': mainImageUrl,
        'additional_image_urls': imageUrls,
      });
    } on FirebaseAuthException catch (e) {
      // Handle authentication error
    } catch (e) {
      // Handle other errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void deleteMainImage() {
    _mainImageData = null;
    _isMainImageNew = false;
    notifyListeners();
  }

  void deleteAdditionalImage(int index) {
    _additionalImageDataList[index] = null;
    _isAdditionalImageNewList[index] = false;
    // Shift images to the left
    for (int i = index; i < _additionalImageDataList.length - 1; i++) {
      _additionalImageDataList[i] = _additionalImageDataList[i + 1];
      _isAdditionalImageNewList[i] = _isAdditionalImageNewList[i + 1];
    }
    _additionalImageDataList[_additionalImageDataList.length - 1] = null;
    _isAdditionalImageNewList[_additionalImageDataList.length - 1] = false;
    notifyListeners();
  }

  Future<void> selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      expiryDateController.text = "${picked.toLocal()}".split(' ')[0];
      notifyListeners();
    }
  }

  Future<void> addOrUpdateProduct(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      _isLoading = true;
      notifyListeners();
      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          if (productId == null) {
            List<String> images = await uploadImages();

            await FirebaseFirestore.instance.collection('products').add({
              'sellerId': user.uid,
              'name': nameController.text,
              'description': descriptionController.text,
              'price': double.parse(priceController.text),
              'stock': int.parse(quantityController.text),
              'expiryDate': DateTime.parse(expiryDateController.text),
              'discount': int.parse(discountController.text),
              'mainImageUrl': images[0],
              'additionalImageUrls': images.sublist(1),
              'isListed': true,
            });
          } else {
            await FirebaseFirestore.instance
                .collection('products')
                .doc(productId)
                .update({
              'name': nameController.text,
              'description': descriptionController.text,
              'price': double.parse(priceController.text),
              'stock': int.parse(quantityController.text),
              'expiryDate': DateTime.parse(expiryDateController.text),
              'discount': int.parse(discountController.text),
              'mainImageUrl': '',
              'additionalImageUrls': [],
            });
          }
        } else {
          // Handle user not logged in
        }
      } catch (e) {
        // Handle errors
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
    expiryDateController.dispose();
    discountController.dispose();
    super.dispose();
  }
}
