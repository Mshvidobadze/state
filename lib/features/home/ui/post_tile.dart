import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/bloc/home_cubit.dart';
import 'package:state/features/home/data/models/post_model.dart';

class PostTile extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final String currentUserName;

  const PostTile({
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isUpvoted = post.upvoters.contains(currentUserId);
    final isFollowing = post.followers.contains(currentUserId);
    const logoColor = Color(0xFF800020);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: author, region, bookmark
            Row(
              children: [
                post.authorPhotoUrl != null
                    ? CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(post.authorPhotoUrl!),
                    )
                    : const CircleAvatar(
                      radius: 14,
                      child: Icon(Icons.person, size: 16),
                    ),
                const SizedBox(width: 8),
                Text(
                  post.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11, // Smaller like Reddit
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: logoColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    post.region,
                    style: TextStyle(
                      color: logoColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isFollowing ? Icons.bookmark : Icons.bookmark_border,
                    color: isFollowing ? logoColor : Colors.grey,
                    size: 22,
                  ),
                  onPressed: () {
                    if (isFollowing) {
                      context.read<HomeCubit>().unfollowPost(
                        post.id,
                        currentUserId,
                      );
                    } else {
                      context.read<HomeCubit>().followPost(
                        post.id,
                        currentUserId,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Image if present
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Content
            Text(post.content, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            // Actions row: upvote, comments, date
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_upward,
                    color: isUpvoted ? logoColor : Colors.grey,
                  ),
                  onPressed: () {
                    context.read<HomeCubit>().upvotePost(
                      post.id,
                      currentUserId,
                    );
                  },
                ),
                Text(
                  post.upvotes.toString(),
                  style: TextStyle(
                    color: isUpvoted ? logoColor : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment, size: 20),
                  onPressed: () {
                    _showCommentDialog(
                      context,
                      post.id,
                      currentUserId,
                      currentUserName,
                    );
                  },
                ),
                Text(
                  post.commentsCount.toString(),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatDate(post.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentDialog(
    BuildContext context,
    String postId,
    String userId,
    String userName, [
    String? parentCommentId,
  ]) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(parentCommentId == null ? 'Add Comment' : 'Reply'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Write a comment...'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final content = controller.text.trim();
                  if (content.isNotEmpty) {
                    context.read<HomeCubit>().addComment(
                      postId: postId,
                      userId: userId,
                      userName: userName,
                      content: content,
                      parentCommentId: parentCommentId,
                    );
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('Post'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
