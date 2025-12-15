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

class _EditNameSheet extends StatefulWidget {
  final String currentName;
  final String userId;
  final int minLength;
  final int maxLength;

  const _EditNameSheet({
    required this.currentName,
    required this.userId,
    required this.minLength,
    required this.maxLength,
  });

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _controller.text.trim();
    final isValid =
        trimmed.length >= widget.minLength && trimmed.length <= widget.maxLength;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit name',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111418),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLength: widget.maxLength,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Display name',
              hintText:
                  'Enter between ${widget.minLength} and ${widget.maxLength} characters',
              errorText: _errorText,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              setState(() {
                _errorText = null;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${trimmed.length}/${widget.maxLength}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF60748A),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            Navigator.of(context).maybePop();
                          },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving || !isValid
                        ? null
                        : () async {
                            setState(() {
                              _isSaving = true;
                            });
                            final success = await context
                                .read<UserProfileCubit>()
                                .updateDisplayName(widget.userId, trimmed);
                            if (!mounted) return;

                            if (success) {
                              Navigator.of(context).maybePop();
                            } else {
                              setState(() {
                                _isSaving = false;
                                _errorText =
                                    'Failed to update name. Please try again.';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF74182f),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserScreenState extends State<UserScreen> {
  File? _localAvatarFile; // Local file for optimistic UI
  static const int _minNameLength = 3;
  static const int _maxNameLength = 30;

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

  Future<void> _showEditNameSheet({
    required String currentName,
    required String userId,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditNameSheet(
        currentName: currentName,
        userId: userId,
        minLength: _minNameLength,
        maxLength: _maxNameLength,
      ),
    );
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

                            // User name with inline edit
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: BlocBuilder<UserProfileCubit, UserProfileState>(
                                    builder: (context, state) {
                                      String displayName =
                                          user.displayName ?? 'Anonymous User';
                                      if (state is UserProfileLoaded &&
                                          state.userProfile.displayName.isNotEmpty) {
                                        displayName = state.userProfile.displayName;
                                      }

                                      return Text(
                                        displayName,
                                        style: const TextStyle(
                                          color: Color(0xFF111418),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.015,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Color(0xFF60748A),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      final currentName =
                                          FirebaseAuth.instance.currentUser?.displayName ??
                                              'Anonymous User';
                                      _showEditNameSheet(
                                        currentName: currentName,
                                        userId: user.uid,
                                      );
                                    },
                                  ),
                                ),
                              ],
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

                            return Column(
                              children: [
                                PostTile(
                                  post: post,
                                  currentUserId: user.uid,
                                  currentUserName: user.displayName ?? '',
                                  showOptions: false,
                                ),
                                Container(
                                  height: 1,
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ],
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
