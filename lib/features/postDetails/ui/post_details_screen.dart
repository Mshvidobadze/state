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

          // Handle all loaded states (including interaction states)
          if (state is PostDetailsLoaded ||
              state is PostDetailsUpvoting ||
              state is PostDetailsCommenting ||
              state is PostDetailsFollowing) {
            // Extract data from any of the loaded states
            final post =
                state is PostDetailsLoaded
                    ? state.post
                    : state is PostDetailsUpvoting
                    ? state.post
                    : state is PostDetailsCommenting
                    ? state.post
                    : state is PostDetailsFollowing
                    ? state.post
                    : null;

            final comments =
                state is PostDetailsLoaded
                    ? state.comments
                    : state is PostDetailsUpvoting
                    ? state.comments
                    : state is PostDetailsCommenting
                    ? state.comments
                    : state is PostDetailsFollowing
                    ? state.comments
                    : [];

            final isUpvoted =
                state is PostDetailsLoaded
                    ? state.isUpvoted
                    : state is PostDetailsUpvoting
                    ? state.isUpvoted
                    : state is PostDetailsCommenting
                    ? state.isUpvoted
                    : state is PostDetailsFollowing
                    ? state.isUpvoted
                    : false;

            final isFollowing =
                state is PostDetailsLoaded
                    ? state.isFollowing
                    : state is PostDetailsUpvoting
                    ? state.isFollowing
                    : state is PostDetailsCommenting
                    ? state.isFollowing
                    : state is PostDetailsFollowing
                    ? state.isFollowing
                    : false;

            if (post == null) return const SizedBox.shrink();

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: Theme.of(context).primaryColor,
                    onRefresh: () async {
                      await context.read<PostDetailsCubit>().loadPostDetails(
                        post.id,
                      );
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Post Content
                        SliverToBoxAdapter(
                          child: PostContentSection(
                            post: post,
                            isUpvoted: isUpvoted,
                            isFollowing: isFollowing,
                            commentsCount: comments.length,
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
                              final comment = comments[index];
                              final currentUserId =
                                  context
                                      .read<PostDetailsCubit>()
                                      .currentUserId;
                              if (currentUserId == null)
                                return const SizedBox.shrink();

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
                            }, childCount: comments.length),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Comment Input
                CommentInput(
                  onSubmit: (content) {
                    context.read<PostDetailsCubit>().addComment(
                      postId: post.id,
                      content: content,
                      parentCommentId: _replyingToCommentId,
                    );
                    _cancelReply();
                  },
                  replyingTo:
                      _replyingToCommentId != null ? _replyingToUserName : null,
                  onCancelReply: _cancelReply,
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
