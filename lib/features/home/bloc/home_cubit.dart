import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/bloc/home_state.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'package:state/features/home/data/models/filter_model.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository homeRepository;
  final FirebaseAuth firebaseAuth;

  HomeCubit(this.homeRepository, this.firebaseAuth) : super(HomeInitial());

  String? get currentUserId => firebaseAuth.currentUser?.uid;
  String? get currentUserName => firebaseAuth.currentUser?.displayName ?? '';

  Future<void> loadPosts({required FilterModel filter}) async {
    emit(HomeLoading());
    try {
      final posts = await homeRepository.fetchPosts(filter: filter);
      final user = firebaseAuth.currentUser;
      emit(HomeLoaded(posts, user?.uid ?? '', user?.displayName ?? ''));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> upvotePost(String postId, String userId) async {
    if (state is! HomeLoaded) return;
    try {
      // Optimistically update UI before awaiting the backend
      final posts =
          (state as HomeLoaded).posts.map((post) {
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

      final user = firebaseAuth.currentUser;
      emit(HomeLoaded(posts, user?.uid ?? '', user?.displayName ?? ''));

      // Await backend update (if it fails, you may want to reload posts)
      await homeRepository.upvotePost(postId, userId);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> followPost(String postId, String userId) async {
    if (state is! HomeLoaded) return;
    try {
      await homeRepository.followPost(postId, userId);
      final posts =
          (state as HomeLoaded).posts.map((post) {
            if (post.id == postId && !post.followers.contains(userId)) {
              final updatedFollowers = List<String>.from(post.followers)
                ..add(userId);
              return post.copyWith(followers: updatedFollowers);
            }
            return post;
          }).toList();

      final user = firebaseAuth.currentUser;
      emit(HomeLoaded(posts, user?.uid ?? '', user?.displayName ?? ''));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> unfollowPost(String postId, String userId) async {
    if (state is! HomeLoaded) return;
    try {
      await homeRepository.unfollowPost(postId, userId);
      final posts =
          (state as HomeLoaded).posts.map((post) {
            if (post.id == postId && post.followers.contains(userId)) {
              final updatedFollowers = List<String>.from(post.followers)
                ..remove(userId);
              return post.copyWith(followers: updatedFollowers);
            }
            return post;
          }).toList();
      final user = firebaseAuth.currentUser;
      emit(HomeLoaded(posts, user?.uid ?? '', user?.displayName ?? ''));
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
