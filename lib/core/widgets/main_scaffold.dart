import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/core/widgets/bottom_nav_bar.dart';
import 'package:state/features/following/ui/following_screen.dart';
import 'package:state/features/home/ui/home_screen.dart';
import 'package:state/features/user/ui/user_screen.dart';
import 'package:state/features/notifications/bloc/notification_cubit.dart';
import 'package:state/service_locator.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Home screen is kept alive, others are recreated
  final Widget _homeScreen = const HomeScreen();

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<NotificationCubit>(),
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _homeScreen, // Home screen - preserved
            const FollowingScreen(), // Following screen - always reloads
            const UserScreen(), // User screen - always reloads
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
