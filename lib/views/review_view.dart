import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReviewPage extends StatelessWidget {
  final String orderId;
  final String storeId;
  final String orderDocId;

  const ReviewPage({Key? key, required this.orderId, required this.storeId, required this.orderDocId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _descriptionController = TextEditingController();
    final _rating = ValueNotifier<int>(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Rate the Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () => _rating.value = index + 1,
                  icon: ValueListenableBuilder<int>(
                    valueListenable: _rating,
                    builder: (context, value, _) => Icon(
                      Icons.star,
                      color: value > index ? Colors.amber : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Write a short review',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final reviewData = {
                  'orderId': orderId,
                  'buyerId': FirebaseAuth.instance.currentUser!.uid,
                  'storeId': storeId,
                  'rating': _rating.value,
                  'description': _descriptionController.text,
                };

                await FirebaseFirestore.instance.collection('orders').doc(orderDocId).update({'isReviewed': true});
                await FirebaseFirestore.instance.collection('stores').doc(storeId).collection('reviews').add(reviewData);

                Navigator.pop(context);
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
