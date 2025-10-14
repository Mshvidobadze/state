import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/postDetails/data/models/comment_model.dart';

abstract class PostDetailsRepository {
  Future<PostModel> fetchPostById(String postId);

  Future<List<CommentModel>> fetchComments(String postId);

  Future<CommentModel?> fetchCommentById(String postId, String commentId);

  Future<Map<String, dynamic>> fetchCommentsWithPagination({
    required String postId,
    required int limit,
    DocumentSnapshot? lastDocument,
  });

  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
    String? userPhotoUrl,
    String? imageUrl,
    String? parentCommentId,
  });

  Future<void> toggleUpvote(String postId, String userId);

  Future<void> toggleCommentUpvote(
    String postId,
    String commentId,
    String userId,
  );

  Future<void> toggleFollow(String postId, String userId);

  Future<void> reportPost(String postId, String userId);
}
