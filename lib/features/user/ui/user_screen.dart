import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/core/widgets/error_state.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/service_locator.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/userProfile/bloc/user_profile_cubit.dart';
import 'package:state/features/userProfile/bloc/user_profile_state.dart';
import 'package:state/features/home/ui/post_tile.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load current user's profile and posts
      context.read<UserProfileCubit>().loadUserProfile(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          final navigationService = sl<INavigationService>();
          navigationService.goToSignIn(context);
        }
      },
      builder: (context, authState) {
        if (authState is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('User not found')));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Profile',
              style: TextStyle(
                color: Color(0xFF111418),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.015,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF111418)),
                tooltip: 'Sign out',
                onPressed: () => context.read<AuthCubit>().signOut(),
              ),
            ],
            iconTheme: const IconThemeData(color: Color(0xFF111418)),
          ),
          body: BlocBuilder<UserProfileCubit, UserProfileState>(
            builder: (context, state) {
              return SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // (Title moved to AppBar)

                    // Profile picture and user info
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Profile picture - no tap functionality
                            Hero(
                              tag: 'user-avatar-${user.uid}',
                              child: AvatarWidget(
                                imageUrl: user.photoURL,
                                size: 80,
                                displayName: user.displayName ?? 'User',
                              ),
                            ),

                            const SizedBox(height: 12),

                            // User name
                            Text(
                              user.displayName ?? 'Anonymous User',
                              style: const TextStyle(
                                color: Color(0xFF111418),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.015,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 4),

                            // User email
                            Text(
                              user.email ?? 'No email',
                              style: const TextStyle(
                                color: Color(0xFF60748A),
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Posts section header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Posts',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111418),
                          ),
                        ),
                      ),
                    ),

                    // Loading, error, or posts list
                    if (state is UserProfileLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (state is UserProfileError)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ErrorState(
                            message: state.message,
                            textColor: Colors.black,
                          ),
                        ),
                      )
                    else if (state is UserProfileLoaded)
                      if (state.posts.isEmpty)
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
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final post = state.posts[index];

                            return PostTile(
                              post: post,
                              currentUserId: user.uid,
                              currentUserName: user.displayName ?? '',
                              showOptions: false,
                            );
                          }, childCount: state.posts.length),
                        )
                    else
                      const SliverToBoxAdapter(child: SizedBox.shrink()),

                    // Bottom spacing (small)
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
