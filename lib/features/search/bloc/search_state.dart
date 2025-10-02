import 'package:state/features/search/data/models/search_user_model.dart';

/// States for SearchCubit
abstract class SearchState {}

/// Initial state
class SearchInitial extends SearchState {}

/// Loading state
class SearchLoading extends SearchState {}

/// Loaded state with search results
class SearchLoaded extends SearchState {
  final List<SearchUserModel> users;
  final String query;
  final bool hasMore;

  SearchLoaded({
    required this.users,
    required this.query,
    this.hasMore = false,
  });

  SearchLoaded copyWith({
    List<SearchUserModel>? users,
    String? query,
    bool? hasMore,
  }) {
    return SearchLoaded(
      users: users ?? this.users,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchLoaded &&
        other.users == users &&
        other.query == query &&
        other.hasMore == hasMore;
  }

  @override
  int get hashCode => Object.hash(users, query, hasMore);
}

/// Error state
class SearchError extends SearchState {
  final String message;

  SearchError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// Empty state when no results found
class SearchEmpty extends SearchState {
  final String query;

  SearchEmpty({required this.query});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchEmpty && other.query == query;
  }

  @override
  int get hashCode => query.hashCode;
}
