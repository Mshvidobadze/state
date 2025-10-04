import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/bloc/home_state.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'package:state/features/home/data/models/filter_model.dart';
import 'package:state/core/constants/ui_constants.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository homeRepository;
  final FirebaseAuth firebaseAuth;
  FilterModel? _currentFilter;

  HomeCubit(this.homeRepository, this.firebaseAuth) : super(HomeInitial());

  String? get currentUserId => firebaseAuth.currentUser?.uid;
  String? get currentUserName => firebaseAuth.currentUser?.displayName ?? '';

  Future<void> loadPosts({required FilterModel filter}) async {
    _currentFilter = filter;
    emit(HomeLoading());
    try {
      final posts = await homeRepository.fetchPosts(
        filter: filter,
        limit: UIConstants.postsPerPage,
      );
      final user = firebaseAuth.currentUser;
      final hasMorePosts = posts.length == UIConstants.postsPerPage;
      final lastDocumentId = posts.isNotEmpty ? posts.last.id : null;

      emit(
        HomeLoaded(
          posts,
          user?.uid ?? '',
          user?.displayName ?? '',
          hasMorePosts: hasMorePosts,
          lastDocumentId: lastDocumentId,
        ),
      );
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> loadMorePosts() async {
    if (_currentFilter == null) return;

    final currentState = state;
    if (currentState is! HomeLoaded ||
        currentState.isLoadingMore ||
        !currentState.hasMorePosts) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final newPosts = await homeRepository.fetchPosts(
        filter: _currentFilter!,
        limit: UIConstants.postsPerPage,
        lastDocumentId: currentState.lastDocumentId,
      );

      final user = firebaseAuth.currentUser;
      final allPosts = [...currentState.posts, ...newPosts];
      final hasMorePosts = newPosts.length == UIConstants.postsPerPage;
      final lastDocumentId =
          newPosts.isNotEmpty ? newPosts.last.id : currentState.lastDocumentId;

      emit(
        HomeLoaded(
          allPosts,
          user?.uid ?? '',
          user?.displayName ?? '',
          hasMorePosts: hasMorePosts,
          lastDocumentId: lastDocumentId,
        ),
      );
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> upvotePost(String postId, String userId) async {
    if (state is! HomeLoaded) return;
    try {
      final currentState = state as HomeLoaded;
      final posts =
          currentState.posts.map((post) {
            if (post.id == postId) {
              final upvoters = post.upvoters;
              bool hasUpvoted = upvoters.contains(userId);
              final updatedUpvoters = List<String>.from(upvoters);
              int updatedUpvotes = post.upvotes;

              if (hasUpvoted) {
                updatedUpvoters.remove(userId);
                updatedUpvotes = updatedUpvotes > 0 ? updatedUpvotes - 1 : 0;
              } else {
                updatedUpvoters.add(userId);
                updatedUpvotes += 1;
              }

              return post.copyWith(
                upvotes: updatedUpvotes,
                upvoters: updatedUpvoters,
              );
            }
            return post;
          }).toList();

      emit(currentState.copyWith(posts: posts));

      await homeRepository.upvotePost(postId, userId);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> followPost(String postId, String userId) async {
    if (state is! HomeLoaded) return;
    try {
      await homeRepository.followPost(postId, userId);
      final currentState = state as HomeLoaded;
      final posts =
          currentState.posts.map((post) {
            if (post.id == postId && !post.followers.contains(userId)) {
              final updatedFollowers = List<String>.from(post.followers)
                ..add(userId);
              return post.copyWith(followers: updatedFollowers);
            }
            return post;
          }).toList();

      emit(currentState.copyWith(posts: posts));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> unfollowPost(String postId, String userId) async {
    if (state is! HomeLoaded) return;
    try {
      await homeRepository.unfollowPost(postId, userId);
      final currentState = state as HomeLoaded;
      final posts =
          currentState.posts.map((post) {
            if (post.id == postId && post.followers.contains(userId)) {
              final updatedFollowers = List<String>.from(post.followers)
                ..remove(userId);
              return post.copyWith(followers: updatedFollowers);
            }
            return post;
          }).toList();

      emit(currentState.copyWith(posts: posts));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      await homeRepository.addComment(
        postId: postId,
        userId: userId,
        userName: userName,
        content: content,
        parentCommentId: parentCommentId,
      );
      // Optionally, you can reload posts or comments here if needed
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
