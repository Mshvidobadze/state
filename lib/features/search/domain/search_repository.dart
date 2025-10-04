import 'package:state/features/search/data/models/search_user_model.dart';

/// Repository interface for user search operations
///
/// Handles:
/// - Searching users by display name
/// - Fetching search results with pagination
abstract class SearchRepository {
  /// Search users by display name
  ///
  /// [query] - The search query string
  /// Returns list of users matching the search query
  Future<List<SearchUserModel>> searchUsers({required String query});
}
