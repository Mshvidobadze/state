import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/core/widgets/bottom_nav_bar.dart';
import 'package:state/features/following/ui/following_screen.dart';
import 'package:state/features/home/ui/home_screen.dart';
import 'package:state/features/user/ui/user_screen.dart';
import 'package:state/features/notifications/bloc/notification_cubit.dart';
import 'package:state/features/notifications/bloc/notification_state.dart';
import 'package:state/features/notifications/ui/notifications_screen.dart';
import 'package:state/service_locator.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // GlobalKeys to access state of each screen for scroll-to-top functionality
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey();
  final GlobalKey<FollowingScreenState> _followingKey = GlobalKey();
  final GlobalKey<NotificationsScreenState> _notificationsKey = GlobalKey();

  void _onTabTapped(int index) {
    // If tapping the same tab, scroll to top and refresh
    if (_currentIndex == index) {
      _scrollToTopAndRefresh(index);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _scrollToTopAndRefresh(int index) {
    switch (index) {
      case 0: // Home
        _homeKey.currentState?.scrollToTopAndRefresh();
        break;
      case 1: // Following
        _followingKey.currentState?.scrollToTopAndRefresh();
        break;
      case 2: // Notifications
        _notificationsKey.currentState?.scrollToTopAndRefresh();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<NotificationCubit>()..loadNotifications(),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(key: _homeKey), // Home screen - preserved
            FollowingScreen(key: _followingKey), // Following screen
            NotificationsScreen(key: _notificationsKey), // Notifications screen
            const UserScreen(), // User screen - always reloads
          ],
        ),
        bottomNavigationBar:
            Platform.isAndroid
                ? SafeArea(
                  // Prevent Android system navigation bar overlap (only on Android)
                  child: BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, state) {
                      final unreadCount =
                          state is NotificationLoaded ? state.unreadCount : 0;
                      return BottomNavBar(
                        currentIndex: _currentIndex,
                        onTap: _onTabTapped,
                        unreadNotifications: unreadCount,
                      );
                    },
                  ),
                )
                : BlocBuilder<NotificationCubit, NotificationState>(
                  builder: (context, state) {
                    final unreadCount =
                        state is NotificationLoaded ? state.unreadCount : 0;
                    return BottomNavBar(
                      currentIndex: _currentIndex,
                      onTap: _onTabTapped,
                      unreadNotifications: unreadCount,
                    );
                  },
                ),
      ),
    );
  }
}
