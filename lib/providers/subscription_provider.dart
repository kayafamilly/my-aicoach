import 'package:flutter/material.dart';
import 'package:my_aicoach/services/purchase_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = true;

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;

  SubscriptionProvider() {
    checkStatus();
  }

  Future<void> checkStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isPremium = await PurchaseService.isPremium();
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      _isPremium = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTestPremium(bool value) {
    _isPremium = value;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    _isLoading = true;
    notifyListeners();
    try {
      await PurchaseService.restorePurchases();
      await checkStatus();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
