import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:state/service_locator.dart';
import 'package:state/firebase_options.dart';
import 'package:state/app/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When using Flutter version 3.3.0 or higher, the background message handler must be annotated with @pragma('vm:entry-point')
/// right above the function declaration (otherwise it may be removed during tree shaking for release mode).
/// Related documentation could be found here:
/// - https://firebase.google.com/docs/cloud-messaging/flutter/receive#apple_platforms_and_android
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Don't show local notification in background handler as FCM already shows system notification
  // await NotificationService().showLocalNotification(message);
}

/// A service that manages both push notifications and local notifications for the app.
/// It leverages Firebase Cloud Messaging for handling remote notifications and Flutter
/// Local Notifications for displaying notifications when the app is in the foreground.
class NotificationService {
  static NotificationService? _instance;
  final FirebaseMessaging _messaging;

  // Add this constructor for testing
  @visibleForTesting
  NotificationService.withMessaging(this._messaging);

  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  NotificationService._internal() : _messaging = FirebaseMessaging.instance;

  static const notificationsEnabledKey = 'notifications_enabled';
  static const initialNotificationSetupKey = 'initial_notification_setup';

  // The base hidden stream broadcast that's ready to access from the deeplink notification stream.
  final _deeplinkNotificationStream =
      StreamController<Map<String, dynamic>>.broadcast();

  /// A stream that emits notification data whenever a notification is tapped by the user.
  /// The stream can be used to implement deep linking and navigation based on notification
  /// interactions. Each emission contains a Map with the notification payload
  /// and routing information.
  Stream<Map<String, dynamic>> get deeplinkNotificationStream =>
      _deeplinkNotificationStream.stream;

  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// The default notification channel configuration for Android devices. The app currently
  /// uses a single main channel for all notifications. In the future, additional channels
  /// may be added for different notification categories to provide users with more granular
  /// control over notification settings.
  static final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'state_notifications_channel',
    'State Notifications',
    channelDescription: 'Main channel for State app notifications',
    importance: Importance.max,
    priority: Priority.high,
    color: Color(0xFF74182f), // Brand color
    icon: '@mipmap/ic_launcher', // App icon for notification
  );

  /// The default notification channel configuration for iOS/macOS devices. This specifies
  /// how notifications should be presented when the app is in the foreground, enabling
  /// alerts, badges, and sounds. These settings ensure notifications are visible and
  /// audible to users on Apple platforms while maintaining platform-specific behavior
  /// and appearance standards.
  static const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  Future<PermissionStatus> requestPermission() =>
      Permission.notification.request();

  /// Check if notifications are enabled and request permission if needed
  Future<bool> ensureNotificationPermission() async {
    final status = await permissionStatus();

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isPermanentlyDenied) {
      // Try to request permission
      final newStatus = await requestPermission();
      return newStatus.isGranted;
    }

    return false;
  }

  /// Retrieves the current notification permission status from the device.
  Future<PermissionStatus> permissionStatus() async =>
      Permission.notification.status;

  /// Requests Firebase Cloud Messaging permissions for iOS
  /// On Android 13+, uses permission_handler to request notification permission
  ///
  /// This should be called when appropriate for your UX flow (e.g., during onboarding
  /// or when user toggles notifications on in settings).
  ///
  /// Returns the authorization status after the request.
  Future<AuthorizationStatus> requestFirebasePermissions() async {
    try {
      if (Platform.isIOS) {
        // Request iOS permissions through Firebase Messaging
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          log('User declined or has not accepted permission');
        } else {
          log('iOS notification permission granted');
        }

        return settings.authorizationStatus;
      } else if (Platform.isAndroid) {
        // Request notification permission for Android 13+ (API 33+)
        // For older Android versions, notification permission is granted by default
        try {
          final status = await Permission.notification.request();
          if (status.isDenied) {
            log('Android notification permission denied');
            return AuthorizationStatus.denied;
          } else {
            log('Android notification permission granted');
            return AuthorizationStatus.authorized;
          }
        } catch (e) {
          log('Android notification permission request failed: $e');
          // Continue anyway - might work on older Android versions
          return AuthorizationStatus.authorized;
        }
      }
    } catch (e) {
      log('Notification permission request error: $e');
    }

    return AuthorizationStatus.notDetermined;
  }

  /// Sets up the notification service by initializing both Firebase Cloud Messaging
  /// and local notifications handlers. This should be called when the app starts,
  /// typically during the bootstrap process.
  ///
  /// Note: This does NOT request permissions. Permissions should be requested
  /// separately when appropriate for your UX flow (e.g., when user opts in).
  Future<void> initialize() async {
    await _initializeFirebaseMessaging();
    await _initializeLocalNotifications();
  }

  /// Configures Firebase Cloud Messaging by setting up message handlers for various
  /// app states (foreground, background, terminated) and checking for any pending
  /// initial messages that may have launched the app.
  Future<void> _initializeFirebaseMessaging() async {
    // Get the FCM token (works even if permissions not granted yet)
    try {
      final token = await FirebaseMessaging.instance.getToken();
      log('FCM Token: $token');
    } catch (e) {
      log('Error getting FCM token: $e');
      // This is fine - token might not be available yet if permissions not granted
      // It will be available after permissions are granted or via onTokenRefresh
    }

    // Set up token refresh listener (best practice - catches token when ready)
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        log('FCM Token refreshed: $newToken');
        // You can send this to your backend or store it locally
      },
      onError: (error) {
        log('Error on token refresh: $error');
      },
    );

    // Set up message listeners
    _setupMessageListeners();
  }

  /// Sets up Firebase Messaging listeners for various app states
  void _setupMessageListeners() {
    // Request iOS permissions
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _messaging.getInitialMessage().then((initialMessage) {
      if (initialMessage != null) {
        log('Initial message received: ${initialMessage.data}');
        // Delay handling initial message to ensure app is fully initialized
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleNotificationData(remote: initialMessage);
        });
      }
    });
  }

  /// Configures the local notifications plugin with platform-specific settings.
  /// Currently focuses on Android settings configuration, with iOS configuration
  /// to be expanded in the future.
  Future<void> _initializeLocalNotifications() async {
    const androidInitializationSettings = AndroidInitializationSettings(
      '@mipmap/ic_stat_name', // Use notification icon
    );
    const iosInitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        log('Local notification tapped, payload: ${response.payload}');
        final notificationData = jsonDecode(response.payload ?? '{}');
        _handleNotificationData(local: notificationData);
      },
    );
  }

  /// Processes incoming messages when the app is in the foreground by displaying
  /// a local notification on Android devices only. iOS handles foreground notifications
  /// through the system notification center based on presentation options set during
  /// initialization.
  ///
  /// This method ensures Android users are aware of new notifications even while
  /// actively using the app, while respecting iOS platform conventions for
  /// notification handling.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (Platform.isAndroid) return await showLocalNotification(message);
  }

  /// Processes notification taps when the app is in the background by handling
  /// the notification data and adding it to the deeplink stream for navigation.
  void _handleMessageOpenedApp(RemoteMessage message) {
    log('Message opened app: ${message.data}');
    _handleNotificationData(remote: message);
  }

  /// Processes raw notification data by converting it into a structured Map
  /// and adding it to the stream for handling deep linking functionality.
  void _handleNotificationData({
    RemoteMessage? remote,
    Map<String, dynamic>? local,
  }) {
    final data = remote?.data ?? local ?? {};

    log('=== NOTIFICATION DATA ===');
    log('Remote message ID: ${remote?.messageId}');
    log('Notification title: ${remote?.notification?.title}');
    log('Notification body: ${remote?.notification?.body}');
    log('Data payload: $data');
    log('========================');

    // Add to stream for deep linking
    _deeplinkNotificationStream.add(data);

    // Handle navigation immediately
    _handleNotificationNavigation(data);
  }

  /// Handles navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final postId = data['postId'];
    final commentId = data['commentId'];
    final notificationType = data['type']; // 'comment' or 'upvote'

    log('=== NAVIGATION HANDLING ===');
    log('Post ID: $postId');
    log('Comment ID: $commentId');
    log('Notification type: $notificationType');
    log('===========================');

    if (postId != null && postId.isNotEmpty) {
      // Delay navigation to ensure app is fully initialized
      Future.delayed(const Duration(milliseconds: 1500), () {
        try {
          log('Attempting navigation to post: $postId');

          // Navigate directly to post details using push to maintain any existing stack
          String path = '/post-details/$postId';
          if (notificationType == 'comment' &&
              commentId != null &&
              commentId.isNotEmpty) {
            path += '?commentId=$commentId';
          }
          log('Pushing to path: $path');

          // Use push to maintain existing navigation stack
          AppRouter.router.push(path);

          log(
            'Successfully navigated to post: $postId${commentId != null && commentId.isNotEmpty ? ' with comment: $commentId' : ''}',
          );
        } catch (e) {
          log('ERROR handling notification navigation: $e');
        }
      });
    } else {
      log('ERROR: Post ID is null or empty, cannot navigate');
    }
  }

  /// Displays a local notification using the Flutter Local Notifications plugin.
  /// This is primarily used for Android devices when the app is in the foreground,
  /// as iOS handles foreground notifications through the system notification center.
  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  /// Returns true if setup was previously completed, false otherwise.
  Future<bool> hasPassedInitialSetup() async {
    final prefs = await sl<SharedPreferences>();
    return prefs.getBool(initialNotificationSetupKey) ?? false;
  }

  /// Checks if notifications are enabled by retrieving the stored flag from local storage.
  Future<bool> hasNotificationEnabled() async {
    final prefs = await sl<SharedPreferences>();
    return prefs.getBool(notificationsEnabledKey) ?? false;
  }

  /// Toggles the notifications permission and returns the new value.
  Future<bool> toggleNotificationsPermissions(bool value) async {
    final prefs = await sl<SharedPreferences>();
    await prefs.setBool(notificationsEnabledKey, value);
    return value;
  }

  /// Returns an updated firebase cloud-messaging token.
  Future<String?> updateFcm() async {
    await deleteFcm();
    final token = await FirebaseMessaging.instance.getToken();
    return token;
  }

  /// Deletes current firebase cloud-messaging token.
  Future<void> deleteFcm() async => FirebaseMessaging.instance.deleteToken();

  /// Subscribes to a topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribes from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Disposes the service and closes streams
  void dispose() {
    _deeplinkNotificationStream.close();
  }
}
