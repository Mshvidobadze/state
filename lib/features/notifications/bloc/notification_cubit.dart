import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/notifications/domain/notification_repository.dart';
import 'package:state/features/notifications/bloc/notification_state.dart';
import 'package:state/features/notifications/data/models/notification_model.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;
  final FirebaseAuth firebaseAuth;
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;

  NotificationCubit(this.notificationRepository, this.firebaseAuth)
    : super(NotificationInitial());

  String? get currentUserId => firebaseAuth.currentUser?.uid;

  Future<void> loadNotifications() async {
    final userId = currentUserId;
    if (userId == null) {
      emit(const NotificationError('User not authenticated'));
      return;
    }

    emit(NotificationLoading());

    try {
      // Start listening to real-time updates
      _notificationSubscription?.cancel();
      _notificationSubscription = notificationRepository
          .listenToNotifications(userId)
          .listen(
            (notifications) => _updateNotifications(notifications),
            onError: (error) => emit(NotificationError(error.toString())),
          );

      // Get initial data
      final notifications = await notificationRepository.fetchNotifications(
        userId,
      );
      final unreadCount = await notificationRepository.getUnreadCount(userId);

      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  void _updateNotifications(List<NotificationModel> notifications) {
    final currentState = state;
    if (currentState is NotificationLoaded) {
      final unreadCount = notifications.where((n) => !n.isRead).length;
      emit(
        currentState.copyWith(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await notificationRepository.markAsRead(notificationId);
    } catch (e) {
      emit(NotificationError('Failed to mark notification as read: $e'));
    }
  }

  Future<void> markAllAsRead() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await notificationRepository.markAllAsRead(userId);
    } catch (e) {
      emit(NotificationError('Failed to mark all notifications as read: $e'));
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await notificationRepository.deleteNotification(notificationId);
    } catch (e) {
      emit(NotificationError('Failed to delete notification: $e'));
    }
  }

  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
