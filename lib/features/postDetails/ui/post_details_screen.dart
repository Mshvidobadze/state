import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/widgets/error_state.dart';
import 'package:state/features/postDetails/bloc/post_details_cubit.dart';
import 'package:state/features/postDetails/bloc/post_details_state.dart';
import 'package:state/features/postDetails/ui/widgets/comment_input.dart';
import 'package:state/features/postDetails/ui/widgets/comment_item.dart';
import 'package:state/features/postDetails/ui/widgets/post_content_section.dart';
import 'package:state/features/postDetails/ui/widgets/post_details_theme.dart';
import 'package:state/features/postDetails/ui/widgets/post_details_skeleton.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({super.key, required this.postId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    context.read<PostDetailsCubit>().loadPostDetails(widget.postId);
  }

  void _handleReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = PostDetailsTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.cardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: theme.textColor,
        ),
        title: Text(
          'Post',
          style: GoogleFonts.beVietnamPro(
            color: theme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocBuilder<PostDetailsCubit, PostDetailsState>(
        builder: (context, state) {
          if (state is PostDetailsLoading) {
            return const PostDetailsSkeleton();
          }

          if (state is PostDetailsError) {
            return ErrorState(
              message: state.message,
              textColor: theme.textColor,
            );
          }

          if (state is PostDetailsLoaded) {
            final post = state.post;
            final currentUserId =
                context.read<PostDetailsCubit>().currentUserId;
            if (currentUserId == null) return const SizedBox.shrink();

            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // Post Content
                      SliverToBoxAdapter(
                        child: PostContentSection(
                          post: post,
                          isUpvoted: state.isUpvoted,
                          isFollowing: state.isFollowing,
                          commentsCount: state.comments.length,
                        ),
                      ),
                      // Comments
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final comment = state.comments[index];
                            return Container(
                              color: theme.cardColor,
                              margin: const EdgeInsets.only(bottom: 1),
                              child: CommentItem(
                                comment: comment,
                                currentUserId: currentUserId,
                                onReply:
                                    (commentId) => _handleReply(
                                      commentId,
                                      comment.userName,
                                    ),
                              ),
                            );
                          }, childCount: state.comments.length),
                        ),
                      ),
                    ],
                  ),
                ),
                // Comment Input
                if (_replyingToUserName != null)
                  Container(
                    color: theme.cardColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Replying to ${_replyingToUserName}',
                          style: GoogleFonts.beVietnamPro(
                            color: theme.subtleColor,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _cancelReply,
                          color: theme.subtleColor,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                Container(
                  color: theme.cardColor,
                  padding: const EdgeInsets.all(16),
                  child: CommentInput(
                    onSubmit: (content) {
                      context.read<PostDetailsCubit>().addComment(
                        postId: post.id,
                        content: content,
                        parentCommentId: _replyingToCommentId,
                      );
                      _cancelReply();
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
