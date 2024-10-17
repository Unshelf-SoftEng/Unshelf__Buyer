import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_buyer/viewmodels/order_viewmodel.dart';

class PaymentScreen extends StatelessWidget {
  final String totalAmount;

  PaymentScreen({required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    final orderViewModel = Provider.of<OrderViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            debugPrint("Hello?");
            await orderViewModel.makePayment(totalAmount);
          },
          child: Text('Pay \$${totalAmount}'),
        ),
      ),
    );
  }
}
