import 'package:state/features/home/data/models/post_model.dart';

abstract class FollowingState {}

class FollowingInitial extends FollowingState {}

class FollowingLoading extends FollowingState {}

class FollowingLoaded extends FollowingState {
  final List<PostModel> posts;
  final String currentUserId;
  final String currentUserName;
  FollowingLoaded(this.posts, this.currentUserId, this.currentUserName);
}

class FollowingError extends FollowingState {
  final String message;
  FollowingError(this.message);
}
