import 'package:equatable/equatable.dart';
import 'package:state/features/home/data/models/post_model.dart';

enum FeedItemType { post, advertisement }

class FeedItem extends Equatable {
  final PostModel post;
  final FeedItemType type;

  const FeedItem({
    required this.post,
    required this.type,
  });

  factory FeedItem.post(PostModel post) {
    return FeedItem(post: post, type: FeedItemType.post);
  }

  factory FeedItem.advertisement(PostModel post) {
    return FeedItem(post: post, type: FeedItemType.advertisement);
  }

  bool get isAdvertisement => type == FeedItemType.advertisement;

  bool get isPost => type == FeedItemType.post;

  FeedItem copyWith({
    PostModel? post,
    FeedItemType? type,
  }) {
    return FeedItem(
      post: post ?? this.post,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [post, type];
}
