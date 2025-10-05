import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:state/service_locator.dart';
import 'package:state/core/services/notification_service.dart';
import 'package:state/core/services/fcm_token_service.dart';
import 'firebase_options.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initInjections();

  // Initialize Notification Service
  final notificationService = sl<NotificationService>();
  await notificationService.initialize();

  // Initialize FCM Token Service
  final fcmTokenService = sl<FCMTokenService>();
  await fcmTokenService.initialize();

  runApp(const App());
}
