import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/core/widgets/error_state.dart';
import 'package:state/features/home/ui/post_tile.dart';
import 'package:state/features/userProfile/bloc/user_profile_cubit.dart';
import 'package:state/features/userProfile/bloc/user_profile_state.dart';
import 'package:state/features/userProfile/data/models/user_profile_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User Profile Screen displaying user information and their posts
///
/// Features:
/// - User avatar and display name
/// - Profile statistics (posts, followers, following)
/// - Follow/unfollow button
/// - List of user's posts using PostTile widget
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load user profile when screen initializes
    context.read<UserProfileCubit>().loadUserProfile(widget.userId);
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
          'Profile',
          style: GoogleFonts.beVietnamPro(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<UserProfileCubit, UserProfileState>(
        listener: (context, state) {
          if (state is UserProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is UserProfileLoading) {
            return const _UserProfileSkeleton();
          }

          if (state is UserProfileError) {
            return ErrorState(message: state.message, textColor: Colors.black);
          }

          if (state is UserProfileLoaded) {
            final userProfile = state.userProfile;
            final posts = state.posts;
            final isLoadingMore = state.isLoadingMore;

            return RefreshIndicator(
              onRefresh:
                  () => context.read<UserProfileCubit>().refreshProfile(
                    widget.userId,
                  ),
              child: CustomScrollView(
                slivers: [
                  // Profile header
                  SliverToBoxAdapter(
                    child: _ProfileHeader(userProfile: userProfile),
                  ),

                  // Posts section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Posts',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  // Posts list
                  if (posts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.post_add,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = posts[index];
                        final currentUser = FirebaseAuth.instance.currentUser;

                        return PostTile(
                          post: post,
                          currentUserId: currentUser?.uid ?? '',
                          currentUserName: currentUser?.displayName ?? '',
                          // No onAuthorTap callback - author name won't be clickable
                        );
                      }, childCount: posts.length),
                    ),

                  // Loading more indicator
                  if (isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Profile header widget showing user information
class _ProfileHeader extends StatelessWidget {
  final UserProfileModel userProfile;

  const _ProfileHeader({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Avatar - no tap functionality
          Hero(
            tag: 'user-avatar-${userProfile.id}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: AvatarWidget(
                imageUrl: userProfile.photoUrl,
                size: 120,
                displayName: userProfile.displayName,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Display name
          Text(
            userProfile.displayName,
            style: GoogleFonts.beVietnamPro(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Loading skeleton for user profile
class _UserProfileSkeleton extends StatelessWidget {
  const _UserProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
