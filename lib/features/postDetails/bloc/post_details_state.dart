import 'package:cloud_firestore/cloud_firestore.dart';
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
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;

  PostDetailsLoaded({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
  });

  PostDetailsLoaded copyWith({
    PostModel? post,
    List<CommentModel>? comments,
    bool? isUpvoted,
    bool? isFollowing,
    bool? hasMoreComments,
    DocumentSnapshot? lastCommentDocument,
  }) {
    return PostDetailsLoaded(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isFollowing: isFollowing ?? this.isFollowing,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      lastCommentDocument: lastCommentDocument ?? this.lastCommentDocument,
    );
  }
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
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;

  PostDetailsUpvoting({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
  });
}

class PostDetailsCommenting extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;

  PostDetailsCommenting({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
  });
}

class PostDetailsFollowing extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;

  PostDetailsFollowing({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
  });
}

class PostDetailsLoadingMore extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;

  PostDetailsLoadingMore({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
  });
}
