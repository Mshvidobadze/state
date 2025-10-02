import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/userProfile/data/models/user_profile_model.dart';

/// States for UserProfileCubit
abstract class UserProfileState {}

/// Initial state
class UserProfileInitial extends UserProfileState {}

/// Loading state
class UserProfileLoading extends UserProfileState {}

/// Loaded state with user profile and posts
class UserProfileLoaded extends UserProfileState {
  final UserProfileModel userProfile;
  final List<PostModel> posts;
  final bool isLoadingMore;

  UserProfileLoaded({
    required this.userProfile,
    required this.posts,
    this.isLoadingMore = false,
  });

  UserProfileLoaded copyWith({
    UserProfileModel? userProfile,
    List<PostModel>? posts,
    bool? isLoadingMore,
  }) {
    return UserProfileLoaded(
      userProfile: userProfile ?? this.userProfile,
      posts: posts ?? this.posts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileLoaded &&
        other.userProfile == userProfile &&
        other.posts == posts &&
        other.isLoadingMore == isLoadingMore;
  }

  @override
  int get hashCode => Object.hash(userProfile, posts, isLoadingMore);
}

/// Error state
class UserProfileError extends UserProfileState {
  final String message;

  UserProfileError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
