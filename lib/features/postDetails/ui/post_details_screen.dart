import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/widgets/error_state.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/features/postDetails/bloc/post_details_cubit.dart';
import 'package:state/features/postDetails/bloc/post_details_state.dart';
import 'package:state/features/postDetails/ui/widgets/comment_input.dart';
import 'package:state/features/postDetails/ui/widgets/comment_item.dart';
import 'package:state/features/postDetails/ui/widgets/post_content_section.dart';
import 'package:state/features/postDetails/ui/widgets/post_details_theme.dart';
import 'package:state/features/postDetails/ui/widgets/post_details_skeleton.dart';
import 'package:state/service_locator.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;
  final String? commentId;

  const PostDetailsScreen({super.key, required this.postId, this.commentId});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    context.read<PostDetailsCubit>().loadPostDetails(
      widget.postId,
      commentId: widget.commentId,
    );
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

          // Handle all loaded states using the base class
          if (state is PostDetailsWithData) {
            final post = state.post;
            final comments = state.comments;
            final isUpvoted = state.isUpvoted;
            final isFollowing = state.isFollowing;
            final hasMoreComments = state.hasMoreComments;
            final viewingSpecificComment = state.viewingSpecificComment;

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
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        // Load more comments when user scrolls to 75% of current content
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent * 0.75) {
                          // Check if we have more comments to load
                          if (hasMoreComments) {
                            context.read<PostDetailsCubit>().loadMoreComments(
                              post.id,
                            );
                          }
                        }
                        return false;
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
                              commentsCount: post.commentsCount,
                              onAuthorTap: () {
                                final navigationService =
                                    sl<INavigationService>();
                                navigationService.goToUserProfile(
                                  context,
                                  post.authorId,
                                );
                              },
                            ),
                          ),
                          // Show "Load All Comments" button when viewing specific comment
                          if (viewingSpecificComment)
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    context
                                        .read<PostDetailsCubit>()
                                        .loadAllComments(post.id);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF111418),
                                    side: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                      width: 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Load All Comments',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
                                    onAuthorTap: () {
                                      final navigationService =
                                          sl<INavigationService>();
                                      navigationService.goToUserProfile(
                                        context,
                                        comment.userId,
                                      );
                                    },
                                  ),
                                );
                              }, childCount: comments.length),
                            ),
                          ),
                          // Load more indicator
                          if (hasMoreComments)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
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
