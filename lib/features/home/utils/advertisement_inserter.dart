import 'package:state/features/home/data/models/post_model.dart';

/// Utility class to insert advertisements into post lists
///
/// This is a pure utility class with only static methods.
/// Use this to maintain consistent ad placement across paginated post lists.
class AdvertisementInserter {
  // Private constructor to prevent instantiation
  const AdvertisementInserter._();

  /// Inserts advertisements into a list of posts at every 11th position
  ///
  /// Rules:
  /// - Only insert if there are at least 10 posts
  /// - Insert at positions 10, 21, 32, etc. (every 11th item, 0-indexed)
  /// - Cycle through advertisements when running out
  ///
  /// Example:
  /// Posts: [P1, P2, P3, ... P10, P11, P12, ... P21, P22]
  /// Ads: [A1, A2, A3]
  /// Result: [P1, P2, ... P10, A1, P11, ... P20, A2, P21, ... P30, A3, P31, ...]
  static List<PostModel> insertAdvertisements({
    required List<PostModel> posts,
    required List<PostModel> advertisements,
    int startingAdIndex = 0,
  }) {
    // Don't insert ads if there are less than 10 posts or no ads available
    if (posts.length < 10 || advertisements.isEmpty) {
      return posts;
    }

    final result = <PostModel>[];
    int adIndex = startingAdIndex % advertisements.length;
    int postsProcessed = 0;

    for (int i = 0; i < posts.length; i++) {
      result.add(posts[i]);
      postsProcessed++;

      // Insert ad after every 10 posts (at positions 10, 20, 30, etc.)
      if (postsProcessed % 10 == 0) {
        result.add(advertisements[adIndex]);
        adIndex = (adIndex + 1) % advertisements.length;
      }
    }

    return result;
  }

  /// Calculates the next ad index to use after inserting ads into a batch
  /// This is used for pagination to maintain ad cycling across pages
  static int calculateNextAdIndex({
    required int currentAdIndex,
    required int postsCount,
    required int advertisementsCount,
  }) {
    if (advertisementsCount == 0) return 0;

    // Calculate how many ads were inserted
    final adsInserted = postsCount ~/ 10;
    return (currentAdIndex + adsInserted) % advertisementsCount;
  }

  /// Removes advertisements from a list of posts
  /// Used when refreshing or filtering to get clean post list
  static List<PostModel> removeAdvertisements({
    required List<PostModel> postsWithAds,
    required List<PostModel> advertisements,
  }) {
    if (advertisements.isEmpty) return postsWithAds;

    final adIds = advertisements.map((ad) => ad.id).toSet();
    return postsWithAds.where((post) => !adIds.contains(post.id)).toList();
  }
}
