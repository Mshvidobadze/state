import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/bloc/home_state.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'package:state/features/home/data/models/filter_model.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/constants/regions.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository homeRepository;
  final FirebaseAuth firebaseAuth;
  FilterModel? _currentFilter;
  List<PostModel>? _allTimeFilteredPosts; // Cache for time-filtered posts
  int _currentPageIndex = 0; // Track pagination for time-filtered posts

  HomeCubit(this.homeRepository, this.firebaseAuth) : super(HomeInitial());

  String? get currentUserId => firebaseAuth.currentUser?.uid;
  String? get currentUserName => firebaseAuth.currentUser?.displayName ?? '';

  bool _isTimeFilteredTopQuery(FilterModel filter) {
    return filter.filterType == FilterType.top &&
        filter.timeFilter != TimeFilter.allTime &&
        filter.timeFilter.isNotEmpty;
  }

  Future<void> loadPosts({required FilterModel filter}) async {
    _currentFilter = filter;
    _currentPageIndex = 0; // Reset page index
    emit(HomeLoading());
    try {
      final isTimeFiltered = _isTimeFilteredTopQuery(filter);

      // Fetch posts from repository
      final allPosts = await homeRepository.fetchPosts(
        filter: filter,
        limit: UIConstants.postsPerPage,
      );

      final user = firebaseAuth.currentUser;

      if (isTimeFiltered) {
        // For time-filtered top posts, store all posts and paginate in-memory
        _allTimeFilteredPosts = allPosts;
        final firstPage = allPosts.take(UIConstants.postsPerPage).toList();
        final hasMorePosts = allPosts.length > UIConstants.postsPerPage;

        emit(
          HomeLoaded(
            firstPage,
            user?.uid ?? '',
            user?.displayName ?? '',
            hasMorePosts: hasMorePosts,
            lastDocumentId: null, // Not used for in-memory pagination
          ),
        );
      } else {
        // Normal pagination for other queries
        _allTimeFilteredPosts = null; // Clear cache
        final hasMorePosts = allPosts.length == UIConstants.postsPerPage;
        final lastDocumentId = allPosts.isNotEmpty ? allPosts.last.id : null;

        emit(
          HomeLoaded(
            allPosts,
            user?.uid ?? '',
            user?.displayName ?? '',
            hasMorePosts: hasMorePosts,
            lastDocumentId: lastDocumentId,
          ),
        );
      }
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
      final user = firebaseAuth.currentUser;

      // Check if we're using in-memory pagination
      if (_allTimeFilteredPosts != null && _allTimeFilteredPosts!.isNotEmpty) {
        // In-memory pagination for time-filtered top posts
        _currentPageIndex++;
        final startIndex = _currentPageIndex * UIConstants.postsPerPage;
        final endIndex = startIndex + UIConstants.postsPerPage;

        if (startIndex < _allTimeFilteredPosts!.length) {
          final nextPage =
              _allTimeFilteredPosts!
                  .skip(startIndex)
                  .take(UIConstants.postsPerPage)
                  .toList();

          final allPosts = [...currentState.posts, ...nextPage];
          final hasMorePosts = endIndex < _allTimeFilteredPosts!.length;

          emit(
            HomeLoaded(
              allPosts,
              user?.uid ?? '',
              user?.displayName ?? '',
              hasMorePosts: hasMorePosts,
              lastDocumentId: null,
            ),
          );
        }
      } else {
        // Normal Firestore pagination
        final newPosts = await homeRepository.fetchPosts(
          filter: _currentFilter!,
          limit: UIConstants.postsPerPage,
          lastDocumentId: currentState.lastDocumentId,
        );

        final allPosts = [...currentState.posts, ...newPosts];
        final hasMorePosts = newPosts.length == UIConstants.postsPerPage;
        final lastDocumentId =
            newPosts.isNotEmpty
                ? newPosts.last.id
                : currentState.lastDocumentId;

        emit(
          HomeLoaded(
            allPosts,
            user?.uid ?? '',
            user?.displayName ?? '',
            hasMorePosts: hasMorePosts,
            lastDocumentId: lastDocumentId,
          ),
        );
      }
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
