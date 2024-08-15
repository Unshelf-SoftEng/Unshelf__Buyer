import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/models/item_model.dart';

class ProductModel implements ItemModel {
  @override
  String get id => productId;
  final String productId;
  String name;
  String description;
  double price;
  int stock;
  DateTime expiryDate;
  int discount;
  String mainImageUrl;
  List<String>? additionalImageUrls;

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
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      discount: data['discount'] ?? 0,
      mainImageUrl: data['mainImageUrl'] ?? '',
      additionalImageUrls: (data['additionalImageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  // Method to convert StoreModel to Json
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'expiryDate': expiryDate.toIso8601String(),
      'discount': discount,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? 0.0,
      stock: json['stock'] ?? 0,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : DateTime.now(),
      discount: json['discount'] ?? 0,
      mainImageUrl: json['mainImageUrl'] ?? '',
    );
  }
}
