import 'package:flutter/foundation.dart';
import 'package:unshelf_buyer/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfileModel _userProfile = UserProfileModel();

  UserProfileModel get userProfile => _userProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void loadUserProfile() async {
    _isLoading = true;
    notifyListeners();
    User user = FirebaseAuth.instance.currentUser!;

    try {
      var userProfileData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      _userProfile = UserProfileModel(
        name: userProfileData['name'],
        email: userProfileData['email'],
        phoneNumber: userProfileData['phoneNumber'],
      );
    } catch (error) {
      _errorMessage = 'Failed to load user profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateUserProfile(UserProfileModel newProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      User user = FirebaseAuth.instance.currentUser!;

      await FirebaseAuth.instance.currentUser!
          .updatePassword(newProfile.password!);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': newProfile.name,
        'email': newProfile.email,
        'phoneNumber': newProfile.phoneNumber,
      });

      _userProfile = newProfile;
    } catch (error) {
      _errorMessage = 'Failed to update user profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
