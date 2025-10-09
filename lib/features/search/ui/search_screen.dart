import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/constants/ui_constants.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/core/widgets/error_state.dart';
import 'package:state/features/search/bloc/search_cubit.dart';
import 'package:state/features/search/bloc/search_state.dart';
import 'package:state/features/search/data/models/search_user_model.dart';
import 'package:state/service_locator.dart';

/// Search Screen for finding users by display name
///
/// Features:
/// - Real-time search with debouncing
/// - User search results with avatar and name
/// - Navigation to user profiles
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<SearchCubit>().searchUsers(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Search Users',
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: BlocConsumer<SearchCubit, SearchState>(
                listener: (context, state) {
                  if (state is SearchError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const _SearchSkeleton();
                  }
                  if (state is SearchError) {
                    return ErrorState(
                      message: state.message,
                      textColor: Colors.black,
                    );
                  }
                  if (state is SearchEmpty) {
                    return _buildEmptyState(state.query);
                  }
                  if (state is SearchLoaded) {
                    return _buildSearchResults(state.users);
                  }
                  // Show initial state or "enter more characters" message
                  return _buildInitialState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search by name...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      context.read<SearchCubit>().clearSearch();
                    },
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<SearchUserModel> users) {
    if (users.isEmpty) {
      return _buildEmptyState(_searchController.text);
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _SearchUserTile(
          user: user,
          onTap: () {
            final navigationService = sl<INavigationService>();
            navigationService.goToUserProfile(context, user.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'Start searching for users'
                : 'No users found for "$query"',
            style: GoogleFonts.beVietnamPro(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    final hasText = _searchController.text.trim().isNotEmpty;
    final textLength = _searchController.text.trim().length;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            hasText && textLength < 2
                ? 'Enter at least 2 characters to search'
                : 'Search for people to connect with!',
            style: GoogleFonts.beVietnamPro(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Search result user tile widget
class _SearchUserTile extends StatelessWidget {
  final SearchUserModel user;
  final VoidCallback onTap;

  const _SearchUserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacingLarge,
          vertical: UIConstants.spacingMedium,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
        ),
        child: Row(
          children: [
            AvatarWidget(
              imageUrl: user.photoUrl,
              size: UIConstants.avatarLarge,
              displayName: user.displayName,
            ),
            const SizedBox(width: UIConstants.spacingMedium),
            Expanded(
              child: Text(
                user.displayName,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111418),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6B7280),
              size: UIConstants.iconLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading skeleton widget
class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
