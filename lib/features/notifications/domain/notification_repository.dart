import 'package:state/features/notifications/data/models/notification_model.dart';

abstract class NotificationRepository {
  /// Fetch all notifications for a user
  Future<List<NotificationModel>> fetchNotifications(String userId);

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId);

  /// Get unread notification count
  Future<int> getUnreadCount(String userId);

  /// Listen to real-time notification updates
  Stream<List<NotificationModel>> listenToNotifications(String userId);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);
}
