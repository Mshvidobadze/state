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
import 'package:state/features/home/ui/widgets/post_options_bottom_sheet.dart';
import 'package:state/features/home/ui/widgets/report_confirmation_dialog.dart';
import 'package:state/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final Set<String> _collapsedCommentIds = {};
  final GlobalKey _commentInputKey = GlobalKey();
  bool _blockedWithAuthor = false;
  bool _blockingLoaded = false;
  String? _blockingAuthorId;

  Future<bool> _isInteractionBlockedWith(String otherUserId) async {
    final me = context.read<PostDetailsCubit>().currentUserId;
    if (me == null || otherUserId.isEmpty) return false;
    try {
      final docs = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(me).get(),
        FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      ]);
      final a = (docs[0].data()?['blockedUsers'] as List?) ?? [];
      final b = (docs[1].data()?['blockedUsers'] as List?) ?? [];
      final aBlocked = a.map((e) => e.toString()).toSet();
      final bBlocked = b.map((e) => e.toString()).toSet();
      return aBlocked.contains(otherUserId) || bBlocked.contains(me);
    } catch (_) {
      return false;
    }
  }

  Future<Set<String>> _getMyBlockedUsers() async {
    final me = context.read<PostDetailsCubit>().currentUserId;
    if (me == null) return {};
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(me).get();
      final list = (doc.data()?['blockedUsers'] as List?) ?? [];
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

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

  void _toggleCommentCollapse(String commentId) {
    setState(() {
      if (_collapsedCommentIds.contains(commentId)) {
        _collapsedCommentIds.remove(commentId);
      } else {
        _collapsedCommentIds.add(commentId);
      }
    });
  }

  Future<void> _loadCommentBlocking(String authorId) async {
    if (_blockingAuthorId == authorId && _blockingLoaded) return;

    _blockingAuthorId = authorId;
    final blocked = await _isInteractionBlockedWith(authorId);
    if (!mounted || _blockingAuthorId != authorId) return;

    setState(() {
      _blockedWithAuthor = blocked;
      _blockingLoaded = true;
    });
  }

  void _showPostOptions(
    BuildContext context,
    bool isFollowing,
    bool isReported,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder:
          (bottomSheetContext) => PostOptionsBottomSheet(
            isFollowing: isFollowing,
            isReported: isReported,
            onFollowToggle: () {
              // Use the outer context for BLoC access
              context.read<PostDetailsCubit>().toggleFollow(widget.postId);
              // PostOptionsBottomSheet handles Navigator.pop internally
            },
            onReport: () => _handleReport(context),
          ),
    );
  }

  void _handleReport(BuildContext context) async {
    // Capture cubit reference BEFORE showing dialog
    final postDetailsCubit = context.read<PostDetailsCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ReportConfirmationDialog(),
    );

    if (confirmed != true) return;

    // Report post - state will update automatically
    postDetailsCubit.reportPost(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PostDetailsTheme.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      resizeToAvoidBottomInset: true,
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
        actions: [
          BlocBuilder<PostDetailsCubit, PostDetailsState>(
            builder: (context, state) {
              if (state is PostDetailsWithData) {
                return IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed:
                      () => _showPostOptions(
                        context,
                        state.isFollowing,
                        state.isReported,
                      ),
                  color: theme.textColor,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<PostDetailsCubit, PostDetailsState>(
        listenWhen:
            (previous, current) =>
                current is PostDetailsWithData &&
                (previous is! PostDetailsWithData ||
                    previous.post.authorId != current.post.authorId),
        listener: (context, state) {
          if (state is PostDetailsWithData) {
            _loadCommentBlocking(state.post.authorId);
          }
        },
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

            return Column(
              children: [
                Expanded(
                  child: _PostDetailsScrollContent(
                    key: ValueKey(post.id),
                    state: state,
                    postId: widget.postId,
                    collapsedCommentIds: _collapsedCommentIds,
                    onReply: _handleReply,
                    onToggleCommentCollapse: _toggleCommentCollapse,
                    isInteractionBlockedWith: _isInteractionBlockedWith,
                    getMyBlockedUsers: _getMyBlockedUsers,
                  ),
                ),
                CommentInput(
                  key: _commentInputKey,
                  enabled: _blockingLoaded ? !_blockedWithAuthor : true,
                  disabledHint:
                      'You cannot comment on this post due to blocking settings.',
                  onSubmit: (content, imageFile) {
                    context.read<PostDetailsCubit>().addComment(
                      postId: post.id,
                      content: content,
                      imageFile: imageFile,
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

class _PostDetailsScrollContent extends StatefulWidget {
  final PostDetailsWithData state;
  final String postId;
  final Set<String> collapsedCommentIds;
  final void Function(String commentId, String userName) onReply;
  final void Function(String commentId) onToggleCommentCollapse;
  final Future<bool> Function(String otherUserId) isInteractionBlockedWith;
  final Future<Set<String>> Function() getMyBlockedUsers;

  const _PostDetailsScrollContent({
    super.key,
    required this.state,
    required this.postId,
    required this.collapsedCommentIds,
    required this.onReply,
    required this.onToggleCommentCollapse,
    required this.isInteractionBlockedWith,
    required this.getMyBlockedUsers,
  });

  @override
  State<_PostDetailsScrollContent> createState() =>
      _PostDetailsScrollContentState();
}

class _PostDetailsScrollContentState extends State<_PostDetailsScrollContent> {
  late Future<List<dynamic>> _interactionFuture;

  @override
  void initState() {
    super.initState();
    _interactionFuture = _loadInteractionState();
  }

  @override
  void didUpdateWidget(covariant _PostDetailsScrollContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.post.authorId != widget.state.post.authorId) {
      _interactionFuture = _loadInteractionState();
    }
  }

  Future<List<dynamic>> _loadInteractionState() {
    return Future.wait([
      widget.isInteractionBlockedWith(widget.state.post.authorId),
      widget.getMyBlockedUsers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PostDetailsTheme.of(context);
    final post = widget.state.post;
    final comments = widget.state.comments;
    final hasMoreComments = widget.state.hasMoreComments;
    final viewingSpecificComment = widget.state.viewingSpecificComment;

    return FutureBuilder<List<dynamic>>(
      future: _interactionFuture,
      builder: (context, snapshot) {
        final blockedWithAuthor =
            snapshot.hasData ? (snapshot.data![0] as bool) : false;
        final myBlockedSet =
            snapshot.hasData
                ? (snapshot.data![1] as Set<String>)
                : <String>{};

        return RefreshIndicator(
          color: Theme.of(context).primaryColor,
          onRefresh: () async {
            await context.read<PostDetailsCubit>().refreshPostDetails(post.id);
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent * 0.75) {
                if (hasMoreComments) {
                  context.read<PostDetailsCubit>().loadMoreComments(post.id);
                }
              }
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: PostContentSection(
                    post: post,
                    isUpvoted: widget.state.isUpvoted,
                    isDownvoted: widget.state.isDownvoted,
                    isFollowing: widget.state.isFollowing,
                    commentsCount: post.commentsCount,
                    onAuthorTap: () {
                      sl<INavigationService>().goToUserProfile(
                        context,
                        post.authorId,
                      );
                    },
                  ),
                ),
                if (viewingSpecificComment)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<PostDetailsCubit>().loadAllComments(
                            post.id,
                          );
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
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final comment = comments[index];
                      final currentUserId =
                          context.read<PostDetailsCubit>().currentUserId;
                      if (currentUserId == null) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        color: theme.cardColor,
                        margin: const EdgeInsets.only(bottom: 1),
                        child: CommentItem(
                          comment: comment,
                          currentUserId: currentUserId,
                          onReply:
                              (commentId) => widget.onReply(
                                commentId,
                                comment.userName,
                              ),
                          onUpvote: (commentId) {
                            context.read<PostDetailsCubit>().toggleCommentUpvote(
                              widget.postId,
                              commentId,
                            );
                          },
                          onToggleCollapse: widget.onToggleCommentCollapse,
                          isCollapsed: widget.collapsedCommentIds.contains(
                            comment.id,
                          ),
                          collapsedCommentIds: widget.collapsedCommentIds,
                          onAuthorTap: () {
                            sl<INavigationService>().goToUserProfile(
                              context,
                              comment.userId,
                            );
                          },
                          canReply:
                              !blockedWithAuthor &&
                              !myBlockedSet.contains(comment.userId),
                        ),
                      );
                    }, childCount: comments.length),
                  ),
                ),
                if (hasMoreComments)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
