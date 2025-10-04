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
  final bool viewingSpecificComment;

  PostDetailsLoaded({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
    this.viewingSpecificComment = false,
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

class PostDetailsUpvoting extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;
  final bool viewingSpecificComment;

  PostDetailsUpvoting({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
    this.viewingSpecificComment = false,
  });
}

class PostDetailsCommenting extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;
  final bool viewingSpecificComment;

  PostDetailsCommenting({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
    this.viewingSpecificComment = false,
  });
}

class PostDetailsFollowing extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;
  final bool viewingSpecificComment;

  PostDetailsFollowing({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
    this.viewingSpecificComment = false,
  });
}

class PostDetailsLoadingMore extends PostDetailsState {
  final PostModel post;
  final List<CommentModel> comments;
  final bool isUpvoted;
  final bool isFollowing;
  final bool hasMoreComments;
  final DocumentSnapshot? lastCommentDocument;
  final bool viewingSpecificComment;

  PostDetailsLoadingMore({
    required this.post,
    required this.comments,
    required this.isUpvoted,
    required this.isFollowing,
    required this.hasMoreComments,
    this.lastCommentDocument,
    this.viewingSpecificComment = false,
  });
}
