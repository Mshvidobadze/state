import 'package:state/features/home/data/models/post_model.dart';

/// Repository for fetching advertisements for the home feed.
///
/// Advertisements are stored in Firestore using the same [PostModel] structure
/// as regular posts. Feed placement tags them as [FeedItemType.advertisement].
abstract class AdvertisementRepository {
  /// Fetches all advertisements from Firestore
  ///
  /// Returns an empty list if fetching fails to prevent breaking the main feed.
  /// Advertisements are ordered by creation date (newest first).
  Future<List<PostModel>> fetchAdvertisements();
}
