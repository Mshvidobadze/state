import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/following/domain/following_repository.dart';

class FollowingRepositoryImpl implements FollowingRepository {
  final FirebaseFirestore firestore;

  FollowingRepositoryImpl({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<PostModel>> fetchFollowingPosts(String userId) async {
    try {
      final query = firestore
          .collection('posts')
          .where('followers', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .limit(50);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => PostModel.fromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch following posts: $e');
    }
  }
}
