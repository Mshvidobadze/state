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
import 'package:cloud_firestore/cloud_firestore.dart';

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

                        return Column(
                          children: [
                            PostTile(
                              post: post,
                              currentUserId: currentUser?.uid ?? '',
                              currentUserName: currentUser?.displayName ?? '',
                              cubit: context.read<UserProfileCubit>(),
                              // No onAuthorTap callback - author name won't be clickable
                            ),
                            Container(
                              height: 1,
                              color: const Color(0xFFE5E7EB),
                            ),
                          ],
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
class _ProfileHeader extends StatefulWidget {
  final UserProfileModel userProfile;

  const _ProfileHeader({required this.userProfile});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _loading = true;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(me.uid).get();
      final list = (doc.data()?['blockedUsers'] as List?) ?? [];
      setState(() {
        _isBlocked = list.map((e) => e.toString()).contains(widget.userProfile.id);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleBlock() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return;
    if (!_isBlocked) {
      // Show info/confirmation dialog before blocking
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Block User?',
            style: GoogleFonts.beVietnamPro(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Blocking limits interactions only:',
                style: GoogleFonts.beVietnamPro(fontSize: 14),
              ),
              const SizedBox(height: 8),
              _Bullet('You cannot comment on each other’s posts'),
              _Bullet('You cannot reply to each other’s comments'),
              const SizedBox(height: 8),
              Text(
                'You will still see each other’s public posts in global feeds.',
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Block',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _loading = true);
    try {
      if (_isBlocked) {
        await FirebaseFirestore.instance.collection('users').doc(me.uid).set({
          'blockedUsers': FieldValue.arrayRemove([widget.userProfile.id]),
        }, SetOptions(merge: true));
        setState(() => _isBlocked = false);
      } else {
        await FirebaseFirestore.instance.collection('users').doc(me.uid).set({
          'blockedUsers': FieldValue.arrayUnion([widget.userProfile.id]),
        }, SetOptions(merge: true));
        setState(() => _isBlocked = true);
      }
    } catch (_) {
      // ignore errors for now
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final isSelf = me?.uid == widget.userProfile.id;
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Avatar - no tap functionality
          Hero(
            tag: 'user-avatar-${widget.userProfile.id}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: AvatarWidget(
                imageUrl: widget.userProfile.photoUrl,
                size: 120,
                displayName: widget.userProfile.displayName,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Display name
          Text(
            widget.userProfile.displayName,
            style: GoogleFonts.beVietnamPro(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          if (!isSelf) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: _loading ? null : _toggleBlock,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isBlocked ? Colors.red : const Color(0xFF74182f),
                  ),
                ),
                child: Text(
                  _isBlocked ? 'Unblock User' : 'Block User',
                  style: GoogleFonts.beVietnamPro(
                    color: _isBlocked ? Colors.red : const Color(0xFF74182f),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.beVietnamPro(fontSize: 14),
            ),
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
