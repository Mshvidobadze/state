import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadNotifications;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadNotifications = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: 'Following',
        ),
        BottomNavigationBarItem(
          icon: _buildNotificationIcon(),
          label: 'Notifications',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
      ],
    );
  }

  Widget _buildNotificationIcon() {
    if (unreadNotifications > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }
    return const Icon(Icons.notifications);
  }
}
