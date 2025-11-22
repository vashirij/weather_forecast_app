import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:weather_forecast_app/controllers/setting_controller.dart';

/// Lightweight wrapper around Firebase Messaging client-side features.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService();

  /// Initialize permissions and return the FCM token (or null).
  Future<String?> initAndGetToken(SettingsController settings) async {
    // Request permission on iOS/macOS
    try {
      final settingsPerm = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (kDebugMode) {
        print('FCM permission status: ${settingsPerm.authorizationStatus}');
      }
    } catch (e) {
      if (kDebugMode) print('FCM permission request failed: $e');
    }

    try {
      final token = await _messaging.getToken();
      if (kDebugMode) print('FCM token: $token');
      if (token != null) {
        try {
          await settings.setFcmToken(token);
        } catch (_) {
          if (kDebugMode) print('Failed to set token on settings controller');
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) print('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic for broadcast alerts.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) print('Subscribed to topic $topic');
    } catch (e) {
      if (kDebugMode) print('Topic subscribe failed: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (_) {}
  }

  /// Request server to send a notification to a topic or token.
  /// The server endpoint should validate and use the Admin SDK to send via FCM.
  /// This function performs a simple POST with JSON payload to the configured endpoint.
  Future<bool> requestSendNotification({
    required Uri endpoint,
    String? topic,
    String? token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'body': body,
      if (topic != null) 'topic': topic,
      if (token != null) 'token': token,
      if (data != null) 'data': data,
    };

    try {
      final res = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      if (kDebugMode)
        print('Notification request status: ${res.statusCode} ${res.body}');
      return res.statusCode == 200 || res.statusCode == 202;
    } catch (e) {
      if (kDebugMode) print('Notification request failed: $e');
      return false;
    }
  }
}
