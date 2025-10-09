import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { upvote, comment }

class NotificationModel {
  final String id;
  final String userId; // User who receives the notification
  final String actorId; // User who performed the action
  final String actorName;
  final String actorPhotoUrl;
  final NotificationType type;
  final String postId;
  final String?
  commentId; // Required for comment notifications, null for upvote notifications
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.actorName,
    required this.actorPhotoUrl,
    required this.type,
    required this.postId,
    this.commentId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? '',
      actorPhotoUrl: data['actorPhotoUrl'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.upvote,
      ),
      postId: data['postId'] ?? '',
      commentId: data['commentId'],
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'actorId': actorId,
      'actorName': actorName,
      'actorPhotoUrl': actorPhotoUrl,
      'type': type.name,
      'postId': postId,
      'commentId': commentId,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? actorId,
    String? actorName,
    String? actorPhotoUrl,
    NotificationType? type,
    String? postId,
    String? commentId,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorPhotoUrl: actorPhotoUrl ?? this.actorPhotoUrl,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, actorId: $actorId, type: $type, postId: $postId, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.actorId == actorId &&
        other.type == type &&
        other.postId == postId &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        actorId.hashCode ^
        type.hashCode ^
        postId.hashCode ^
        isRead.hashCode;
  }
}
