import 'package:state/features/home/data/models/post_model.dart';

abstract class FollowingRepository {
  Future<List<PostModel>> fetchFollowingPosts(String userId);
}
