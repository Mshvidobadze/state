import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/service_locator.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/notifications/bloc/notification_cubit.dart';
import 'package:state/features/notifications/bloc/notification_state.dart';
import 'package:state/features/notifications/ui/widgets/notification_item.dart';
import 'package:state/core/widgets/error_state.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<NotificationCubit>().loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      builder: (context, state) {
        if (state is AuthLoading) {
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
          body: SafeArea(
            child: Column(
              children: [
                // Header with Profile title
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      // Profile title
                      Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            color: const Color(0xFF111418),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.015,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile picture and user info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile picture
                      AvatarWidget(
                        imageUrl: user.photoURL,
                        size: 80,
                        displayName: user.displayName ?? 'User',
                      ),

                      const SizedBox(height: 12),

                      // User name
                      Text(
                        user.displayName ?? 'Anonymous User',
                        style: TextStyle(
                          color: const Color(0xFF111418),
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
                        style: TextStyle(
                          color: const Color(0xFF60748A),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: const Color(0xFF111418),
                    unselectedLabelColor: const Color(0xFF60748A),
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: 'Profile'),
                      Tab(text: 'Notifications'),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Profile tab content
                      _buildProfileTab(),
                      // Notifications tab content
                      _buildNotificationsTab(),
                    ],
                  ),
                ),

                // Sign out button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minWidth: 84,
                      maxWidth: 480,
                    ),
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => context.read<AuthCubit>().signOut(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F2F5),
                        foregroundColor: const Color(0xFF111418),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.015,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom spacing
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Text(
        'Profile settings coming soon...',
        style: TextStyle(color: Color(0xFF60748A), fontSize: 16),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is NotificationLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NotificationError) {
          return ErrorState(
            message: state.message,
            textColor: const Color(0xFF60748A),
          );
        }

        if (state is NotificationLoaded) {
          if (state.notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Color(0xFF60748A), fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.notifications.length,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return NotificationItem(
                notification: notification,
                onTap: () => _handleNotificationTap(context, notification),
              );
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _handleNotificationTap(BuildContext context, notification) {
    final navigationService = sl<INavigationService>();
    navigationService.goToPostDetails(
      context,
      notification.postId,
      commentId: notification.commentId,
    );
  }
}
