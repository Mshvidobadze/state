import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/notifications/domain/notification_repository.dart';
import 'package:state/features/notifications/bloc/notification_state.dart';
import 'package:state/features/notifications/data/models/notification_model.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;
  final FirebaseAuth firebaseAuth;

  NotificationCubit(this.notificationRepository, this.firebaseAuth)
    : super(NotificationInitial());

  String? get currentUserId => firebaseAuth.currentUser?.uid;

  static const int _notificationsPerPage = 15;
  DocumentSnapshot? _lastDocument;

  Future<void> loadNotifications() async {
    final userId = currentUserId;
    if (userId == null) {
      emit(const NotificationError('User not authenticated'));
      return;
    }

    emit(NotificationLoading());

    try {
      // Get initial data with pagination
      final result = await notificationRepository
          .fetchNotificationsWithPagination(
            userId: userId,
            limit: _notificationsPerPage,
            lastDocument: null,
          );

      final notifications = result['notifications'] as List<NotificationModel>;
      _lastDocument = result['lastDocument'] as DocumentSnapshot?;

      final unreadCount = await notificationRepository.getUnreadCount(userId);

      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> loadMoreNotifications() async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;
    if (currentState.isLoadingMore) return;
    if (_lastDocument == null) return;

    final userId = currentUserId;
    if (userId == null) return;

    try {
      emit(currentState.copyWith(isLoadingMore: true));

      final result = await notificationRepository
          .fetchNotificationsWithPagination(
            userId: userId,
            limit: _notificationsPerPage,
            lastDocument: _lastDocument,
          );

      final newNotifications =
          result['notifications'] as List<NotificationModel>;
      _lastDocument = result['lastDocument'] as DocumentSnapshot?;

      final updatedNotifications = [
        ...currentState.notifications,
        ...newNotifications,
      ];

      final unreadCount = await notificationRepository.getUnreadCount(userId);

      emit(
        NotificationLoaded(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      // Optimistically update UI
      final updatedNotifications =
          currentState.notifications.map((n) {
            if (n.id == notificationId) {
              return n.copyWith(isRead: true);
            }
            return n;
          }).toList();

      final newUnreadCount =
          updatedNotifications.where((n) => !n.isRead).length;

      emit(
        currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        ),
      );

      // Update in Firestore
      await notificationRepository.markAsRead(notificationId);
    } catch (e) {
      // Revert on error
      emit(currentState);
      emit(NotificationError('Failed to mark notification as read: $e'));
    }
  }

  Future<void> markAllAsRead() async {
    final userId = currentUserId;
    if (userId == null) return;

    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      // Optimistically update UI
      final updatedNotifications =
          currentState.notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();

      emit(
        currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        ),
      );

      // Update in Firestore
      await notificationRepository.markAllAsRead(userId);
    } catch (e) {
      // Revert on error
      emit(currentState);
      emit(NotificationError('Failed to mark all notifications as read: $e'));
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    try {
      // Optimistically update UI
      final updatedNotifications =
          currentState.notifications
              .where((n) => n.id != notificationId)
              .toList();

      final newUnreadCount =
          updatedNotifications.where((n) => !n.isRead).length;

      emit(
        currentState.copyWith(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        ),
      );

      // Delete from Firestore
      await notificationRepository.deleteNotification(notificationId);
    } catch (e) {
      // Revert on error
      emit(currentState);
      emit(NotificationError('Failed to delete notification: $e'));
    }
  }

  Future<void> refreshNotifications() async {
    _lastDocument = null; // Reset pagination
    await loadNotifications();
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
