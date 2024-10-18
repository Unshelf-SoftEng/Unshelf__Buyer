import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:unshelf_buyer/models/order_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';

class OrderViewModel extends ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderStatus _currentStatus = OrderStatus.all;
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  Map<String, dynamic>? paymentIntentData;

  OrderModel? get selectedOrder => _selectedOrder;
  List<OrderModel> get orders => _orders;
  OrderStatus get currentStatus => _currentStatus;
  bool get isLoading => _isLoading;

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
          .where('seller_id', isEqualTo: FirebaseFirestore.instance.doc('users/${user.uid}'))
          .orderBy('created_at', descending: true)
          .get();

      _orders = await Future.wait<OrderModel>(querySnapshot.docs.map((doc) => OrderModel.fetchOrderWithProducts(doc)).toList());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Failed to fetch orders: $e');
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
      _currentStatus = OrderStatus.pending;
    } else if (status == 'Completed') {
      _currentStatus = OrderStatus.completed;
    } else if (status == 'Ready') {
      _currentStatus = OrderStatus.ready;
    }
    notifyListeners();
  }

  // Function to initiate payment process
  Future<void> makePayment(String amount) async {
    try {
      paymentIntentData = await createPaymentIntent(amount, 'PHP');

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData!['client_secret'],
          merchantDisplayName: 'Unshelf',
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            testEnv: true,
          ),
        ),
      );

      // Display payment sheet
      await displayPaymentSheet();
    } catch (error) {
      paymentIntentData = null;
      print('Error in makePayment: $error');
      rethrow;
    }
  }

  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    String secretKey = dotenv.env['stripeSecretKey'] ?? '';
    try {
      Map<String, dynamic> body = {
        'amount': (double.parse(amount).floor() * 100).toString(), // Amount in cents
        'currency': currency,
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: body,
        headers: {
          'Authorization': 'Bearer ${secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      debugPrint("Payment Intent Response: ${response.body}");
      return json.decode(response.body);
    } catch (error) {
      print('Error in createPaymentIntent: $error');
      rethrow;
    }
  }

  // Display the Stripe payment sheet
  Future<void> displayPaymentSheet() async {
    try {
      debugPrint("inside displayPaymentSheet - start");

      await Stripe.instance.presentPaymentSheet().then((value) {
        debugPrint("inside displayPaymentSheet - present");
      }).catchError((error) {
        debugPrint("Error presenting payment sheet: $error");
      });

      await Stripe.instance.confirmPaymentSheetPayment().then((value) {
        debugPrint("inside displayPaymentSheet - confirm");
      }).catchError((error) {
        debugPrint("Error confirming payment: $error");
      });

      // Update order status to 'paid' once the payment is successful
      await updateOrderStatusToPaid();

      debugPrint("inside displayPaymentSheet - updated");
      paymentIntentData = null;
      notifyListeners();
    } catch (error) {
      debugPrint('Error in displayPaymentSheet: $error');
    }
  }

  // Update the order status to "Paid"
  Future<void> updateOrderStatusToPaid() async {
    if (_selectedOrder != null) {
      try {
        // Update order status in Firestore
        await FirebaseFirestore.instance.collection('orders').doc(_selectedOrder!.id).update({
          'is_paid': true,
        });

        // Update locally as well
        _selectedOrder!.is_paid = true;
        notifyListeners();
      } catch (e) {
        print('Error updating order status: $e');
      }
    }
  }

  // New method to handle the full order process
  Future<bool> processOrderAndPayment(
      String buyerId, List<Map<String, dynamic>> basketItems, String sellerId, double totalAmount, String? pickupTime) async {
    try {
      // Add order to Firestore
      DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'buyer_id': buyerId,
        'created_at': DateTime.now(),
        'order_items': basketItems
            .map((item) => {
                  'product_id': item['productId'],
                  'quantity': item['quantity'],
                })
            .toList(),
        'seller_id': sellerId,
        'status': 'Pending',
        'pickup_time': pickupTime,
      });

      // Process the payment
      await makePayment(totalAmount.toString());

      // If payment is successful, mark order as paid
      await orderRef.update({'is_paid': true, 'status': 'Paid'});

      // Delete items from the basket after successful payment
      for (var item in basketItems) {
        await FirebaseFirestore.instance
            .collection('baskets')
            .doc(buyerId)
            .collection('cart_items')
            .doc(item['productId'])
            .delete();
      }

      return true;
    } catch (e) {
      print('Error during order and payment process: $e');
      return false;
    }
  }
}
