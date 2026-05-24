import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/core/services/deep_link_service.dart';
import 'package:state/service_locator.dart';
import 'package:state/core/configs/assets/app_vectors.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/core/constants/app_colors.dart';
import 'package:state/core/constants/quotes.dart';
import 'dart:math';
import 'package:state/features/legal/ui/terms_acceptance_dialog.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});
  static const double _authButtonWidth = 260;
  static const double _authButtonHeight = 48;
  static const String _betaVersionLabel = 'Beta - 1.0.5';

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
          final navigationService = sl<INavigationService>();

          // Check if there's a pending deep link from before authentication
          if (deepLinkService.hasPendingDeepLink()) {
            debugPrint(
              '🔐 [SIGN IN] Found pending deep link, will be handled after navigation to main',
            );
          }

          // Terms/EULA acceptance gate (post-auth)
          () async {
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                return;
              }
              final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              final hasAccepted = (doc.data()?['hasAcceptedTerms'] as bool?) ?? false;

              if (!context.mounted) return;
              if (!hasAccepted) {
                final accepted = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const TermsAcceptanceDialog(),
                );
                if (!context.mounted) return;
                if (accepted == true) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
                    {
                      'hasAcceptedTerms': true,
                      'acceptedTermsVersion': 1,
                      'acceptedAt': FieldValue.serverTimestamp(),
                    },
                    SetOptions(merge: true),
                  );
                  navigationService.goToMainScaffold(context);
                } else {
                  // User declined - sign out
                  context.read<AuthCubit>().signOut();
                }
              } else {
                navigationService.goToMainScaffold(context);
              }
            } catch (e) {
              // If anything fails, be safe and route to main
              if (!context.mounted) return;
              navigationService.goToMainScaffold(context);
            }
          }();
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
          body: Stack(
            children: [
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      children: [
                    // Main content - vertically centered
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Brand logo
                          SvgPicture.asset(
                            AppVectors.appLogo,
                            width: 96,
                            colorFilter: const ColorFilter.mode(
                              AppColors.primary,
                              BlendMode.srcIn,
                            ),
                          ),

                          const SizedBox(height: 32),

                          MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(textScaler: const TextScaler.linear(1.0)),
                            child: Column(
                              children: [
                                // Apple sign-in (iOS only) with availability check and official button
                                if (Platform.isIOS)
                                  FutureBuilder<bool>(
                                    future: SignInWithApple.isAvailable(),
                                    builder: (context, snapshot) {
                                      final available = snapshot.data == true;
                                      if (!available) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: SizedBox(
                                          width: _authButtonWidth,
                                          height: _authButtonHeight,
                                          child: SignInWithAppleButton(
                                            style: SignInWithAppleButtonStyle.black,
                                            onPressed:
                                                () => context
                                                    .read<AuthCubit>()
                                                    .signInWithApple(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                if (Platform.isIOS) const SizedBox(height: 12),

                                // Google sign in (same style)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: SizedBox(
                                    width: _authButtonWidth,
                                    height: _authButtonHeight,
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
                                          () => context
                                              .read<AuthCubit>()
                                              .signInWithGoogle(),
                                      icon: SvgPicture.asset(
                                        AppVectors.googleSignIn,
                                        width: 20,
                                        height: 20,
                                      ),
                                      label: const Text(
                                        'Sign in with Google',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
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

                          const SizedBox(height: 24),

                          // Subtle random quote
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              Quotes.signinQuotes[Random().nextInt(
                                Quotes.signinQuotes.length,
                              )],
                              style: const TextStyle(
                                color: Color(0xFF637488),
                                fontSize: 13,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                        // Bottom legal text
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'By continuing, you agree to our ',
                                style: TextStyle(
                                  color: Color(0xFF637488),
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              InkWell(
                                onTap:
                                    () => _launchUrl(
                                      'https://stateapp.net/terms-and-conditions',
                                      context,
                                    ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    'Terms of Service',
                                    style: TextStyle(
                                      color: Color(0xFF637488),
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                ' and ',
                                style: TextStyle(
                                  color: Color(0xFF637488),
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              InkWell(
                                onTap:
                                    () => _launchUrl(
                                      'https://stateapp.net/privacy-policy',
                                      context,
                                    ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      color: Color(0xFF637488),
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                '.',
                                style: TextStyle(
                                  color: Color(0xFF637488),
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),

                    const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(top: 0, right: 0, child: _SignInVersionBadge()),
            ],
          ),
        );
      },
    );
  }
}

class _SignInVersionBadge extends StatelessWidget {
  const _SignInVersionBadge();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 12),
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xE674182F),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              SignInScreen._betaVersionLabel,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
