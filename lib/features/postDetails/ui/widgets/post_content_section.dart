import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/postDetails/bloc/post_details_cubit.dart';
import 'package:state/features/postDetails/ui/widgets/post_details_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/core/services/share_service.dart';
import 'package:state/service_locator.dart';

class PostContentSection extends StatelessWidget {
  final PostModel post;
  final bool isUpvoted;
  final bool isFollowing;
  final int commentsCount;
  final VoidCallback? onAuthorTap;

  const PostContentSection({
    super.key,
    required this.post,
    required this.isUpvoted,
    required this.isFollowing,
    required this.commentsCount,
    this.onAuthorTap,
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
              // Author avatar
              AvatarWidget(
                imageUrl: post.authorPhotoUrl,
                size: UIConstants.avatarMedium,
                displayName: post.authorName,
                onTap: onAuthorTap,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    onAuthorTap != null
                        ? GestureDetector(
                          onTap: onAuthorTap,
                          child: Text(
                            post.authorName,
                            style: GoogleFonts.beVietnamPro(
                              color: theme.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        : Text(
                          post.authorName,
                          style: GoogleFonts.beVietnamPro(
                            color: theme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    const SizedBox(width: 8),
                    Text(
                      _getTimeAgo(post.createdAt),
                      style: GoogleFonts.beVietnamPro(
                        color: theme.subtleColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
            const SizedBox(height: UIConstants.spacingLarge),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingLarge,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],

          // const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.arrow_upward,
                  label: post.upvotes.toString(),
                  isActive: isUpvoted,
                  onPressed:
                      () => context.read<PostDetailsCubit>().toggleUpvote(
                        post.id,
                      ),
                  horizontalPadding: 0,
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: commentsCount.toString(),
                  isActive: false,
                  onPressed: null,
                ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: '',
                  isActive: false,
                  onPressed: () => _handleShare(),
                  horizontalPadding: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onPressed,
    double horizontalPadding = 12,
    double verticalPadding = 8,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF121416)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: const Color(0xFF121416),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.015,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleShare() {
    final shareService = sl<ShareService>();
    shareService.sharePost(post);
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
