// view_models/settings_view_model.dart
import 'package:flutter/material.dart';
import '../models/settings_model.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsModel _settings = SettingsModel(
    notificationsEnabled: true,
    language: 'English',
  );

  SettingsModel get settings => _settings;

  void toggleNotifications(bool value) {
    _settings = SettingsModel(
      notificationsEnabled: value,
      language: _settings.language,
    );
    notifyListeners();
  }

  void changeLanguage(String newLanguage) {
    _settings = SettingsModel(
      notificationsEnabled: _settings.notificationsEnabled,
      language: newLanguage,
    );
    notifyListeners();
  }
}
