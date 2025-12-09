import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/core/widgets/error_state.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/service_locator.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/userProfile/bloc/user_profile_cubit.dart';
import 'package:state/features/userProfile/bloc/user_profile_state.dart';
import 'package:state/features/home/ui/post_tile.dart';
import 'package:state/features/postCreation/ui/widgets/image_source_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  File? _localAvatarFile; // Local file for optimistic UI

  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      // Fallback: try to launch with external application mode
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // If both fail, show an error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load current user's profile and posts
      context.read<UserProfileCubit>().loadUserProfile(user.uid);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await ImageSourceSelector.show(context);
    if (result != null && mounted) {
      final picker = ImagePicker();
      XFile? image;

      if (result == true) {
        // Camera
        image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 512,
          maxHeight: 512,
        );
      } else if (result == false) {
        // Gallery
        image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 512,
          maxHeight: 512,
        );
      }

      if (image != null && mounted) {
        final imageFile = File(image.path);
        
        // Immediately show local image (optimistic UI)
        setState(() {
          _localAvatarFile = imageFile;
        });

        // Upload in background
        context.read<UserProfileCubit>().uploadAvatar(imageFile, user.uid).then((_) async {
          // After upload completes, reload FirebaseAuth and clear local file
          await user.reload();
          if (mounted) {
            setState(() {
              _localAvatarFile = null; // Now use network URL
            });
          }
        }).catchError((error) {
          // On error, revert to original
          if (mounted) {
            setState(() {
              _localAvatarFile = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload avatar: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
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
                            // Profile picture with edit button
                            Stack(
                              children: [
                                Hero(
                                  tag: 'user-avatar-${user.uid}',
                                  child: AvatarWidget(
                                    imageUrl: user.photoURL,
                                    localImageFile: _localAvatarFile,
                                    size: 80,
                                    displayName: user.displayName ?? 'User',
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickAndUploadAvatar,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF74182f),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

                    // Account actions / links
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.center,
                          child: TextButton.icon(
                            onPressed: () => _launchUrl(
                              'https://stateapp.net/delete-account.html',
                              context,
                            ),
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Color(0xFF74182f),
                              size: 18,
                            ),
                            label: const Text(
                              'Delete Account',
                              style: TextStyle(
                                color: Color(0xFF74182f),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
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
