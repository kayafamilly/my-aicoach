import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_aicoach/services/purchase_service.dart';

enum SubscriptionTier { free, trial, premium }

class SubscriptionProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = true;
  SubscriptionTier _tier = SubscriptionTier.free;
  DateTime? _trialStartDate;
  int _trialCoachCount = 0;

  static const String _trialStartKey = 'trial_start_date';
  static const String _trialCoachCountKey = 'trial_coach_count';
  static const int trialDurationDays = 7;

  bool get isPremium => _isPremium || _tier == SubscriptionTier.premium;
  bool get isLoading => _isLoading;
  SubscriptionTier get tier => _tier;
  int get trialCoachCount => _trialCoachCount;

  /// Whether the user can create a coach right now
  bool get canCreateCoach {
    if (_tier == SubscriptionTier.premium) return true;
    if (_tier == SubscriptionTier.trial) {
      if (_trialCoachCount >= 1) return false; // already used trial creation
      if (_trialStartDate != null) {
        final elapsed = DateTime.now().difference(_trialStartDate!).inDays;
        if (elapsed > trialDurationDays) return false; // trial expired
      }
      return true;
    }
    return false; // free tier
  }

  /// Whether the user can access the Market (premium only, not trial)
  bool get canAccessMarket => _tier == SubscriptionTier.premium;

  /// Days remaining in trial, or 0
  int get trialDaysRemaining {
    if (_trialStartDate == null) return trialDurationDays;
    final elapsed = DateTime.now().difference(_trialStartDate!).inDays;
    return (trialDurationDays - elapsed).clamp(0, trialDurationDays);
  }

  SubscriptionProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadTrialData();
    await checkStatus();
  }

  Future<void> _loadTrialData() async {
    final prefs = await SharedPreferences.getInstance();
    final startMs = prefs.getInt(_trialStartKey);
    if (startMs != null) {
      _trialStartDate = DateTime.fromMillisecondsSinceEpoch(startMs);
    }
    _trialCoachCount = prefs.getInt(_trialCoachCountKey) ?? 0;
  }

  Future<void> checkStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isPremium = await PurchaseService.isPremium();
      _updateTier();
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      _isPremium = false;
      _updateTier();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateTier() {
    if (_isPremium) {
      _tier = SubscriptionTier.premium;
    } else if (_trialStartDate != null) {
      final elapsed = DateTime.now().difference(_trialStartDate!).inDays;
      _tier = elapsed <= trialDurationDays
          ? SubscriptionTier.trial
          : SubscriptionTier.free;
    } else {
      _tier = SubscriptionTier.free;
    }
  }

  /// Start the 7-day free trial
  Future<void> startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    _trialStartDate = DateTime.now();
    await prefs.setInt(_trialStartKey, _trialStartDate!.millisecondsSinceEpoch);
    _trialCoachCount = 0;
    await prefs.setInt(_trialCoachCountKey, 0);
    _updateTier();
    notifyListeners();
  }

  /// Increment the trial coach creation count
  Future<void> incrementTrialCoachCount() async {
    _trialCoachCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_trialCoachCountKey, _trialCoachCount);
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
