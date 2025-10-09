import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/service_locator.dart';
import 'package:state/features/home/bloc/home_cubit.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/home/ui/widgets/post_options_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class PostTile extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback? onUnfollow;
  final VoidCallback? onAuthorTap;
  final dynamic cubit; // Can be HomeCubit or FollowingCubit

  const PostTile({
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    this.onUnfollow,
    this.onAuthorTap,
    this.cubit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isUpvoted = post.upvoters.contains(currentUserId);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info (not navigable)
          Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Author avatar
                    AvatarWidget(
                      imageUrl: post.authorPhotoUrl,
                      size: UIConstants.avatarSmall,
                      displayName: post.authorName,
                      onTap: onAuthorTap,
                    ),
                    const SizedBox(width: 8),
                    // Author name and timestamp
                    Expanded(
                      child: GestureDetector(
                        onTap: onAuthorTap,
                        child: Row(
                          children: [
                            Text(
                              post.authorName,
                              style: GoogleFonts.beVietnamPro(
                                color: const Color(0xFF121416),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(post.createdAt),
                              style: GoogleFonts.beVietnamPro(
                                color: const Color(0xFF6B7280),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: IconButton(
                    onPressed: () => _showPostOptions(context),
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF121416),
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),

          // Post content area (navigable)
          GestureDetector(
            behavior: HitTestBehavior.opaque, // Makes empty spaces clickable
            onTap: () {
              final navigationService = sl<INavigationService>();
              navigationService.goToPostDetails(context, post.id);
            },
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Makes full width clickable
              children: [
                // Post content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    post.content,
                    style: GoogleFonts.beVietnamPro(
                      color: const Color(0xFF121416),
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      height: 1.5,
                    ),
                  ),
                ),

                // Post image if exists
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UIConstants.spacingLarge,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        UIConstants.radiusMedium,
                      ),
                      child: Image.network(
                        post.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.contain, // Show original size
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: UIConstants.loadingPlaceholderHeight,
                            color: Colors.grey[100],
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/vectors/logo.svg',
                                width: UIConstants.loadingPlaceholderSize,
                                height: UIConstants.loadingPlaceholderSize,
                                colorFilter: const ColorFilter.mode(
                                  Colors.grey,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Actions row
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: UIConstants.spacingXSmall,
              horizontal: UIConstants.spacingXSmall,
            ),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.arrow_upward,
                  label: post.upvotes.toString(),
                  isActive: isUpvoted,
                  onPressed: () => _handleUpvote(context),
                ),
                const SizedBox(width: UIConstants.spacingXSmall),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: post.commentsCount.toString(),
                  isActive: false,
                  onPressed: () {
                    final navigationService = sl<INavigationService>();
                    navigationService.goToPostDetails(context, post.id);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: UIConstants.spacingSmall), // Bottom spacing
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
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

  void _handleUpvote(BuildContext context) {
    if (cubit != null) {
      cubit.upvotePost(post.id, currentUserId);
    } else {
      context.read<HomeCubit>().upvotePost(post.id, currentUserId);
    }
  }

  void _handleFollowToggle(BuildContext context, bool isFollowing) {
    if (isFollowing) {
      if (onUnfollow != null) {
        onUnfollow!();
      } else {
        context.read<HomeCubit>().unfollowPost(post.id, currentUserId);
      }
    } else {
      context.read<HomeCubit>().followPost(post.id, currentUserId);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => PostOptionsBottomSheet(
            isFollowing: post.followers.contains(currentUserId),
            onFollowToggle:
                () => _handleFollowToggle(
                  context,
                  post.followers.contains(currentUserId),
                ),
            onReport: () {
              // TODO: Implement report functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report functionality coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
    );
  }
}
