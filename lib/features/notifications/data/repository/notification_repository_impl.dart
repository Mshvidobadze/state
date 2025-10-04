import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state/features/notifications/domain/notification_repository.dart';
import 'package:state/features/notifications/data/models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore firestore;

  NotificationRepositoryImpl({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      final snapshot =
          await firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = firestore.batch();
      final snapshot =
          await firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot =
          await firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  @override
  Stream<List<NotificationModel>> listenToNotifications(String userId) {
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromDoc(doc))
                  .toList(),
        );
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}
