import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/service_locator.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final INavigationService _navigationService = sl<INavigationService>();

  /// Initialize Firebase Messaging (fully non-blocking)
  static Future<void> initialize() async {
    // Initialize everything in background
    _initializeInBackground();
  }

  static void _initializeInBackground() async {
    try {
      // Request permission for iOS
      if (Platform.isIOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint('User declined or has not accepted permission');
          return;
        }

        // Wait for APNS token to be available on iOS
        try {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('APNS token not available yet, waiting...');
            // Wait a bit and try again
            await Future.delayed(const Duration(seconds: 2));
          }
        } catch (e) {
          debugPrint('APNS token error: $e');
        }
      }

      // Get FCM token in background
      _getTokenInBackground();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app is terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('Firebase messaging initialization error: $e');
    }
  }

  /// Get FCM token for the current user
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    // Show local notification or update UI
    // For now, we'll just log the message
    debugPrint('Message data: ${message.data}');
    debugPrint('Message notification: ${message.notification?.title}');
  }

  /// Handle notification tap
  static void _getTokenInBackground() async {
    try {
      String? token;
      if (Platform.isIOS) {
        // Wait a bit for APNS token to be ready
        await Future.delayed(const Duration(seconds: 2));
        try {
          final apnsToken = await _messaging.getAPNSToken();
          if (apnsToken != null) {
            token = await _messaging.getToken();
          }
        } catch (e) {
          debugPrint('APNS token error in background: $e');
        }
      } else {
        token = await _messaging.getToken();
      }

      if (token != null) {
        debugPrint('FCM Token: $token');
      } else {
        debugPrint('Failed to get FCM token in background');
      }
    } catch (e) {
      debugPrint('Background token retrieval error: $e');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');

    final data = message.data;
    final postId = data['postId'];
    final commentId = data['commentId'];

    if (postId != null) {
      // Navigate to post details using deep linking
      String deepLink = '/post-details/$postId';

      // If commentId is provided, add it as a query parameter
      if (commentId != null && commentId.isNotEmpty) {
        deepLink += '?commentId=$commentId';
      }

      _navigationService.handleDeepLink(deepLink);
      debugPrint(
        'Navigate to post: $postId${commentId != null ? ' with comment: $commentId' : ''}',
      );
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background message here
}
