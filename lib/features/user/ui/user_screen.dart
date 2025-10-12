import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:state/core/widgets/avatar_widget.dart';
import 'package:state/core/widgets/fullscreen_image_viewer.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/service_locator.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

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
                  child: const Row(
                    children: [
                      // Profile title
                      Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            color: Color(0xFF111418),
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
                      // Profile picture - tappable for fullscreen view
                      GestureDetector(
                        onTap: () {
                          if (user.photoURL != null &&
                              user.photoURL!.isNotEmpty) {
                            FullscreenImageViewer.show(
                              context,
                              imageUrl: user.photoURL!,
                              heroTag: 'user-avatar-${user.uid}',
                            );
                          }
                        },
                        child: Hero(
                          tag: 'user-avatar-${user.uid}',
                          child: AvatarWidget(
                            imageUrl: user.photoURL,
                            size: 80,
                            displayName: user.displayName ?? 'User',
                          ),
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

                const Spacer(),

                // Sign out button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: SizedBox(
                    width: double.infinity,
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
                      child: const Text(
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
}
