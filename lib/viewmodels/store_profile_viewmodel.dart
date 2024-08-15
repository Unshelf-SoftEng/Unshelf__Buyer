import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:unshelf_buyer/models/store_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditStoreProfileViewModel extends ChangeNotifier {
  final String storeId; // The ID of the store to update
  late TextEditingController _nameController;
  Uint8List? _profileImage;
  final ImagePicker picker = ImagePicker();

  EditStoreProfileViewModel(StoreModel storeDetails)
      : storeId = storeDetails.userId {
    _nameController = TextEditingController(text: storeDetails.storeName);
  }

  TextEditingController get nameController => _nameController;
  Uint8List? get profileImage => _profileImage;

  get isLoading => _loading;
  bool _loading = false;

  Future<void> pickImage() async {
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List imageData = await image.readAsBytes();
      _profileImage = imageData;
      notifyListeners();
    }
  }

  Future<void> updateStoreProfile() async {
    _loading = true;
    if (_nameController.text.isNotEmpty) {
      try {
        // Update store details in Firestore
        final storeRef =
            FirebaseFirestore.instance.collection('stores').doc(storeId);
        final updateData = {
          'store_name': _nameController.text,
          // Handle image upload if a new image is selected
        };

        if (_profileImage != null) {
          // Assuming you have a method to upload the image and get the URL
          final imageUrl = await uploadImage(_profileImage!);
          updateData['store_image_url'] = imageUrl;
        }

        await storeRef.update(updateData);
        _loading = false;
        notifyListeners(); // Notify listeners if necessary
      } catch (e) {
        // Handle errors
        print('Error updating store profile: $e');
      }
    }
  }

  Future<String> uploadImage(Uint8List? image) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final mainImageRef =
        FirebaseStorage.instance.ref().child('user_avatars/$userId.jpg');
    await mainImageRef.putData(image!);
    final mainImageUrl = await mainImageRef.getDownloadURL();
    return mainImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
