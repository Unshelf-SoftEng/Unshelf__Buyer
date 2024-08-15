import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_buyer/models/store_model.dart';

class StoreScheduleViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _timeFormatter = DateFormat('HH:mm');
  late Map<String, Map<String, String>> _storeSchedule;

  StoreScheduleViewModel(StoreModel storeDetails) {
    _storeSchedule = storeDetails.storeSchedule ??
        {
          'Monday': {'open': 'Closed', 'close': 'Closed'},
          'Tuesday': {'open': 'Closed', 'close': 'Closed'},
          'Wednesday': {'open': 'Closed', 'close': 'Closed'},
          'Thursday': {'open': 'Closed', 'close': 'Closed'},
          'Friday': {'open': 'Closed', 'close': 'Closed'},
          'Saturday': {'open': 'Closed', 'close': 'Closed'},
          'Sunday': {'open': 'Closed', 'close': 'Closed'},
        };
  }

  Map<String, Map<String, String>> get storeSchedule => _storeSchedule;

  Future<void> selectTime(String day, String type, TimeOfDay pickedTime) async {
    final timeString = _timeFormatter.format(
      DateTime(2023, 1, 1, pickedTime.hour, pickedTime.minute),
    );
    _storeSchedule[day]![type] = timeString;
    notifyListeners();
  }

  Future<void> saveProfile(BuildContext context, String userId) async {
    try {
      await _firestore.collection('stores').doc(userId).update({
        'store_schedule': _storeSchedule,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    }
  }
}
