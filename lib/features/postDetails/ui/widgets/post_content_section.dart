import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/postDetails/bloc/post_details_cubit.dart';
import 'package:state/features/postDetails/ui/widgets/post_details_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostContentSection extends StatelessWidget {
  final PostModel post;
  final bool isUpvoted;
  final bool isFollowing;
  final int commentsCount;

  const PostContentSection({
    super.key,
    required this.post,
    required this.isUpvoted,
    required this.isFollowing,
    required this.commentsCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = PostDetailsTheme.of(context);

    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Row(
            children: [
              Text(
                post.authorName,
                style: GoogleFonts.beVietnamPro(
                  color: theme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${_getTimeAgo(post.createdAt)}',
                style: GoogleFonts.beVietnamPro(
                  color: theme.subtleColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Post Content
          Text(
            post.content,
            style: GoogleFonts.beVietnamPro(
              color: theme.textColor,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Actions Row
          Row(
            children: [
              _ActionButton(
                icon: isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                label: '${post.upvotes}',
                onPressed:
                    () =>
                        context.read<PostDetailsCubit>().toggleUpvote(post.id),
                isActive: isUpvoted,
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.comment_outlined,
                label: '$commentsCount',
                onPressed: null,
              ),
              const Spacer(),
              _ActionButton(
                icon: isFollowing ? Icons.bookmark : Icons.bookmark_outline,
                label: isFollowing ? 'Following' : 'Follow',
                onPressed:
                    () =>
                        context.read<PostDetailsCubit>().toggleFollow(post.id),
                isActive: isFollowing,
              ),
            ],
          ),
        ],
      ),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = PostDetailsTheme.of(context);
    final color = isActive ? const Color(0xFF1A237E) : theme.subtleColor;

    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
