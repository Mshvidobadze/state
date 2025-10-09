import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/postDetails/data/models/comment_model.dart';

abstract class PostDetailsState {}

class PostDetailsInitial extends PostDetailsState {}

class PostDetailsLoading extends PostDetailsState {}

/// Base class for all states that contain post details data
abstract class PostDetailsWithData extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;
  final bool viewingSpecificComment;

  PostDetailsWithData({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
    this.viewingSpecificComment = false,
  });
}

class PostDetailsLoaded extends PostDetailsWithData {
  PostDetailsLoaded({
    required super.post,
    required super.comments,
    required super.isUpvoted,
    required super.isFollowing,
    required super.hasMoreComments,
    super.lastCommentDocument,
    super.viewingSpecificComment = false,
  });

  PostDetailsLoaded copyWith({
    PostModel? post,
    List<CommentModel>? comments,
    bool? isUpvoted,
    bool? isFollowing,
    bool? hasMoreComments,
    DocumentSnapshot? lastCommentDocument,
    bool? viewingSpecificComment,
  }) {
    return PostDetailsLoaded(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isFollowing: isFollowing ?? this.isFollowing,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      lastCommentDocument: lastCommentDocument ?? this.lastCommentDocument,
      viewingSpecificComment:
          viewingSpecificComment ?? this.viewingSpecificComment,
    );
  }
}

class PostDetailsError extends PostDetailsState {
  final String message;
  PostDetailsError(this.message);
}

class PostDetailsUpvoting extends PostDetailsWithData {
  PostDetailsUpvoting({
    required super.post,
    required super.comments,
    required super.isUpvoted,
    required super.isFollowing,
    required super.hasMoreComments,
    super.lastCommentDocument,
    super.viewingSpecificComment = false,
  });
}

class PostDetailsCommenting extends PostDetailsWithData {
  PostDetailsCommenting({
    required super.post,
    required super.comments,
    required super.isUpvoted,
    required super.isFollowing,
    required super.hasMoreComments,
    super.lastCommentDocument,
    super.viewingSpecificComment = false,
  });
}

class PostDetailsFollowing extends PostDetailsWithData {
  PostDetailsFollowing({
    required super.post,
    required super.comments,
    required super.isUpvoted,
    required super.isFollowing,
    required super.hasMoreComments,
    super.lastCommentDocument,
    super.viewingSpecificComment = false,
  });
}

class PostDetailsLoadingMore extends PostDetailsWithData {
  PostDetailsLoadingMore({
    required super.post,
    required super.comments,
    required super.isUpvoted,
    required super.isFollowing,
    required super.hasMoreComments,
    super.lastCommentDocument,
    super.viewingSpecificComment = false,
  });
}
