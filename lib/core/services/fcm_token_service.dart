import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service to manage FCM token updates and synchronization with Firestore
class FCMTokenService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize FCM token management
  Future<void> initialize() async {
    // Listen for auth state changes to update FCM token
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _updateFCMTokenForUser(user.uid);
      }
    });

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((String token) {
      final user = _auth.currentUser;
      if (user != null) {
        _saveFCMTokenToFirestore(user.uid, token);
      }
    });

    // Get initial token if user is already authenticated
    final user = _auth.currentUser;
    if (user != null) {
      await _updateFCMTokenForUser(user.uid);
    }
  }

  /// Update FCM token for the current user
  Future<void> _updateFCMTokenForUser(String userId) async {
    try {
      print('FCMTokenService: Getting FCM token for user: $userId');
      final token = await _messaging.getToken();
      print(
        'FCMTokenService: FCM token received: ${token?.substring(0, 20)}...',
      );
      if (token != null) {
        await _saveFCMTokenToFirestore(userId, token);
      } else {
        print('FCMTokenService: FCM token is null');
      }
    } catch (e) {
      print('FCMTokenService: Error updating FCM token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMTokenToFirestore(String userId, String token) async {
    try {
      print('FCMTokenService: Saving FCM token to Firestore for user: $userId');
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print(
        'FCMTokenService: FCM token saved successfully to Firestore for user: $userId',
      );
    } catch (e) {
      print('FCMTokenService: Error saving FCM token to Firestore: $e');
      // Try to create the document if it doesn't exist
      try {
        print('FCMTokenService: Attempting to create user document...');
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('FCMTokenService: User document created with FCM token');
      } catch (createError) {
        print('FCMTokenService: Error creating user document: $createError');
      }
    }
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('FCMTokenService: Error getting FCM token: $e');
      return null;
    }
  }

  /// Manually trigger FCM token generation and save to current user
  Future<void> refreshAndSaveFCMToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      print(
        'FCMTokenService: Manually refreshing FCM token for user: ${user.uid}',
      );
      await _updateFCMTokenForUser(user.uid);
    } else {
      print('FCMTokenService: No authenticated user found');
    }
  }

  /// Delete FCM token from Firestore (for logout)
  Future<void> deleteFCMToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('FCM token deleted from Firestore for user: $userId');
    } catch (e) {
      print('Error deleting FCM token from Firestore: $e');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }
}
