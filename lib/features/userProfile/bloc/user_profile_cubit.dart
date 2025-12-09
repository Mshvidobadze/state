import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/home/domain/home_repository.dart';
import 'package:state/features/userProfile/data/models/user_profile_model.dart';
import 'package:state/features/userProfile/domain/user_profile_repository.dart';
import 'package:state/features/userProfile/bloc/user_profile_state.dart';

/// Cubit for managing user profile state
///
/// Handles:
/// - Loading user profile information
/// - Loading user's posts
/// - Managing loading states
/// - Uploading user avatar
class UserProfileCubit extends Cubit<UserProfileState> {
  final UserProfileRepository userProfileRepository;
  final HomeRepository homeRepository;
  final FirebaseAuth firebaseAuth;
  final FirebaseStorage firebaseStorage;

  UserProfileCubit(
    this.userProfileRepository,
    this.firebaseAuth,
    this.firebaseStorage,
    this.homeRepository,
  ) : super(UserProfileInitial());

  /// Load user profile and posts
  Future<void> loadUserProfile(String userId) async {
    emit(UserProfileLoading());

    try {
      final results = await Future.wait([
        userProfileRepository.fetchUserProfile(userId),
        userProfileRepository.fetchUserPosts(userId),
      ]);

      final userProfile = results[0] as UserProfileModel;
      final posts = results[1] as List<PostModel>;

      emit(UserProfileLoaded(userProfile: userProfile, posts: posts));
    } catch (e) {
      emit(UserProfileError('Failed to load user profile: ${e.toString()}'));
    }
  }

  /// Refresh user profile and posts
  Future<void> refreshProfile(String userId) async {
    await loadUserProfile(userId);
  }

  /// Load more posts (for future pagination)
  Future<void> loadMorePosts(String userId) async {
    final currentState = state;
    if (currentState is! UserProfileLoaded || currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      // In future, implement pagination
      final posts = await userProfileRepository.fetchUserPosts(userId);

      emit(
        UserProfileLoaded(
          userProfile: currentState.userProfile,
          posts: posts,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(UserProfileError('Failed to load more posts: ${e.toString()}'));
    }
  }

  /// Apply follow locally to keep UI in sync when toggled from other cubits
  void applyFollowLocally(String postId, String userId) {
    final currentState = state;
    if (currentState is! UserProfileLoaded) return;

    final updatedPosts =
        currentState.posts.map((post) {
          if (post.id == postId && !post.followers.contains(userId)) {
            final updatedFollowers = List<String>.from(post.followers)
              ..add(userId);
            return post.copyWith(followers: updatedFollowers);
          }
          return post;
        }).toList();

    emit(currentState.copyWith(posts: updatedPosts));
  }

  /// Apply unfollow locally to keep UI in sync when toggled from other cubits
  void applyUnfollowLocally(String postId, String userId) {
    final currentState = state;
    if (currentState is! UserProfileLoaded) return;

    final updatedPosts =
        currentState.posts.map((post) {
          if (post.id == postId && post.followers.contains(userId)) {
            final updatedFollowers = List<String>.from(post.followers)
              ..remove(userId);
            return post.copyWith(followers: updatedFollowers);
          }
          return post;
        }).toList();

    emit(currentState.copyWith(posts: updatedPosts));
  }

  /// Upload user avatar to Firebase Storage and update Firestore + FirebaseAuth
  Future<void> uploadAvatar(File imageFile, String userId) async {
    try {
      // Upload image to Firebase Storage
      final storageRef = firebaseStorage.ref().child('user_avatars/$userId.jpg');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firestore
      await userProfileRepository.updateUserAvatar(userId, downloadUrl);

      // Update FirebaseAuth profile
      final user = firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePhotoURL(downloadUrl);
        await user.reload();
      }

      // Reload profile to reflect changes
      await loadUserProfile(userId);
    } catch (e) {
      emit(UserProfileError('Failed to upload avatar: ${e.toString()}'));
  /// Report a post and update UI optimistically
  Future<void> reportPost(String postId, String userId) async {
    if (state is! UserProfileLoaded) return;
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

  /// Apply report locally to keep UI in sync when reported from other screens
  void reportPostLocally(String postId, String userId) {
    print(
      '🚩 [USER_PROFILE_CUBIT] reportPostLocally called - postId: $postId, userId: $userId',
    );
    print('🚩 [USER_PROFILE_CUBIT] Current state: ${state.runtimeType}');

    final currentState = state;
    if (currentState is! UserProfileLoaded) {
      print(
        '🚩 [USER_PROFILE_CUBIT] State is not UserProfileLoaded, returning',
      );
      return;
    }

    print(
      '🚩 [USER_PROFILE_CUBIT] Current posts count: ${currentState.posts.length}',
    );
    final updatedPosts =
        currentState.posts.map((post) {
          if (post.id == postId && !post.reporters.contains(userId)) {
            print(
              '🚩 [USER_PROFILE_CUBIT] Found post to update, adding reporter',
            );
            final updatedReporters = List<String>.from(post.reporters)
              ..add(userId);
            return post.copyWith(reporters: updatedReporters);
          }
          return post;
        }).toList();

    print('🚩 [USER_PROFILE_CUBIT] Emitting updated state');
    emit(currentState.copyWith(posts: updatedPosts));
  }

  /// Upvote a post
  Future<void> upvotePost(String postId, String userId) async {
    if (state is! UserProfileLoaded) return;
    try {
      final currentState = state as UserProfileLoaded;
      final updatedPosts =
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
                updatedUpvotes = updatedUpvotes + 1;
              }

              return post.copyWith(
                upvoters: updatedUpvoters,
                upvotes: updatedUpvotes,
              );
            }
            return post;
          }).toList();

      emit(currentState.copyWith(posts: updatedPosts));
      await homeRepository.upvotePost(postId, userId);
    } catch (e) {
      print('Upvote error: $e');
    }
  }
}
