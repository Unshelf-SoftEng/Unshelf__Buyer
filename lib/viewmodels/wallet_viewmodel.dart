import 'package:flutter/foundation.dart';
import 'package:unshelf_buyer/services/paymongo_service.dart';

class WalletViewModel extends ChangeNotifier {
  final PayMongoService _payMongoService = PayMongoService();
  double _balance = 0.0;
  bool _isLoading = true;
  String? _errorMessage;

  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WalletViewModel() {
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      _isLoading = true;
      notifyListeners();
      _balance = await _payMongoService.getWalletBalance();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load balance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
