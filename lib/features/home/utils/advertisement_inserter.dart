import 'package:state/features/home/data/models/feed_item.dart';
import 'package:state/features/home/data/models/post_model.dart';

/// Utility class to insert advertisements into feed item lists.
class AdvertisementInserter {
  const AdvertisementInserter._();

  /// Inserts advertisements into a list of posts at every 11th position.
  ///
  /// Regular posts are tagged as [FeedItemType.post].
  /// Inserted advertisements are tagged as [FeedItemType.advertisement].
  static List<FeedItem> insertAdvertisements({
    required List<PostModel> posts,
    required List<PostModel> advertisements,
    int startingAdIndex = 0,
  }) {
    if (posts.isEmpty) {
      return const [];
    }

    if (posts.length < 10 || advertisements.isEmpty) {
      return posts.map(FeedItem.post).toList();
    }

    final result = <FeedItem>[];
    var adIndex = startingAdIndex % advertisements.length;
    var postsProcessed = 0;

    for (final post in posts) {
      result.add(FeedItem.post(post));
      postsProcessed++;

      if (postsProcessed % 10 == 0) {
        result.add(FeedItem.advertisement(advertisements[adIndex]));
        adIndex = (adIndex + 1) % advertisements.length;
      }
    }

    return result;
  }

  static int calculateNextAdIndex({
    required int currentAdIndex,
    required int postsCount,
    required int advertisementsCount,
  }) {
    if (advertisementsCount == 0) return 0;

    final adsInserted = postsCount ~/ 10;
    return (currentAdIndex + adsInserted) % advertisementsCount;
  }

  /// Returns only regular posts from a mixed feed list.
  static List<PostModel> removeAdvertisements({
    required List<FeedItem> feedItems,
  }) {
    return feedItems
        .where((item) => item.type == FeedItemType.post)
        .map((item) => item.post)
        .toList();
  }
}
