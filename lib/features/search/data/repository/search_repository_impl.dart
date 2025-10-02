import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:state/features/search/data/models/search_user_model.dart';
import 'package:state/features/search/domain/search_repository.dart';

/// Implementation of SearchRepository using Firestore
///
/// Handles all search operations including:
/// - Searching users by display name
/// - Optimizing search queries
class SearchRepositoryImpl implements SearchRepository {
  final FirebaseFirestore firestore;

  SearchRepositoryImpl({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<SearchUserModel>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      if (query.isEmpty) return [];

      // Normalize query for case-insensitive search
      final lowerCaseQuery = query.toLowerCase();

      // Get all users and filter client-side since Firestore doesn't support case-insensitive search
      Query firestoreQuery = firestore
          .collection('users')
          .limit(100); // Get more users to filter from

      final snapshot = await firestoreQuery.get();
      final allUsers =
          snapshot.docs
              .map(
                (doc) => SearchUserModel.fromDoc(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Filter users whose display name contains the query (case-insensitive)
      final filteredUsers =
          allUsers.where((user) {
            final displayName = user.displayName.toLowerCase();
            return displayName.contains(lowerCaseQuery);
          }).toList();

      // Sort to prioritize exact matches or more relevant results
      filteredUsers.sort((a, b) {
        final aName = a.displayName.toLowerCase();
        final bName = b.displayName.toLowerCase();

        if (aName == lowerCaseQuery) return -1;
        if (bName == lowerCaseQuery) return 1;
        if (aName.startsWith(lowerCaseQuery) &&
            !bName.startsWith(lowerCaseQuery)) {
          return -1;
        }
        if (bName.startsWith(lowerCaseQuery) &&
            !aName.startsWith(lowerCaseQuery)) {
          return 1;
        }

        // Fallback to alphabetical order
        return aName.compareTo(bName);
      });

      // Return limited results
      return filteredUsers.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
