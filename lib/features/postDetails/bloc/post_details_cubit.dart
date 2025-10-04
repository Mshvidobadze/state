import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/postDetails/bloc/post_details_state.dart';
import 'package:state/features/postDetails/domain/post_details_repository.dart';
import 'package:state/features/postDetails/data/models/comment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailsCubit extends Cubit<PostDetailsState> {
  final PostDetailsRepository _repository;
  final FirebaseAuth _auth;

  PostDetailsCubit(this._repository, this._auth) : super(PostDetailsInitial());

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName ?? '';

  static const int _commentsPerPage = 10;

  Future<void> loadPostDetails(String postId, {String? commentId}) async {
    emit(PostDetailsLoading());
    try {
      final post = await _repository.fetchPostById(postId);

      List<CommentModel> comments;
      DocumentSnapshot? lastDocument;
      bool hasMoreComments = false;

      if (commentId != null && commentId.isNotEmpty) {
        // Load only the specific comment
        final specificComment = await _repository.fetchCommentById(
          postId,
          commentId,
        );
        comments = specificComment != null ? [specificComment] : [];
        lastDocument = null; // No pagination for single comment
        hasMoreComments = true; // Indicate there are more comments to load
      } else {
        // Load comments normally with pagination
        final result = await _repository.fetchCommentsWithPagination(
          postId: postId,
          limit: _commentsPerPage,
          lastDocument: null,
        );

        comments = result['comments'] as List<CommentModel>;
        lastDocument = result['lastDocument'] as DocumentSnapshot?;
        hasMoreComments = comments.length >= _commentsPerPage;
      }

      final currentUser = _auth.currentUser;
      final isUpvoted =
          currentUser != null && post.upvoters.contains(currentUser.uid);
      final isFollowing =
          currentUser != null && post.followers.contains(currentUser.uid);

      emit(
        PostDetailsLoaded(
          post: post,
          comments: comments,
          isUpvoted: isUpvoted,
          isFollowing: isFollowing,
          hasMoreComments: hasMoreComments,
          lastCommentDocument: lastDocument,
          viewingSpecificComment: commentId != null && commentId.isNotEmpty,
        ),
      );
    } catch (e) {
      emit(PostDetailsError(e.toString()));
    }
  }

  Future<void> loadMoreComments(String postId) async {
    if (state is! PostDetailsLoaded) return;

    final currentState = state as PostDetailsLoaded;
    if (!currentState.hasMoreComments) return;

    try {
      // Emit loading more state
      emit(
        PostDetailsLoadingMore(
          post: currentState.post,
          comments: currentState.comments,
          isUpvoted: currentState.isUpvoted,
          isFollowing: currentState.isFollowing,
          hasMoreComments: currentState.hasMoreComments,
          lastCommentDocument: currentState.lastCommentDocument,
          viewingSpecificComment: currentState.viewingSpecificComment,
        ),
      );

      // Use pagination method to fetch next batch
      final result = await _repository.fetchCommentsWithPagination(
        postId: postId,
        limit: _commentsPerPage,
        lastDocument: currentState.lastCommentDocument,
      );

      final newComments = result['comments'] as List<CommentModel>;
      final lastDocument = result['lastDocument'] as DocumentSnapshot?;

      if (newComments.isNotEmpty) {
        // Add new comments to existing ones (avoid duplicates)
        final existingIds = currentState.comments.map((c) => c.id).toSet();
        final uniqueNewComments =
            newComments.where((c) => !existingIds.contains(c.id)).toList();

        final updatedComments = [
          ...currentState.comments,
          ...uniqueNewComments,
        ];

        emit(
          PostDetailsLoaded(
            post: currentState.post,
            comments: updatedComments,
            isUpvoted: currentState.isUpvoted,
            isFollowing: currentState.isFollowing,
            hasMoreComments: newComments.length >= _commentsPerPage,
            lastCommentDocument: lastDocument,
            viewingSpecificComment: currentState.viewingSpecificComment,
          ),
        );
      } else {
        emit(currentState.copyWith(hasMoreComments: false));
      }
    } catch (e) {
      // Revert to previous state on error
      emit(
        PostDetailsLoaded(
          post: currentState.post,
          comments: currentState.comments,
          isUpvoted: currentState.isUpvoted,
          isFollowing: currentState.isFollowing,
          hasMoreComments: currentState.hasMoreComments,
          lastCommentDocument: currentState.lastCommentDocument,
          viewingSpecificComment: currentState.viewingSpecificComment,
        ),
      );
    }
  }

  Future<void> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    if (state is! PostDetailsLoaded) return;
    final currentState = state as PostDetailsLoaded;

    try {
      // Emit commenting state to show UI is updating
      emit(
        PostDetailsCommenting(
          post: currentState.post,
          comments: currentState.comments,
          isUpvoted: currentState.isUpvoted,
          isFollowing: currentState.isFollowing,
          hasMoreComments: currentState.hasMoreComments,
          lastCommentDocument: currentState.lastCommentDocument,
          viewingSpecificComment: currentState.viewingSpecificComment,
        ),
      );

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to comment');
      }

      await _repository.addComment(
        postId: postId,
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'Anonymous',
        userPhotoUrl: currentUser.photoURL,
        content: content,
        parentCommentId: parentCommentId,
      );

      // Fetch updated comments and update state directly
      final updatedComments = await _repository.fetchComments(postId);

      // Update post model with incremented comments count
      final updatedPost = currentState.post.copyWith(
        commentsCount: currentState.post.commentsCount + 1,
      );

      emit(
        PostDetailsLoaded(
          post: updatedPost,
          comments: updatedComments,
          isUpvoted: currentState.isUpvoted,
          isFollowing: currentState.isFollowing,
          hasMoreComments: currentState.hasMoreComments,
          lastCommentDocument: currentState.lastCommentDocument,
          viewingSpecificComment: currentState.viewingSpecificComment,
        ),
      );
    } catch (e) {
      emit(PostDetailsError(e.toString()));
    }
  }

  Future<void> toggleUpvote(String postId) async {
    if (state is! PostDetailsLoaded) return;
    final currentState = state as PostDetailsLoaded;

    try {
      // Emit upvoting state to show UI is updating
      emit(
        PostDetailsUpvoting(
          post: currentState.post,
          comments: currentState.comments,
          isUpvoted: currentState.isUpvoted,
          isFollowing: currentState.isFollowing,
          hasMoreComments: currentState.hasMoreComments,
          lastCommentDocument: currentState.lastCommentDocument,
          viewingSpecificComment: currentState.viewingSpecificComment,
        ),
      );

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to upvote');
      }

      await _repository.toggleUpvote(postId, currentUser.uid);

      // Update state directly with new upvote status
      final newIsUpvoted = !currentState.isUpvoted;
      final updatedPost = currentState.post.copyWith(
        upvotes:
            newIsUpvoted
                ? currentState.post.upvotes + 1
                : currentState.post.upvotes - 1,
        upvoters:
            newIsUpvoted
                ? [...currentState.post.upvoters, currentUser.uid]
                : currentState.post.upvoters
                    .where((id) => id != currentUser.uid)
                    .toList(),
      );

      emit(
        PostDetailsLoaded(
          post: updatedPost,
          comments: currentState.comments,
          isUpvoted: newIsUpvoted,
          isFollowing: currentState.isFollowing,
          hasMoreComments: currentState.hasMoreComments,
          lastCommentDocument: currentState.lastCommentDocument,
          viewingSpecificComment: currentState.viewingSpecificComment,
        ),
      );
    } catch (e) {
      emit(PostDetailsError(e.toString()));
    }
  }

  Future<void> loadAllComments(String postId) async {
    if (state is! PostDetailsLoaded) return;
    final currentState = state as PostDetailsLoaded;

    try {
      // Load all comments normally with pagination
      final result = await _repository.fetchCommentsWithPagination(
        postId: postId,
        limit: _commentsPerPage,
        lastDocument: null,
      );

      final comments = result['comments'] as List<CommentModel>;
      final lastDocument = result['lastDocument'] as DocumentSnapshot?;

      emit(
        PostDetailsLoaded(
          post: currentState.post,
          comments: comments,
          isUpvoted: currentState.isUpvoted,
          isFollowing: currentState.isFollowing,
          hasMoreComments: comments.length >= _commentsPerPage,
          lastCommentDocument: lastDocument,
          viewingSpecificComment: false, // Now viewing all comments
        ),
      );
    } catch (e) {
      emit(PostDetailsError(e.toString()));
    }
  }

  Future<void> toggleFollow(String postId) async {
    if (state is! PostDetailsLoaded) return;
    final currentState = state as PostDetailsLoaded;

    try {
      // Emit following state to show UI is updating
      emit(
        PostDetailsFollowing(
          post: currentState.post,
          comments: currentState.comments,
          isUpvoted: currentState.isUpvoted,
          isFollowing: currentState.isFollowing,
          hasMoreComments: currentState.hasMoreComments,
          lastCommentDocument: currentState.lastCommentDocument,
          viewingSpecificComment: currentState.viewingSpecificComment,
        ),
      );

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to follow');
      }

      await _repository.toggleFollow(postId, currentUser.uid);

      // Update state directly with new follow status
      final newIsFollowing = !currentState.isFollowing;
      final updatedPost = currentState.post.copyWith(
        followers:
            newIsFollowing
                ? [...currentState.post.followers, currentUser.uid]
                : currentState.post.followers
                    .where((id) => id != currentUser.uid)
                    .toList(),
      );

      emit(
        PostDetailsLoaded(
          post: updatedPost,
          comments: currentState.comments,
          isUpvoted: currentState.isUpvoted,
          isFollowing: newIsFollowing,
          hasMoreComments: currentState.hasMoreComments,
          lastCommentDocument: currentState.lastCommentDocument,
          viewingSpecificComment: currentState.viewingSpecificComment,
        ),
      );
    } catch (e) {
      emit(PostDetailsError(e.toString()));
    }
  }
}
