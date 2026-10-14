import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized permissions service for Quickopia.
/// Handles runtime permission requests for location tracking and microphone voice input.
class PermissionService {
  /// Requests device location permission for high-accuracy courier and delivery tracking.
  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.status;
      if (status.isGranted) return true;
      final result = await Permission.location.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('Location permission request error: $e');
      return false;
    }
  }

  /// Requests microphone permission for AI voice shopping assistant.
  static Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return true;
      final result = await Permission.microphone.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('Microphone permission request error: $e');
      return false;
    }
  }

  /// Checks if microphone permission is currently granted.
  static Future<bool> isMicrophoneGranted() async {
    try {
      return await Permission.microphone.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Checks if location permission is currently granted.
  static Future<bool> isLocationGranted() async {
    try {
      return await Permission.location.isGranted;
    } catch (e) {
      return false;
    }
  }
}
