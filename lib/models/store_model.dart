import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String userId;
  final String email;
  final String name;
  final String phoneNumber;
  final String storeName;
  final double? storeLongitude;
  final double? storeLatitude;
  final Map<String, Map<String, String>>? storeSchedule;
  final String? storeImageUrl;
  double? storeRating;
  int? storeFollowers;

  StoreModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.storeName,
    this.storeSchedule,
    this.storeLongitude,
    this.storeLatitude,
    this.storeImageUrl,
    this.storeRating,
    this.storeFollowers,
  });

  // Factory method to create StoreModel from Firebase document snapshot
  factory StoreModel.fromSnapshot(DocumentSnapshot userDoc, DocumentSnapshot storeDoc) {
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    Map<String, dynamic> storeData = storeDoc.data() as Map<String, dynamic>;

    return StoreModel(
      userId: userDoc.id,
      email: userData['email'] ?? '',
      name: userData['name'] ?? '',
      phoneNumber: userData['phone_number'] ?? '',
      storeName: storeData['store_name'] ?? '',
      storeSchedule: (storeData['store_schedule'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as String),
          ),
        ),
      ),
      storeLongitude: (storeData['longitude'] as num?)?.toDouble(),
      storeLatitude: (storeData['latitude'] as num?)?.toDouble(),
      storeImageUrl: storeData['store_image_url'],
      storeRating: 4.5, // Handle this dynamically!
      storeFollowers: 1200, // Handle this dynamically!
    );
  }
}
