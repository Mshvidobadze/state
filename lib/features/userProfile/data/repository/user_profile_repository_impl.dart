import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/userProfile/data/models/user_profile_model.dart';
import 'package:state/features/userProfile/domain/user_profile_repository.dart';

/// Implementation of UserProfileRepository using Firestore
///
/// Handles user profile operations:
/// - Fetching user profile information
/// - Fetching user's posts
class UserProfileRepositoryImpl implements UserProfileRepository {
  final FirebaseFirestore firestore;

  UserProfileRepositoryImpl({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserProfileModel> fetchUserProfile(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      return UserProfileModel.fromDoc(userDoc);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<List<PostModel>> fetchUserPosts(String userId) async {
    try {
      final query = firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50);
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => PostModel.fromDoc(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }
}
