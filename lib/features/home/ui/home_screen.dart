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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedRegion = kRegions.first;
  String selectedSort = 'hot';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().loadPosts(
      region: selectedRegion,
      sort: selectedSort,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<HomeCubit>().loadPosts(
      region: selectedRegion,
      sort: selectedSort,
    );
  }

  Future<void> _onCreatePost() async {
    final result = await AppRouter.goToPostCreation(context);
    if (result == true) {
      context.read<HomeCubit>().loadPosts(
        region: selectedRegion,
        sort: selectedSort,
      );
    }
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
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              'State',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.black87,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, size: 22, color: Colors.black54),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
            ],
          ),
          body: Column(
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
                child: FiltersRow(
                  selectedRegion: selectedRegion,
                  selectedSort: selectedSort,
                  onRegionChanged: (value) {
                    setState(() => selectedRegion = value);
                    context.read<HomeCubit>().loadPosts(
                      region: selectedRegion,
                      sort: selectedSort,
                    );
                  },
                  onSortChanged: (value) {
                    setState(() => selectedSort = value);
                    context.read<HomeCubit>().loadPosts(
                      region: selectedRegion,
                      sort: selectedSort,
                    );
                  },
                  onCreatePost: _onCreatePost,
                ),
              ),
              Expanded(
                child: BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor,
                          ),
                        ),
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
                          itemCount: state.posts.length,
                          itemBuilder: (context, index) {
                            final post = state.posts[index];
                            return PostTile(
                              post: post,
                              currentUserId: state.currentUserId,
                              currentUserName: state.currentUserName,
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
        );
      },
    );
  }
}
