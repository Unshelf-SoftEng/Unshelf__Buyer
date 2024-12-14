import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unshelf_buyer/views/product_view.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({Key? key}) : super(key: key);

  Future<void> _removeFromFavorites(String productId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favoriteRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').doc(productId);

    await favoriteRef.delete();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final favoritesRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E9E57),
        elevation: 0,
        toolbarHeight: 60,
        title: const Text(
          "My Favorites",
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
        stream: favoritesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No favorites yet.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final favoriteDoc = snapshot.data!.docs[index];
              final productId = favoriteDoc.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                builder: (context, productSnapshot) {
                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final productData = productSnapshot.data!;
                  final name = productData['name'] as String;
                  // final price = productData['price'] as int;
                  final quantifier = productData['quantifier'] as String;
                  final mainImageUrl = productData['mainImageUrl'] as String;

                  return ListTile(
                    leading: Image.network(mainImageUrl),
                    title: Text(name),
                    // subtitle: Text('₱$price/$quantifier'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductPage(productId: productId),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.green),
                      onPressed: () {
                        _removeFromFavorites(productId);
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
