import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/core/constants/regions.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/home/bloc/home_cubit.dart';
import 'package:state/features/home/bloc/home_state.dart';
import 'package:state/features/home/ui/post_tile.dart';
import 'package:state/features/home/ui/filters_row.dart';
import 'package:state/app/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedRegion = kRegions.first;
  String selectedSort = 'hot';

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().loadPosts(
      region: selectedRegion,
      sort: selectedSort,
    );
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

  void _onRegionChanged(String region) {
    setState(() => selectedRegion = region);
    context.read<HomeCubit>().loadPosts(region: region, sort: selectedSort);
  }

  void _onSortChanged(String sort) {
    setState(() => selectedSort = sort);
    context.read<HomeCubit>().loadPosts(region: selectedRegion, sort: sort);
  }

  @override
  Widget build(BuildContext context) {
    const logoColor = Color(0xFF800020);
    final backgroundColor = const Color(0xFFF8F4F6);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        String currentUserId = '';
        String currentUserName = '';
        if (authState is Authenticated) {
          currentUserId = authState.userId;
          currentUserName = authState.userName;
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text(
              'State',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
            backgroundColor: logoColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
            ],
            elevation: 2,
          ),
          backgroundColor: backgroundColor,
          body: Column(
            children: [
              FiltersRow(
                selectedRegion: selectedRegion,
                selectedSort: selectedSort,
                onRegionChanged: _onRegionChanged,
                onSortChanged: _onSortChanged,
                onCreatePost: _onCreatePost,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is HomeLoaded) {
                      if (state.posts.isEmpty) {
                        return const Center(child: Text('No posts found.'));
                      }
                      return RefreshIndicator(
                        color: logoColor,
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          itemCount: state.posts.length,
                          itemBuilder: (context, index) {
                            final post = state.posts[index];
                            return PostTile(
                              post: post,
                              currentUserId: currentUserId,
                              currentUserName: currentUserName,
                            );
                          },
                        ),
                      );
                    } else if (state is HomeError) {
                      return Center(child: Text(state.message));
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
