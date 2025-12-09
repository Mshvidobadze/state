import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/widgets/linkified_text.dart';
import 'package:state/core/constants/app_colors.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/features/postDetails/data/models/comment_model.dart';

class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final String currentUserId;
  final Function(String) onReply;
  final Function(String) onUpvote;
  final Function(String)? onToggleCollapse;
  final bool isCollapsed;
  final Set<String> collapsedCommentIds;
  final double indentLevel;
  final VoidCallback? onAuthorTap;
  final bool canReply;

  const CommentItem({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onReply,
    required this.onUpvote,
    this.onToggleCollapse,
    this.isCollapsed = false,
    this.collapsedCommentIds = const {},
    this.indentLevel = 0,
    this.onAuthorTap,
    this.canReply = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final textColor = isLightMode ? Colors.black87 : Colors.white;
    final subtleColor = isLightMode ? Colors.black54 : Colors.white70;

    final hasReplies = comment.replies.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap:
              hasReplies && onToggleCollapse != null
                  ? () => onToggleCollapse!(comment.id)
                  : null,
          child: Container(
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
                    AvatarWidget(
                      imageUrl: comment.userPhotoUrl,
                      size: UIConstants.avatarSmall,
                      displayName: comment.userName,
                      onTap: onAuthorTap,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          onAuthorTap != null
                              ? GestureDetector(
                                onTap: onAuthorTap,
                                child: Text(
                                  comment.userName,
                                  style: GoogleFonts.beVietnamPro(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              : Text(
                                comment.userName,
                                style: GoogleFonts.beVietnamPro(
                                  color: textColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          const SizedBox(width: 8),
                          Text(
                            _getTimeAgo(comment.createdAt),
                            style: GoogleFonts.beVietnamPro(
                              color: subtleColor,
                              fontSize: 12,
                            ),
                          ),
                          if (hasReplies) ...[
                            const SizedBox(width: 8),
                            Icon(
                              isCollapsed
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              size: 16,
                              color: subtleColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Comment Content (linkified)
                if (comment.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LinkifiedText(
                      text: comment.content,
                      style: GoogleFonts.beVietnamPro(
                        color: textColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                // Comment Image
                if (comment.imageUrl != null && comment.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        comment.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  ),
                // Action Buttons Row
                Row(
                  children: [
                    // Upvote Button
                    InkWell(
                      onTap: () => onUpvote(comment.id),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              size: 16,
                              color:
                                  comment.upvoters.contains(currentUserId)
                                      ? AppColors.primary
                                      : subtleColor,
                            ),
                            if (comment.upvotes > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${comment.upvotes}',
                                style: GoogleFonts.beVietnamPro(
                                  color:
                                      comment.upvoters.contains(currentUserId)
                                          ? AppColors.primary
                                          : subtleColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reply Button
                    TextButton(
                      onPressed: canReply ? () => onReply(comment.id) : null,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Reply',
                        style: GoogleFonts.beVietnamPro(
                          color: canReply ? subtleColor : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Nested Replies - only show if not collapsed
        if (comment.replies.isNotEmpty && !isCollapsed)
          ...comment.replies.map(
            (reply) => CommentItem(
              comment: reply,
              currentUserId: currentUserId,
              onReply: onReply,
              onUpvote: onUpvote,
              onToggleCollapse: onToggleCollapse,
              isCollapsed: collapsedCommentIds.contains(reply.id),
              collapsedCommentIds: collapsedCommentIds,
              indentLevel: indentLevel + 1,
              onAuthorTap: onAuthorTap,
              canReply: canReply,
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
