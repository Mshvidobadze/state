import 'package:state/features/home/data/models/post_model.dart';

/// Repository for fetching advertisement posts
///
/// Advertisements are stored in Firestore using the same PostModel structure
/// as regular posts, but with empty authorId to distinguish them.
abstract class AdvertisementRepository {
  /// Fetches all advertisements from Firestore
  ///
  /// Returns an empty list if fetching fails to prevent breaking the main feed.
  /// Advertisements are ordered by creation date (newest first).
  Future<List<PostModel>> fetchAdvertisements();
}
