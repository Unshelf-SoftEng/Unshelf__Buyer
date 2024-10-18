import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/product_view.dart';
import 'package:unshelf_buyer/views/store_view.dart';

class FollowingView extends StatelessWidget {
  const FollowingView({super.key});

  Future<void> _removeFromFollowing(String storeId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final followingRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('following').doc(storeId);

    await followingRef.delete();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final followingRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('following');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E9E57),
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          "Following",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: Container(
              color: const Color.fromARGB(255, 200, 221, 150),
              height: 6.0,
            )),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: followingRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("You aren't following any stores."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final followingDoc = snapshot.data!.docs[index];
              final storeId = followingDoc.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('stores').doc(storeId).get(),
                builder: (context, storeSnapshot) {
                  if (storeSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!storeSnapshot.hasData || !storeSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final storeData = storeSnapshot.data!;
                  final storeName = storeData['store_name'] as String;
                  final storeImageUrl = storeData['store_image_url'] as String;
                  // final productData = productSnapshot.data!;
                  // final name = productData['name'] as String;
                  // final price = productData['price'] as int;
                  // final quantifier = productData['quantifier'] as String;
                  // final mainImageUrl = productData['mainImageUrl'] as String;

                  return ListTile(
                    leading: Image.network(storeImageUrl),
                    title: Text(storeName),
                    // subtitle: Text('₱$price/$quantifier'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoreView(storeId: storeId),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.green),
                      onPressed: () {
                        _removeFromFollowing(storeId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Successfully removed from following list.'),
                        ));
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
