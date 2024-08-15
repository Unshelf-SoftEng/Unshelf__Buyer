import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_buyer/category_row_widget.dart';

class CategoryProductsPage extends StatelessWidget {
  final CategoryItem category;

  CategoryProductsPage({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${category.name} Products'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').where('category', isEqualTo: category.categoryKey).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var productData = products[index].data() as Map<String, dynamic>;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('stores').doc(productData['sellerId']).get(),
                builder: (context, storeSnapshot) {
                  if (!storeSnapshot.hasData) {
                    return ListTile(title: Text('Loading...'));
                  }

                  var storeData = storeSnapshot.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(storeData['store_image_url']),
                    ),
                    title: Text(productData['name']),
                    subtitle: Text('P ${productData['price']}'),
                    trailing: Text(DateFormat('MMMM d, yyyy').format((productData['expiryDate'] as Timestamp).toDate())),
                    onTap: () {
                      // Implement navigation to product details or other relevant actions
                    },
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
