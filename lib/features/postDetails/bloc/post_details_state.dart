import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/postDetails/data/models/comment_model.dart';

abstract class PostDetailsState {}

class PostDetailsInitial extends PostDetailsState {}

class PostDetailsLoading extends PostDetailsState {}

class PostDetailsLoaded extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;

  PostDetailsLoaded({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
  });
}

class PostDetailsError extends PostDetailsState {
  final String message;
  PostDetailsError(this.message);
}

class PostDetailsUpvoting extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;

  PostDetailsUpvoting({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
  });
}

class PostDetailsCommenting extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;

  PostDetailsCommenting({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
  });
}

class PostDetailsFollowing extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;

  PostDetailsFollowing({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
  });
}
