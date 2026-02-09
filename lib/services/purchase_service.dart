import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class PurchaseService {
  static const String _entitlementId = 'premium';
  static bool _isConfigured = false;

  static bool get _isMobilePlatform {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static Future<void> init() async {
    if (!_isMobilePlatform) {
      debugPrint('RevenueCat: Skipping init on non-mobile platform');
      return;
    }

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final apiKey = dotenv.env['REVENUECAT_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        PurchasesConfiguration config = PurchasesConfiguration(apiKey);
        await Purchases.configure(config);
        _isConfigured = true;
      } else {
        debugPrint('Warning: RevenueCat API Key not found');
      }
    } catch (e) {
      debugPrint('RevenueCat init error: $e');
    }
  }

  static Future<bool> isPremium() async {
    if (!_isConfigured) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  /// Returns `true` if the purchase completed, `false` if the user cancelled.
  static Future<bool> purchasePackage(Package package) async {
    if (!_isConfigured) throw Exception('Purchase service is not available');
    try {
      final params = PurchaseParams.package(package);
      await Purchases.purchase(params);
      return true;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false; // User cancelled — not an error
      }
      debugPrint('Purchase error: $e');
      rethrow;
    }
  }

  static Future<void> restorePurchases() async {
    if (!_isConfigured) return;
    try {
      await Purchases.restorePurchases();
    } on PlatformException catch (e) {
      debugPrint('Restore error: $e');
      rethrow;
    }
  }

  static Future<Offerings?> getOfferings() async {
    if (!_isConfigured) return null;
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      debugPrint('Error fetching offerings: $e');
      return null;
    }
  }
}
