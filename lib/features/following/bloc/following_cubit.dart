import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/following/domain/following_repository.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'following_state.dart';

class FollowingCubit extends Cubit<FollowingState> {
  final FollowingRepository followingRepository;
  final HomeRepository homeRepository;
  final FirebaseAuth firebaseAuth;

  FollowingCubit(
    this.followingRepository,
    this.homeRepository,
    this.firebaseAuth,
  ) : super(FollowingInitial());

  String? get currentUserId => firebaseAuth.currentUser?.uid;
  String? get currentUserName => firebaseAuth.currentUser?.displayName ?? '';

  Future<void> fetchFollowingPosts() async {
    emit(FollowingLoading());
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw Exception('User not signed in');
      final posts = await followingRepository.fetchFollowingPosts(user.uid);
      emit(FollowingLoaded(posts, user.uid, user.displayName ?? ''));
    } catch (e) {
      emit(FollowingError(e.toString()));
    }
  }

  Future<void> unfollowPost(String postId) async {
    if (state is! FollowingLoaded) return;
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw Exception('User not signed in');
      await homeRepository.unfollowPost(postId, user.uid);
      final updatedPosts =
          (state as FollowingLoaded).posts
              .where((post) => post.id != postId)
              .toList();
      emit(FollowingLoaded(updatedPosts, user.uid, user.displayName ?? ''));
    } catch (e) {
      emit(FollowingError(e.toString()));
    }
  }

  Future<void> upvotePost(String postId, String userId) async {
    if (state is! FollowingLoaded) return;
    try {
      final posts =
          (state as FollowingLoaded).posts.map((post) {
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
                updatedUpvotes = updatedUpvotes + 1;
              }

              return post.copyWith(
                upvoters: updatedUpvoters,
                upvotes: updatedUpvotes,
              );
            }
            return post;
          }).toList();

      final user = firebaseAuth.currentUser;
      emit(FollowingLoaded(posts, user?.uid ?? '', user?.displayName ?? ''));

      await homeRepository.upvotePost(postId, userId);
    } catch (e) {
      emit(FollowingError(e.toString()));
    }
  }

  Future<void> reportPost(String postId, String userId) async {
    if (state is! FollowingLoaded) return;
    try {
      // Optimistically update UI first
      reportPostLocally(postId, userId);
      // Then persist to backend
      await homeRepository.reportPost(postId, userId);
    } catch (e) {
      // Silently fail - UI already updated
      print('Report error: $e');
    }
  }

  void reportPostLocally(String postId, String userId) {
    if (state is! FollowingLoaded) return;
    final currentState = state as FollowingLoaded;
    final posts =
        currentState.posts.map((post) {
          if (post.id == postId && !post.reporters.contains(userId)) {
            final updatedReporters = List<String>.from(post.reporters)
              ..add(userId);
            return post.copyWith(reporters: updatedReporters);
          }
          return post;
        }).toList();

    emit(
      FollowingLoaded(
        posts,
        currentState.currentUserId,
        currentState.currentUserName,
      ),
    );
  }
}
