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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading:
            post.authorPhotoUrl != null
                ? CircleAvatar(
                  backgroundImage: NetworkImage(post.authorPhotoUrl!),
                )
                : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(post.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.content),
            const SizedBox(height: 8),
            Row(
              children: [
                // Upvote button
                IconButton(
                  icon: Icon(
                    Icons.arrow_upward,
                    color: isUpvoted ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    context.read<HomeCubit>().upvotePost(
                      post.id,
                      currentUserId,
                    );
                  },
                ),
                Text(post.upvotes.toString()),
                const SizedBox(width: 16),
                // Follow button
                IconButton(
                  icon: Icon(
                    isFollowing ? Icons.bookmark : Icons.bookmark_border,
                    color: isFollowing ? Colors.blue : Colors.grey,
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
                const SizedBox(width: 16),
                // Comment button
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    _showCommentDialog(
                      context,
                      post.id,
                      currentUserId,
                      currentUserName,
                    );
                  },
                ),
                Text(post.commentsCount.toString()),
              ],
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to post details/comments thread
        },
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
}
