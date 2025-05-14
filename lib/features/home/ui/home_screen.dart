import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/home/bloc/home_cubit.dart';
import 'package:state/features/home/bloc/home_state.dart';
import 'package:state/features/home/ui/post_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedRegion = 'Global';
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

  @override
  Widget build(BuildContext context) {
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
            title: const Text('State'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Filters
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Region filter
                    DropdownButton<String>(
                      value: selectedRegion,
                      items: const [
                        DropdownMenuItem(
                          value: 'Global',
                          child: Text('Global'),
                        ),
                        DropdownMenuItem(
                          value: 'Europe',
                          child: Text('Europe'),
                        ),
                        DropdownMenuItem(value: 'USA', child: Text('USA')),
                      ],
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
                    const SizedBox(width: 16),
                    // Sort filter
                    DropdownButton<String>(
                      value: selectedSort,
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
                  ],
                ),
              ),
              // Post creation input (simplified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "What's on your mind?",
                    suffixIcon: Icon(Icons.add_a_photo),
                  ),
                  onTap: () {
                    // TODO: Show post creation dialog/screen
                  },
                  readOnly: true,
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
