import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final DateTime expiryDate;
  final int discount;
  final String mainImageUrl;
  final List<String>? additionalImageUrls;

  ProductModel({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.expiryDate,
    required this.discount,
    required this.mainImageUrl,
    this.additionalImageUrls,
  });

  // Factory method to create StoreModel from Firebase document snapshot
  factory ProductModel.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      productId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: data['stock'] ?? 0,
      expiryDate: (data['expiry_date'] as Timestamp).toDate(),
      discount: data['discount'] ?? 0,
      mainImageUrl: data['main_image_url'] ?? '',
      additionalImageUrls: (data['additional_image_urls'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }
}
