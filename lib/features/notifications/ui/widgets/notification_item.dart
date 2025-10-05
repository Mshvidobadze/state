import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/features/notifications/data/models/notification_model.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/core/constants/ui_constants.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        theme.brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF121416);
    final subtleColor =
        theme.brightness == Brightness.dark
            ? Colors.grey[400]
            : const Color(0xFF6A7681);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                notification.isRead
                    ? Colors.transparent
                    : theme.primaryColor.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Actor avatar
              AvatarWidget(
                imageUrl: notification.actorPhotoUrl,
                size: UIConstants.avatarMedium,
                displayName: notification.actorName,
              ),
              const SizedBox(width: 12),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: notification.actorName,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${notification.message}',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTimeAgo(notification.createdAt),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: subtleColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Action icon
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  _getNotificationIcon(),
                  size: 20,
                  color: subtleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.upvote:
        return Icons.thumb_up;
      case NotificationType.comment:
        return Icons.comment;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

