import 'package:equatable/equatable.dart';
import 'package:state/features/notifications/data/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoadingMore;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
    this.isLoadingMore = false,
  });

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoadingMore,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [notifications, unreadCount, isLoadingMore];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}
