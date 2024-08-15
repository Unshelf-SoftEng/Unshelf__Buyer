import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:unshelf_buyer/models/product_model.dart';

enum OrderStatus { all, pending, ready, completed }

OrderStatus orderStatusFromString(String status) {
  switch (status) {
    case 'Pending':
      return OrderStatus.pending;
    case 'Completed':
      return OrderStatus.completed;
    case 'Ready':
      return OrderStatus.ready;
    default:
      throw Exception('Unknown order status: $status');
  }
}

class OrderModel {
  final String id;
  final DocumentReference buyerId;
  final List<OrderItem> items;
  OrderStatus status;
  final Timestamp createdAt;
  List<ProductModel> products = [];
  double totalPrice;
  String buyerName;
  Timestamp? completionDate;
  String? pickUpCode;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.items,
    required this.status,
    required this.createdAt,
    this.totalPrice = 0,
    this.products = const [],
    this.buyerName = '',
    this.completionDate,
    this.pickUpCode = '',
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OrderModel(
      id: doc.id,
      status: orderStatusFromString(data['status'] as String),
      createdAt: data['created_at'] as Timestamp,
      buyerId: data['buyer_id'] as DocumentReference,
      items: List<OrderItem>.from(
        data['order_items'].map((item) => OrderItem.fromMap(item)),
      ),
      products: [],
    );
  }

  static Future<OrderModel> fetchOrderWithProducts(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final orderModel = OrderModel(
      id: doc.id,
      status: orderStatusFromString(data['status'] as String),
      createdAt: data['created_at'] as Timestamp,
      buyerId: data['buyer_id'] as DocumentReference,
      items: List<OrderItem>.from(
        data['order_items'].map((item) => OrderItem.fromMap(item)),
      ),
      products: [],
      completionDate: data['completion_date'] as Timestamp?,
    );

    List<DocumentReference> productRefs = [];
    for (var item in orderModel.items) {
      productRefs.add(item.productId);
    }

    final productSnapshots =
        await Future.wait(productRefs.map((ref) => ref.get()));

    final products = productSnapshots
        .map((snapshot) => ProductModel.fromSnapshot(snapshot))
        .toList();

    // Fetch the buyer's name
    await FirebaseFirestore.instance
        .doc(orderModel.buyerId.path)
        .get()
        .then((buyerSnapshot) {
      orderModel.buyerName = buyerSnapshot.data()!['name'] as String;
    });

    // Return a new OrderModel with the populated products
    return OrderModel(
      id: orderModel.id,
      status: orderModel.status,
      createdAt: orderModel.createdAt,
      buyerId: orderModel.buyerId,
      items: orderModel.items,
      products: products,
      totalPrice: products.fold<double>(
        0,
        (previousValue, element) => previousValue + element.price,
      ),
      buyerName: orderModel.buyerName,
    );
  }
}

class OrderItem {
  final int quantity;
  final DocumentReference productId;

  OrderItem({
    required this.quantity,
    required this.productId,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      quantity: map['quantity'] as int,
      productId: map['product_id'] as DocumentReference,
    );
  }
}
