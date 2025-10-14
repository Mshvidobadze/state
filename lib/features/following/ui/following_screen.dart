import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/core/widgets/error_state.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/following/bloc/following_cubit.dart';
import 'package:state/features/following/bloc/following_state.dart';
import 'package:state/features/home/ui/post_tile.dart';
import 'package:state/service_locator.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/features/following/ui/widgets/following_skeleton.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => FollowingScreenState();
}

class FollowingScreenState extends State<FollowingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to top - called when bottom nav is tapped while already on this screen
  void scrollToTopAndRefresh() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onRefresh(BuildContext context) async {
    await context.read<FollowingCubit>().fetchFollowingPosts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF74182F);
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
                  return RefreshIndicator(
                    color: primaryColor,
                    onRefresh: () => _onRefresh(context),
                    child:
                        state.posts.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                  ),
                                ),
                              ],
                            )
                            : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: state.posts.length,
                              itemBuilder: (context, index) {
                                final post = state.posts[index];
                                return Column(
                                  children: [
                                    PostTile(
                                      post: post,
                                      currentUserId: state.currentUserId,
                                      currentUserName: state.currentUserName,
                                      cubit: context.read<FollowingCubit>(),
                                      onUnfollow:
                                          () => context
                                              .read<FollowingCubit>()
                                              .unfollowPost(post.id),
                                      onAuthorTap:
                                          post.authorId.isNotEmpty
                                              ? () {
                                                final navigationService =
                                                    sl<INavigationService>();
                                                navigationService
                                                    .goToUserProfile(
                                                      context,
                                                      post.authorId,
                                                    );
                                              }
                                              : null, // Don't navigate for ads
                                    ),
                                    Container(
                                      height: 1,
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ],
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
