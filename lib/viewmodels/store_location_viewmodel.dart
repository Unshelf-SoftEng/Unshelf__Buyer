import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreLocationViewModel extends ChangeNotifier {
  GoogleMapController? _mapController;
  LatLng _chosenLocation = LatLng(10.3157, 123.8854);

  LatLng get chosenLocation => _chosenLocation;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  void updateLocation(LatLng location) {
    _chosenLocation = location;
    notifyListeners();
  }

  Future<void> saveLocation() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    try {
      await FirebaseFirestore.instance.collection('stores').doc(user.uid).set({
        'latitude': _chosenLocation.latitude,
        'longitude': _chosenLocation.longitude,
      }, SetOptions(merge: true));
    } catch (error) {
      throw Exception('Failed to save location: $error');
    }

    notifyListeners();
  }
}
