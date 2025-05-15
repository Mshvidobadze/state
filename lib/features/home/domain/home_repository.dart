import 'package:state/features/home/data/models/post_model.dart';

abstract class HomeRepository {
  Future<List<PostModel>> fetchPosts({
    required String region,
    required String sort,
  });

  Future<void> createPost(PostModel post);

  Future<void> upvotePost(String postId, String userId);

  Future<void> followPost(String postId, String userId);

  Future<void> unfollowPost(String postId, String userId);

  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
    String? parentCommentId,
  });
}
