import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/app/app_router.dart';
import 'package:state/features/home/bloc/home_cubit.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/home/ui/widgets/post_options_bottom_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class PostTile extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback? onUnfollow;

  const PostTile({
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    this.onUnfollow,
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
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Author avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image:
                                post.authorPhotoUrl != null
                                    ? DecorationImage(
                                      image: NetworkImage(post.authorPhotoUrl!),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              post.authorPhotoUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 16),
                        // Author name and date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              post.authorName,
                              style: GoogleFonts.beVietnamPro(
                                color: const Color(0xFF121416),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _formatDate(post.createdAt),
                              style: GoogleFonts.beVietnamPro(
                                color: const Color(0xFF6A7681),
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
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
            onTap: () => AppRouter.goToPostDetails(context, post.id),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // Makes full width clickable
              children: [
                // Post content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                  AspectRatio(
                    aspectRatio: 3 / 2,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(post.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Actions row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.arrow_upward,
                  label: post.upvotes.toString(),
                  isActive: isUpvoted,
                  onPressed: () => _handleUpvote(context),
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: post.commentsCount.toString(),
                  isActive: false,
                  onPressed: () => AppRouter.goToPostDetails(context, post.id),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20), // Bottom spacing
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
    context.read<HomeCubit>().upvotePost(post.id, currentUserId);
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

  void _showCommentDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Add Comment',
              style: GoogleFonts.beVietnamPro(
                color: const Color(0xFF121416),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: TextField(
              controller: controller,
              style: GoogleFonts.beVietnamPro(color: const Color(0xFF121416)),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: GoogleFonts.beVietnamPro(
                  color: const Color(0xFF6A7681),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6A7681)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6A7681)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF121416)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.beVietnamPro(
                    color: const Color(0xFF6A7681),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final content = controller.text.trim();
                  if (content.isNotEmpty) {
                    context.read<HomeCubit>().addComment(
                      postId: post.id,
                      userId: currentUserId,
                      userName: currentUserName,
                      content: content,
                    );
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'Post',
                  style: GoogleFonts.beVietnamPro(
                    color: const Color(0xFF121416),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
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
