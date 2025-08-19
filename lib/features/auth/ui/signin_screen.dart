import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:state/app/app_router.dart';
import 'package:state/core/configs/assets/app_vectors.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          AppRouter.goToMainScaffold(context);
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Main content - vertically centered
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // State title - much bigger
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'State',
                          style: TextStyle(
                            color: const Color(0xFF111418),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.015,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Plato quote - much smaller
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'The punishment which the wise suffer who refuse to take part in the government, is to live under the government of worse men.',
                          style: TextStyle(
                            color: const Color(0xFF111418),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Plato attribution
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 32),
                        child: Text(
                          '- Plato',
                          style: TextStyle(
                            color: const Color(0xFF637488),
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Original SVG sign in button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap:
                              () =>
                                  context.read<AuthCubit>().signInWithGoogle(),
                          child: SvgPicture.asset(
                            AppVectors.googleSignIn,
                            width: 220,
                            height: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom legal text
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy.',
                    style: TextStyle(
                      color: const Color(0xFF637488),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
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
