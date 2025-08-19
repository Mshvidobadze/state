import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/core/widgets/error_state.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/following/bloc/following_cubit.dart';
import 'package:state/features/following/bloc/following_state.dart';
import 'package:state/features/home/ui/post_tile.dart';
import 'package:state/service_locator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/features/following/ui/widgets/following_skeleton.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh(BuildContext context) async {
    await context.read<FollowingCubit>().fetchFollowingPosts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF1A237E);
    final isLightMode = theme.brightness == Brightness.light;
    final backgroundColor =
        isLightMode ? const Color(0xFFF8F9FA) : const Color(0xFF1A1A1A);
    final textColor = isLightMode ? Colors.black87 : Colors.white;

    return BlocProvider<FollowingCubit>(
      create: (context) {
        final cubit = sl<FollowingCubit>();
        cubit.fetchFollowingPosts();
        return cubit;
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: Colors.white,
              title: Text(
                'Following',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            body: BlocBuilder<FollowingCubit, FollowingState>(
              builder: (context, state) {
                if (state is FollowingLoading) {
                  return const FollowingSkeleton();
                } else if (state is FollowingLoaded) {
                  if (state.posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 48,
                            color: textColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No followed posts yet',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Posts you follow will appear here',
                            style: TextStyle(
                              color: textColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: primaryColor,
                    onRefresh: () => _onRefresh(context),
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
                          onUnfollow:
                              () => context.read<FollowingCubit>().unfollowPost(
                                post.id,
                              ),
                        );
                      },
                    ),
                  );
                } else if (state is FollowingError) {
                  return ErrorState(
                    message: state.message,
                    textColor: textColor,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}
