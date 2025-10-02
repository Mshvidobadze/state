import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/userProfile/data/models/user_profile_model.dart';
import 'package:state/features/userProfile/domain/user_profile_repository.dart';
import 'package:state/features/userProfile/bloc/user_profile_state.dart';

/// Cubit for managing user profile state
///
/// Handles:
/// - Loading user profile information
/// - Loading user's posts
/// - Managing loading states
class UserProfileCubit extends Cubit<UserProfileState> {
  final UserProfileRepository userProfileRepository;
  final FirebaseAuth firebaseAuth;

  UserProfileCubit(this.userProfileRepository, this.firebaseAuth)
    : super(UserProfileInitial());

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
}
