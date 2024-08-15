import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unshelf_buyer/models/order_model.dart';

class OrderViewModel extends ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderStatus _currentStatus = OrderStatus.all;
  OrderModel? _selectedOrder;
  OrderModel? get selectedOrder => _selectedOrder;
  List<OrderModel> get orders => _orders;
  OrderStatus get currentStatus => _currentStatus;

  bool get isLoading => _isLoading;
  bool _isLoading = false;

  late Future<void> fetchOrdersFuture;

  OrderViewModel() {
    fetchOrdersFuture = fetchOrders();
  }

  List<OrderModel> get filteredOrders {
    if (_currentStatus == OrderStatus.all) {
      return _orders;
    }
    return _orders.where((order) => order.status == _currentStatus).toList();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('seller_id',
              isEqualTo: FirebaseFirestore.instance.doc('users/${user.uid}'))
          .orderBy('created_at', descending: true)
          .get();

      _orders = await Future.wait<OrderModel>(querySnapshot.docs
          .map((doc) => OrderModel.fetchOrderWithProducts(doc))
          .toList());

      if (_orders.length == 1) {
        _orders = List<OrderModel>.generate(5, (index) => _orders[0]);
      }

      orders[1].status = OrderStatus.ready;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Failed to fetch orders: $e');
      // Handle errors appropriately
    }
  }

  OrderModel? selectOrder(String orderId) {
    _isLoading = true;
    _selectedOrder = _orders.firstWhere((order) => order.id == orderId);

    _isLoading = false;
    notifyListeners();
    return _selectedOrder;
  }

  void filterOrdersByStatus(String? status) {
    if (status == null || status == 'All') {
      _currentStatus = OrderStatus.all;
    } else if (status == 'Pending') {
      // Filter orders based on status
      _currentStatus = OrderStatus.pending;
    } else if (status == 'Completed') {
      _currentStatus = OrderStatus.completed;
    } else if (status == 'Ready') {
      _currentStatus = OrderStatus.ready;
    }
    notifyListeners();
  }

  void clear() {
    _orders = [];
    _selectedOrder = null;
    _currentStatus = OrderStatus.all;
    notifyListeners();
  }
}
