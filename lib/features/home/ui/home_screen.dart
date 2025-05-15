import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/core/constants/regions.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/home/bloc/home_cubit.dart';
import 'package:state/features/home/bloc/home_state.dart';
import 'package:state/features/home/ui/post_tile.dart';
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

  @override
  Widget build(BuildContext context) {
    const logoColor = Color(0xFF800020);
    final backgroundColor = const Color(0xFFF8F4F6);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('State'),
            backgroundColor: logoColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Region filter
                    DropdownButton<String>(
                      value: selectedRegion,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: logoColor),
                      items:
                          kRegions
                              .map(
                                (region) => DropdownMenuItem(
                                  value: region,
                                  child: Text(region),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedRegion = value);
                          context.read<HomeCubit>().loadPosts(
                            region: selectedRegion,
                            sort: selectedSort,
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    // Sort filter
                    DropdownButton<String>(
                      value: selectedSort,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: logoColor),
                      items: const [
                        DropdownMenuItem(value: 'hot', child: Text('Hot')),
                        DropdownMenuItem(value: 'new', child: Text('New')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedSort = value);
                          context.read<HomeCubit>().loadPosts(
                            region: selectedRegion,
                            sort: selectedSort,
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    // Create button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: logoColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Create'),
                      onPressed: _onCreatePost,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Posts list with pull-to-refresh
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
                              currentUserId: state.currentUserId,
                              currentUserName: state.currentUserName,
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
