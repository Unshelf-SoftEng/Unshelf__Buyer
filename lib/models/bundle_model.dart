import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/models/item_model.dart';
import 'package:unshelf_buyer/models/product_model.dart';

class BundleModel implements ItemModel {
  @override
  String get id => bundleId;
  final String bundleId;
  String name;
  List<String> productIds;
  double price;
  int stock;
  int discount;
  String mainImageUrl;
  List<String>? additionalImageUrls;
  List<ProductModel>? products;

  BundleModel({
    required this.bundleId,
    required this.name,
    required this.productIds,
    required this.price,
    required this.mainImageUrl,
    required this.stock,
    required this.discount,
    this.additionalImageUrls,
    this.products,
  });

  // Factory method to create StoreModel from Firebase document snapshot
  factory BundleModel.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BundleModel(
      bundleId: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: data['stock'] ?? 0,
      discount: data['discount'] ?? 0,
      productIds: (data['productIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      mainImageUrl: data['mainImageUrl'] ?? '',
      additionalImageUrls: (data['additionalImageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  factory BundleModel.fromJson(Map<String, dynamic> json) {
    List<ProductModel> productList = json['products'] != null
        ? (json['products'] as List)
            .map((product) => ProductModel.fromJson(product))
            .toList()
        : [];

    List<String> productIdList =
        productList.map((product) => product.id).toList();

    return BundleModel(
      bundleId: '',
      name: json['bundle_name'] ?? '',
      products: productList,
      productIds: productIdList,
      price: 0.0,
      stock: 0,
      discount: 0,
      mainImageUrl: '',
    );
  }
}
