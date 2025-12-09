import 'package:state/features/home/data/models/post_model.dart';
import 'package:state/features/userProfile/data/models/user_profile_model.dart';

/// Repository interface for user profile operations
///
/// Handles:
/// - Fetching user profile information
/// - Fetching user's posts
/// - Updating user avatar
abstract class UserProfileRepository {
  /// Fetch user profile information by user ID
  Future<UserProfileModel> fetchUserProfile(String userId);

  /// Fetch all posts created by a specific user
  Future<List<PostModel>> fetchUserPosts(String userId);

  /// Update user avatar (photoUrl) in Firestore
  Future<void> updateUserAvatar(String userId, String photoUrl);
}
