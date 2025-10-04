import 'package:state/features/home/data/models/post_model.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<PostModel> posts;
  final String currentUserId;
  final String currentUserName;
  final bool hasMorePosts;
  final bool isLoadingMore;
  final String? lastDocumentId;

  HomeLoaded(
    this.posts,
    this.currentUserId,
    this.currentUserName, {
    this.hasMorePosts = true,
    this.isLoadingMore = false,
    this.lastDocumentId,
  });

  HomeLoaded copyWith({
    List<PostModel>? posts,
    String? currentUserId,
    String? currentUserName,
    bool? hasMorePosts,
    bool? isLoadingMore,
    String? lastDocumentId,
  }) {
    return HomeLoaded(
      posts ?? this.posts,
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
