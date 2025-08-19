import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/app/app_router.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          AppRouter.goToSignIn(context);
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

                // Main profile content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Profile picture and user info
                        Column(
                          children: [
                            // Profile picture
                            Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF0F2F5),
                              ),
                              child:
                                  user.photoURL != null
                                      ? ClipOval(
                                        child: Image.network(
                                          user.photoURL!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Icon(
                                              Icons.person,
                                              size: 64,
                                              color: const Color(0xFF60748A),
                                            );
                                          },
                                        ),
                                      )
                                      : Icon(
                                        Icons.person,
                                        size: 64,
                                        color: const Color(0xFF60748A),
                                      ),
                            ),

                            const SizedBox(height: 16),

                            // User name
                            Text(
                              user.displayName ?? 'Anonymous User',
                              style: TextStyle(
                                color: const Color(0xFF111418),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.015,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),

                            // User email
                            Text(
                              user.email ?? 'No email',
                              style: TextStyle(
                                color: const Color(0xFF60748A),
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
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
}
