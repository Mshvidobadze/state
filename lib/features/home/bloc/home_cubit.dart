import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/bloc/home_state.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'package:state/features/home/domain/advertisement_repository.dart';
import 'package:state/features/home/data/models/filter_model.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/home/utils/advertisement_inserter.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/constants/regions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository homeRepository;
  final AdvertisementRepository advertisementRepository;
  final FirebaseAuth firebaseAuth;
  FilterModel? _currentFilter;
  List<PostModel>? _allTimeFilteredPosts; // Cache for time-filtered posts
  int _currentPageIndex = 0; // Track pagination for time-filtered posts
  List<PostModel> _advertisements = []; // Cached advertisements
  int _currentAdIndex = 0; // Track which ad to insert next

  HomeCubit(
    this.homeRepository,
    this.advertisementRepository,
    this.firebaseAuth,
  ) : super(HomeInitial());

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
    _currentAdIndex = 0; // Reset ad index
    emit(HomeLoading());
    try {
      final isTimeFiltered = _isTimeFilteredTopQuery(filter);

      // Fetch posts and advertisements in parallel
      final results = await Future.wait([
        homeRepository.fetchPosts(
          filter: filter,
          limit: UIConstants.postsPerPage,
        ),
        advertisementRepository.fetchAdvertisements(),
      ]);

      final allPosts = results[0] as List<PostModel>;
      _advertisements = results[1] as List<PostModel>;

      final user = firebaseAuth.currentUser;

      if (isTimeFiltered) {
        // For time-filtered top posts, store all posts and paginate in-memory
        _allTimeFilteredPosts = allPosts;
        final firstPage = allPosts.take(UIConstants.postsPerPage).toList();

        // Insert advertisements into first page
        final postsWithAds = AdvertisementInserter.insertAdvertisements(
          posts: firstPage,
          advertisements: _advertisements,
          startingAdIndex: _currentAdIndex,
        );

        // Update ad index for next page
        _currentAdIndex = AdvertisementInserter.calculateNextAdIndex(
          currentAdIndex: _currentAdIndex,
          postsCount: firstPage.length,
          advertisementsCount: _advertisements.length,
        );

        final hasMorePosts = allPosts.length > UIConstants.postsPerPage;

        emit(
          HomeLoaded(
            postsWithAds,
            user?.uid ?? '',
            user?.displayName ?? '',
            hasMorePosts: hasMorePosts,
            lastDocumentId: null, // Not used for in-memory pagination
          ),
        );
      } else {
        // Normal pagination for other queries
        _allTimeFilteredPosts = null; // Clear cache

        // Insert advertisements
        final postsWithAds = AdvertisementInserter.insertAdvertisements(
          posts: allPosts,
          advertisements: _advertisements,
          startingAdIndex: _currentAdIndex,
        );

        // Update ad index for next page
        _currentAdIndex = AdvertisementInserter.calculateNextAdIndex(
          currentAdIndex: _currentAdIndex,
          postsCount: allPosts.length,
          advertisementsCount: _advertisements.length,
        );

        final hasMorePosts = allPosts.length == UIConstants.postsPerPage;
        final lastDocumentId = allPosts.isNotEmpty ? allPosts.last.id : null;

        emit(
          HomeLoaded(
            postsWithAds,
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

      // Remove ads from current posts to get clean post list
      final currentPostsWithoutAds = AdvertisementInserter.removeAdvertisements(
        postsWithAds: currentState.posts,
        advertisements: _advertisements,
      );

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

          // Combine posts and insert ads
          final combinedPosts = [...currentPostsWithoutAds, ...nextPage];
          final postsWithAds = AdvertisementInserter.insertAdvertisements(
            posts: combinedPosts,
            advertisements: _advertisements,
            startingAdIndex: 0, // Start from beginning for full list
          );

          final hasMorePosts = endIndex < _allTimeFilteredPosts!.length;

          emit(
            HomeLoaded(
              postsWithAds,
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

        // Combine posts and insert ads
        final combinedPosts = [...currentPostsWithoutAds, ...newPosts];
        final postsWithAds = AdvertisementInserter.insertAdvertisements(
          posts: combinedPosts,
          advertisements: _advertisements,
          startingAdIndex: 0, // Start from beginning for full list
        );

        final hasMorePosts = newPosts.length == UIConstants.postsPerPage;
        final lastDocumentId =
            newPosts.isNotEmpty
                ? newPosts.last.id
                : currentState.lastDocumentId;

        emit(
          HomeLoaded(
            postsWithAds,
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

  Future<void> reportPost(String postId, String userId) async {
    print(
      '🚩 [HOME_CUBIT] reportPost called - postId: $postId, userId: $userId',
    );
    print('🚩 [HOME_CUBIT] Current state: ${state.runtimeType}');

    if (state is! HomeLoaded) {
      print('🚩 [HOME_CUBIT] State is not HomeLoaded, returning');
      return;
    }

    try {
      // Optimistically update UI first
      final currentState = state as HomeLoaded;
      print(
        '🚩 [HOME_CUBIT] Current posts count: ${currentState.posts.length}',
      );

      final posts =
          currentState.posts.map((post) {
            if (post.id == postId && !post.reporters.contains(userId)) {
              print('🚩 [HOME_CUBIT] Found post to update, adding reporter');
              final updatedReporters = List<String>.from(post.reporters)
                ..add(userId);
              return post.copyWith(reporters: updatedReporters);
            }
            return post;
          }).toList();

      print('🚩 [HOME_CUBIT] Emitting updated state');
      emit(currentState.copyWith(posts: posts));

      // Then persist to backend
      print('🚩 [HOME_CUBIT] Calling repository.reportPost');
      await homeRepository.reportPost(postId, userId);
      print('🚩 [HOME_CUBIT] Repository call successful');
    } catch (e) {
      // Silently fail - UI already updated
      print('🚩 [HOME_CUBIT] Report error: $e');
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
      // Interaction-only blocking enforcement
      String? targetUserId;
      // Try to find post author from current state
      if (state is HomeLoaded) {
        final currentState = state as HomeLoaded;
        PostModel? found;
        for (final p in currentState.posts) {
          if (p.id == postId) {
            found = p;
            break;
          }
        }
        if (found != null) {
          targetUserId = found.authorId;
        }
      }
      // If replying to a comment, get the comment's author
      if (parentCommentId != null && parentCommentId.isNotEmpty) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .collection('comments')
              .doc(parentCommentId)
              .get();
          final data = doc.data();
          final uid = data?['userId'] as String?;
          if (uid != null && uid.isNotEmpty) {
            targetUserId = uid;
          }
        } catch (_) {}
      }
      if (targetUserId != null && targetUserId != userId) {
        final isBlocked = await _isInteractionBlocked(userId, targetUserId!);
        if (isBlocked) {
          return;
        }
      }
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

  Future<bool> _isInteractionBlocked(String me, String other) async {
    try {
      final docs = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(me).get(),
        FirebaseFirestore.instance.collection('users').doc(other).get(),
      ]);
      final a = (docs[0].data()?['blockedUsers'] as List?) ?? [];
      final b = (docs[1].data()?['blockedUsers'] as List?) ?? [];
      final aBlocked = a.map((e) => e.toString()).toSet();
      final bBlocked = b.map((e) => e.toString()).toSet();
      return aBlocked.contains(other) || bBlocked.contains(me);
    } catch (_) {
      return false;
    }
  }
}
