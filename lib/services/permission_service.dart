import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request camera permission. Returns true if granted.
  static Future<bool> requestCamera(BuildContext context) async {
    return _requestPermission(
      context,
      Permission.camera,
      'Camera',
      'Camera access is needed to take photos for your coach.',
    );
  }

  /// Request microphone permission. Returns true if granted.
  static Future<bool> requestMicrophone(BuildContext context) async {
    return _requestPermission(
      context,
      Permission.microphone,
      'Microphone',
      'Microphone access is needed for speech-to-text.',
    );
  }

  /// Request notification permission (Android 13+). Returns true if granted.
  static Future<bool> requestNotification(BuildContext context) async {
    return _requestPermission(
      context,
      Permission.notification,
      'Notifications',
      'Notification access is needed to send you reminders.',
    );
  }

  static Future<bool> _requestPermission(
    BuildContext context,
    Permission permission,
    String name,
    String rationale,
  ) async {
    var status = await permission.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('$name Permission Required'),
            content: Text(
              '$rationale\n\nYou previously denied this permission. '
              'Please enable it in Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    // Ask for permission
    status = await permission.request();
    return status.isGranted;
  }
}
