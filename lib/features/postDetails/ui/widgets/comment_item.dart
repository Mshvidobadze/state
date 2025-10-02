import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/features/postDetails/data/models/comment_model.dart';

class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final Function(String) onReply;
  final double indentLevel;

  const CommentItem({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onReply,
    this.indentLevel = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final textColor = isLightMode ? Colors.black87 : Colors.white;
    final subtleColor = isLightMode ? Colors.black54 : Colors.white70;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: indentLevel * 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: indentLevel > 0 ? 2 : 0,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comment Header
              Row(
                children: [
                  // Comment author avatar
                  Container(
                    width: UIConstants.avatarSmall,
                    height: UIConstants.avatarSmall,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image:
                          comment.userPhotoUrl != null
                              ? DecorationImage(
                                image: NetworkImage(comment.userPhotoUrl!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        comment.userPhotoUrl == null
                            ? const Icon(
                              Icons.person,
                              size: UIConstants.iconSmall,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          comment.userName,
                          style: GoogleFonts.beVietnamPro(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${_getTimeAgo(comment.createdAt)}',
                          style: GoogleFonts.beVietnamPro(
                            color: subtleColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Comment Content
              Text(
                comment.content,
                style: GoogleFonts.beVietnamPro(
                  color: textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Reply Button
              TextButton(
                onPressed: () => onReply(comment.id),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Reply',
                  style: GoogleFonts.beVietnamPro(
                    color: subtleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Nested Replies
        if (comment.replies.isNotEmpty)
          ...comment.replies.map(
            (reply) => CommentItem(
              comment: reply,
              currentUserId: currentUserId,
              onReply: onReply,
              indentLevel: indentLevel + 1,
            ),
          ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
