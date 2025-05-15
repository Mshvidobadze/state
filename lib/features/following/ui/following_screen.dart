import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/following/bloc/following_cubit.dart';
import 'package:state/features/following/bloc/following_state.dart';
import 'package:state/features/home/ui/post_tile.dart';
import 'package:state/service_locator.dart';

class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});

  Future<void> _onRefresh(BuildContext context) async {
    await context.read<FollowingCubit>().fetchFollowingPosts();
  }

  @override
  Widget build(BuildContext context) {
    const logoColor = Color(0xFF800020);
    final backgroundColor = const Color(0xFFF8F4F6);

    return BlocProvider<FollowingCubit>(
      create: (context) {
        final cubit = sl<FollowingCubit>();
        cubit.fetchFollowingPosts();
        return cubit;
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'Following',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
              backgroundColor: logoColor,
              elevation: 2,
            ),
            backgroundColor: backgroundColor,
            body: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: BlocBuilder<FollowingCubit, FollowingState>(
                    builder: (context, state) {
                      if (state is FollowingLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is FollowingLoaded) {
                        if (state.posts.isEmpty) {
                          return const Center(
                            child: Text('No followed posts yet.'),
                          );
                        }
                        return RefreshIndicator(
                          color: logoColor,
                          onRefresh: () => _onRefresh(context),
                          child: ListView.builder(
                            itemCount: state.posts.length,
                            itemBuilder: (context, index) {
                              final post = state.posts[index];
                              return PostTile(
                                post: post,
                                currentUserId: state.currentUserId,
                                currentUserName: state.currentUserName,
                                onUnfollow:
                                    () => context
                                        .read<FollowingCubit>()
                                        .unfollowPost(post.id),
                              );
                            },
                          ),
                        );
                      } else if (state is FollowingError) {
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
      ),
    );
  }
}
