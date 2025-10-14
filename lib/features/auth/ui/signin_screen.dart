import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/core/services/deep_link_service.dart';
import 'package:state/service_locator.dart';
import 'package:state/core/configs/assets/app_vectors.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/core/constants/quotes.dart';
import 'dart:math';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          debugPrint('🔐 [SIGN IN] User authenticated successfully');
          final deepLinkService = sl<DeepLinkService>();

          // Check if there's a pending deep link from before authentication
          if (deepLinkService.hasPendingDeepLink()) {
            debugPrint(
              '🔐 [SIGN IN] Found pending deep link, will be handled after navigation to main',
            );
          }

          final navigationService = sl<INavigationService>();
          navigationService.goToMainScaffold(context);
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

                      // Random quote - much smaller
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          Quotes.signinQuotes[Random().nextInt(
                            Quotes.signinQuotes.length,
                          )],
                          style: TextStyle(
                            color: const Color(0xFF111418),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Apple sign-in (iOS only)
                      if (Platform.isIOS)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: 220,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF111418),
                                elevation: 0,
                                side: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed:
                                  () =>
                                      context
                                          .read<AuthCubit>()
                                          .signInWithApple(),
                              icon: const Icon(
                                Icons.apple,
                                size: 20,
                                color: Color(0xFF111418),
                              ),
                              label: const Text(
                                'Sign in with Apple',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.015,
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (Platform.isIOS) const SizedBox(height: 12),

                      // Google sign in button (match Apple styling, use SVG icon)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 220,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF111418),
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed:
                                () =>
                                    context
                                        .read<AuthCubit>()
                                        .signInWithGoogle(),
                            icon: SvgPicture.asset(
                              AppVectors.googleSignIn,
                              width: 20,
                              height: 20,
                            ),
                            label: const Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.015,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom legal text
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: const Color(0xFF637488),
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      children: [
                        const TextSpan(
                          text: 'By continuing, you agree to our ',
                        ),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap:
                                () => _launchUrl(
                                  'https://stateapp.net/terms-and-conditions',
                                  context,
                                ),
                            child: Text(
                              'Terms of Service',
                              style: TextStyle(
                                color: const Color(0xFF637488),
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap:
                                () => _launchUrl(
                                  'https://stateapp.net/privacy-policy',
                                  context,
                                ),
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: const Color(0xFF637488),
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
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
