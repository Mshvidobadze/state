import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/home/data/models/filter_model.dart';

abstract class HomeRepository {
  Future<List<PostModel>> fetchPosts({required FilterModel filter});

  Future<void> createPost(PostModel post);

  Future<void> upvotePost(String postId, String userId);

  Future<void> followPost(String postId, String userId);

  Future<void> unfollowPost(String postId, String userId);

  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
    String? userPhotoUrl,
    String? parentCommentId,
  });
}
