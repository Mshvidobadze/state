import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/search/domain/search_repository.dart';
import 'package:state/features/search/bloc/search_state.dart';

/// Cubit for managing search state
///
/// Handles:
/// - Searching users by display name
/// - Managing search loading states
/// - Debouncing search queries
class SearchCubit extends Cubit<SearchState> {
  final SearchRepository searchRepository;
  Timer? _debounceTimer;

  SearchCubit(this.searchRepository) : super(SearchInitial());

  /// Search users with debouncing
  void searchUsers(String query, {int debounceMs = 300}) {
    _debounceTimer?.cancel();

    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      emit(SearchInitial());
      return;
    }

    // Only search if query has at least 2 characters
    if (trimmedQuery.length < 2) {
      emit(SearchInitial());
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: debounceMs), () {
      _performSearch(trimmedQuery);
    });
  }

  /// Search users immediately (no debouncing)
  void searchUsersImmediate(String query) {
    _debounceTimer?.cancel();

    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      emit(SearchInitial());
      return;
    }

    // Only search if query has at least 2 characters
    if (trimmedQuery.length < 2) {
      emit(SearchInitial());
      return;
    }

    _performSearch(trimmedQuery);
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    emit(SearchLoading());

    try {
      final users = await searchRepository.searchUsers(query: query);

      if (users.isEmpty) {
        emit(SearchEmpty(query: query));
      } else {
        emit(SearchLoaded(users: users, query: query));
      }
    } catch (e) {
      emit(SearchError('Search failed: ${e.toString()}'));
    }
  }

  /// Clear search results
  void clearSearch() {
    _debounceTimer?.cancel();
    emit(SearchInitial());
  }

  /// Load more results (for future pagination)
  Future<void> loadMoreResults(String query) async {
    final currentState = state;
    if (currentState is! SearchLoaded || !currentState.hasMore) return;

    try {
      final moreUsers = await searchRepository.searchUsers(query: query);

      final allUsers = [...currentState.users, ...moreUsers];

      emit(
        SearchLoaded(
          users: allUsers,
          query: query,
          hasMore: false, // No pagination needed since we get all results
        ),
      );
    } catch (e) {
      emit(SearchError('Failed to load more results: ${e.toString()}'));
    }
  }

  /// Refresh search results
  Future<void> refreshSearch(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      emit(SearchInitial());
      return;
    }

    // Only search if query has at least 2 characters
    if (trimmedQuery.length < 2) {
      emit(SearchInitial());
      return;
    }

    await _performSearch(trimmedQuery);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
