import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/data/models/post_model.dart';
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
      // Remove the post from the local list
      final updatedPosts =
          (state as FollowingLoaded).posts
              .where((post) => post.id != postId)
              .toList();
      emit(FollowingLoaded(updatedPosts, user.uid, user.displayName ?? ''));
    } catch (e) {
      emit(FollowingError(e.toString()));
    }
  }
}
