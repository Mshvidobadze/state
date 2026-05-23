import 'package:state/features/home/data/models/feed_item.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<FeedItem> feedItems;
  final String currentUserId;
  final String currentUserName;
  final bool hasMorePosts;
  final bool isLoadingMore;
  final String? lastDocumentId;

  HomeLoaded(
    this.feedItems,
    this.currentUserId,
    this.currentUserName, {
    this.hasMorePosts = true,
    this.isLoadingMore = false,
    this.lastDocumentId,
  });

  HomeLoaded copyWith({
    List<FeedItem>? feedItems,
    String? currentUserId,
    String? currentUserName,
    bool? hasMorePosts,
    bool? isLoadingMore,
    String? lastDocumentId,
  }) {
    return HomeLoaded(
      feedItems ?? this.feedItems,
      currentUserId ?? this.currentUserId,
      currentUserName ?? this.currentUserName,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocumentId: lastDocumentId ?? this.lastDocumentId,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}
