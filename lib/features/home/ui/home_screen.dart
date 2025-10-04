import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:state/core/constants/regions.dart';
import 'package:state/core/widgets/error_state.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/home/bloc/home_cubit.dart';
import 'package:state/features/home/bloc/home_state.dart';
import 'package:state/features/home/ui/post_tile.dart';
import 'package:state/app/app_router.dart';
import 'package:state/features/home/ui/filters_row.dart';
import 'package:state/features/home/ui/widgets/filters_row_skeleton.dart';
import 'package:state/features/home/ui/widgets/post_tile_skeleton.dart';
import 'package:state/features/home/data/models/filter_model.dart';
import 'package:state/core/services/preferences_service.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/service_locator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FilterModel _currentFilter;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeFilter();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final homeCubit = context.read<HomeCubit>();
        homeCubit.loadMorePosts();
      }
    });
  }

  Future<void> _initializeFilter() async {
    final savedRegion = await PreferencesService.getRegion();
    _currentFilter = FilterModel(
      region: savedRegion,
      filterType: FilterType.newest, // Default to "New" filter
      timeFilter: '', // Empty time filter for "New" filter type
    );

    if (mounted) {
      setState(() {});
      context.read<HomeCubit>().loadPosts(filter: _currentFilter);
    }
  }

  Future<void> _onRefresh() async {
    await context.read<HomeCubit>().loadPosts(filter: _currentFilter);
  }

  Future<void> _onCreatePost() async {
    final result = await AppRouter.goToPostCreation(context);
    if (result == true) {
      context.read<HomeCubit>().loadPosts(filter: _currentFilter);
    }
  }

  void _onFilterChanged(FilterModel newFilter) async {
    setState(() => _currentFilter = newFilter);

    await PreferencesService.saveRegion(newFilter.region);

    context.read<HomeCubit>().loadPosts(filter: newFilter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF1A237E); // Deep Indigo
    final isLightMode = theme.brightness == Brightness.light;
    final backgroundColor =
        isLightMode ? const Color(0xFFF8F9FA) : const Color(0xFF1A1A1A);
    final cardColor = isLightMode ? Colors.white : const Color(0xFF2D2D2D);
    final textColor = isLightMode ? Colors.black87 : Colors.white;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color:
                            isLightMode
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      if (state is HomeLoading) {
                        return const FiltersRowSkeleton();
                      }
                      return FiltersRow(
                        currentFilter: _currentFilter,
                        onFilterChanged: _onFilterChanged,
                        onCreatePost: _onCreatePost,
                        onSearch: () {
                          final navigationService = sl<INavigationService>();
                          navigationService.goToSearch(context);
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  child: BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      if (state is HomeLoading) {
                        return ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return const PostTileSkeleton();
                          },
                        );
                      } else if (state is HomeLoaded) {
                        if (state.posts.isEmpty) {
                          return Center(
                            child: Text(
                              'No posts found.',
                              style: TextStyle(color: textColor),
                            ),
                          );
                        }
                        return RefreshIndicator(
                          color: primaryColor,
                          onRefresh: _onRefresh,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount:
                                state.posts.length +
                                (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show loading indicator at the end when loading more
                              if (index == state.posts.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final post = state.posts[index];
                              return PostTile(
                                post: post,
                                currentUserId: state.currentUserId,
                                currentUserName: state.currentUserName,
                                onAuthorTap: () {
                                  final navigationService =
                                      sl<INavigationService>();
                                  navigationService.goToUserProfile(
                                    context,
                                    post.authorId,
                                  );
                                },
                              );
                            },
                          ),
                        );
                      } else if (state is HomeError) {
                        return ErrorState(
                          message: state.message,
                          textColor: textColor,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
