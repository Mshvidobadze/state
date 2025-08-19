import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/postDetails/bloc/post_details_state.dart';
import 'package:state/features/postDetails/domain/post_details_repository.dart';

class PostDetailsCubit extends Cubit<PostDetailsState> {
  final PostDetailsRepository _repository;
  final FirebaseAuth _auth;

  PostDetailsCubit(this._repository, this._auth) : super(PostDetailsInitial());

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName ?? '';

  Future<void> loadPostDetails(String postId) async {
    emit(PostDetailsLoading());
    try {
      final post = await _repository.fetchPostById(postId);
      final comments = await _repository.fetchComments(postId);

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
        ),
      );
    } catch (e) {
      emit(PostDetailsError(e.toString()));
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
        content: content,
        parentCommentId: parentCommentId,
      );

      // Fetch updated comments and update state directly
      final updatedComments = await _repository.fetchComments(postId);
      emit(
        PostDetailsLoaded(
          post: currentState.post,
          comments: updatedComments,
          isUpvoted: currentState.isUpvoted,
          isFollowing: currentState.isFollowing,
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
        ),
      );
    } catch (e) {
      emit(PostDetailsError(e.toString()));
    }
  }
}
