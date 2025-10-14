import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/auth/domain/auth_repository.dart';
import 'package:state/core/services/fcm_token_service.dart';
import 'package:state/core/services/notification_service.dart';
import 'package:state/service_locator.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  final FirebaseAuth _firebaseAuth;

  AuthCubit(this.authRepository, this._firebaseAuth) : super(AuthInitial());

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      await authRepository.signInWithGoogle();
      await authRepository.createUserEntry();

      emit(
        Authenticated(
          userId: _firebaseAuth.currentUser?.uid ?? '',
          userName: _firebaseAuth.currentUser?.displayName ?? '',
        ),
      );

      // Request permissions and update FCM token in background (non-blocking)
      _requestPermissionsAndUpdateToken();
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> signInWithApple() async {
    emit(AuthLoading());
    try {
      await authRepository.signInWithApple();
      await authRepository.createUserEntry();

      emit(
        Authenticated(
          userId: _firebaseAuth.currentUser?.uid ?? '',
          userName: _firebaseAuth.currentUser?.displayName ?? '',
        ),
      );

      _requestPermissionsAndUpdateToken();
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> signOut() async {
    // Delete FCM token from current user's Firestore document before signing out
    final userId = _firebaseAuth.currentUser?.uid;
    if (userId != null) {
      final fcmTokenService = sl<FCMTokenService>();
      await fcmTokenService.deleteFCMToken(userId);
      print('AuthCubit: FCM token deleted for user: $userId');
    }

    await authRepository.signOut();
    emit(Unauthenticated());
  }

  Future<void> checkAuthStatus() async {
    final isSignedIn = await authRepository.isSignedIn();
    if (isSignedIn) {
      emit(
        Authenticated(
          userId: _firebaseAuth.currentUser?.uid ?? '',
          userName: _firebaseAuth.currentUser?.displayName ?? '',
        ),
      );

      // Request permissions if needed and update FCM token (non-blocking)
      _requestPermissionsAndUpdateToken();
    } else {
      emit(Unauthenticated());
    }
  }

  /// Requests notification permissions and updates FCM token in background
  /// This is non-blocking and won't freeze the UI
  ///
  /// On iOS, we rely on the onTokenRefresh listener to save the token once
  /// permissions are granted and APNS token becomes available.
  Future<void> _requestPermissionsAndUpdateToken() async {
    try {
      final fcmTokenService = sl<FCMTokenService>();
      final notificationService = sl<NotificationService>();

      // Request permissions on both platforms
      final authStatus = await notificationService.requestFirebasePermissions();

      if (Platform.isIOS) {
        print('AuthCubit: iOS notification permission status: $authStatus');

        if (authStatus != AuthorizationStatus.authorized) {
          print('AuthCubit: Permission not granted, skipping FCM token update');
          return;
        }

        // Try to update token once - if APNS token isn't ready yet,
        // the onTokenRefresh listener will handle it when it becomes available
        await fcmTokenService.refreshAndSaveFCMToken();
        print(
          'AuthCubit: FCM token update initiated (will save via onTokenRefresh if needed)',
        );
      } else {
        // Android - permissions dialog is shown, then token is updated
        print('AuthCubit: Android notification permission status: $authStatus');
        await fcmTokenService.refreshAndSaveFCMToken();
        print('AuthCubit: Android FCM token updated');
      }
    } catch (e) {
      print('AuthCubit: Error requesting permissions or updating token: $e');
    }
  }
}
