import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:state/core/constants/routes.dart';
import 'package:state/core/widgets/main_scaffold.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/auth/ui/signin_screen.dart';
import 'package:state/features/following/ui/following_screen.dart';
import 'package:state/features/home/ui/home_screen.dart';
import 'package:state/features/postCreation/bloc/post_creation_cubit.dart';
import 'package:state/features/postCreation/ui/post_creation_screen.dart';
import 'package:state/features/postDetails/bloc/post_details_cubit.dart';
import 'package:state/features/postDetails/ui/post_details_screen.dart';
import 'package:state/features/splash/ui/splash_screen.dart';
import 'package:state/features/user/ui/user_screen.dart';
import 'package:state/features/userProfile/bloc/user_profile_cubit.dart';
import 'package:state/features/userProfile/ui/user_profile_screen.dart';
import 'package:state/features/search/bloc/search_cubit.dart';
import 'package:state/features/search/ui/search_screen.dart';
import 'package:state/features/notifications/ui/notifications_screen.dart';
import 'package:state/service_locator.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,

    // Route guards and redirects
    redirect: (context, state) {
      debugPrint('🚦 [ROUTER] Redirect called');
      debugPrint('🚦 [ROUTER] Full location: ${state.uri}');
      debugPrint('🚦 [ROUTER] Matched location: ${state.matchedLocation}');
      debugPrint('🚦 [ROUTER] Path: ${state.uri.path}');
      debugPrint('🚦 [ROUTER] Path parameters: ${state.pathParameters}');

      final authCubit = context.read<AuthCubit>();
      final authState = authCubit.state;
      debugPrint('🚦 [ROUTER] Auth state: ${authState.runtimeType}');

      // Handle authentication redirects
      if (state.matchedLocation == Routes.signin &&
          authState is Authenticated) {
        debugPrint(
          '🚦 [ROUTER] Redirecting from signin to main (already authenticated)',
        );
        return Routes.main;
      }

      // Allow post details, user profile, and shared post routes without authentication
      // (for deep links from notifications and shares)
      if (state.matchedLocation.startsWith(Routes.postDetails) ||
          state.matchedLocation.startsWith(Routes.userProfile) ||
          state.matchedLocation.startsWith('/post/')) {
        debugPrint('🚦 [ROUTER] Allowing access to: ${state.matchedLocation}');
        return null; // Allow access
      }

      if (state.matchedLocation.startsWith(Routes.main) &&
          authState is Unauthenticated) {
        debugPrint('🚦 [ROUTER] Redirecting to signin (unauthenticated)');
        return Routes.signin;
      }

      debugPrint('🚦 [ROUTER] No redirect needed');
      return null; // No redirect needed
    },

    // Error handling
    errorBuilder: (context, state) {
      debugPrint('❌ [ROUTER ERROR] Error builder called!');
      debugPrint('❌ [ROUTER ERROR] Full URI: ${state.uri}');
      debugPrint('❌ [ROUTER ERROR] Matched location: ${state.matchedLocation}');
      debugPrint('❌ [ROUTER ERROR] Path: ${state.uri.path}');
      debugPrint('❌ [ROUTER ERROR] Path parameters: ${state.pathParameters}');
      debugPrint(
        '❌ [ROUTER ERROR] Query parameters: ${state.uri.queryParameters}',
      );
      debugPrint('❌ [ROUTER ERROR] Error: ${state.error}');

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'The page "${state.matchedLocation}" does not exist.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(Routes.splash),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },

    routes: [
      // Splash route
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication route
      GoRoute(
        path: Routes.signin,
        name: 'signin',
        builder: (context, state) => const SignInScreen(),
      ),

      // Main app with nested routes
      GoRoute(
        path: Routes.main,
        name: 'main',
        builder: (context, state) => const MainScaffold(),
        routes: [
          // Home tab
          GoRoute(
            path: Routes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Following tab
          GoRoute(
            path: Routes.following,
            name: 'following',
            builder: (context, state) => const FollowingScreen(),
          ),

          // Notifications tab
          GoRoute(
            path: Routes.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),

          // User tab
          GoRoute(
            path: Routes.user,
            name: 'user',
            builder: (context, state) => const UserScreen(),
          ),
        ],
      ),

      // Modal routes (fullscreen dialogs)
      GoRoute(
        path: Routes.postCreation,
        name: 'postCreation',
        pageBuilder:
            (context, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: BlocProvider<PostCreationCubit>(
                create: (_) => sl<PostCreationCubit>(),
                child: const PostCreationScreen(),
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeInOut)),
                  ),
                  child: child,
                );
              },
            ),
      ),

      // Post details route with parameter
      GoRoute(
        path: '${Routes.postDetails}/:postId',
        name: 'postDetails',
        builder: (context, state) {
          debugPrint('📄 [POST DETAILS ROUTE] Building post details screen');
          debugPrint(
            '📄 [POST DETAILS ROUTE] Path parameters: ${state.pathParameters}',
          );
          debugPrint('📄 [POST DETAILS ROUTE] Full URI: ${state.uri}');

          final postId = state.pathParameters['postId']!;
          final commentId = state.uri.queryParameters['commentId'];

          debugPrint('📄 [POST DETAILS ROUTE] Post ID: $postId');
          debugPrint('📄 [POST DETAILS ROUTE] Comment ID: $commentId');

          return BlocProvider<PostDetailsCubit>(
            create: (_) => sl<PostDetailsCubit>(),
            child: PostDetailsScreen(postId: postId, commentId: commentId),
          );
        },
      ),

      // User profile route with parameter
      GoRoute(
        path: '${Routes.userProfile}/:userId',
        name: 'userProfile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return BlocProvider<UserProfileCubit>(
            create: (_) => sl<UserProfileCubit>(),
            child: UserProfileScreen(userId: userId),
          );
        },
      ),

      // Search route
      GoRoute(
        path: Routes.search,
        name: 'search',
        builder: (context, state) {
          return BlocProvider<SearchCubit>(
            create: (_) => sl<SearchCubit>(),
            child: const SearchScreen(),
          );
        },
      ),

      // Shared post route - redirect to main (pending deep link will be handled there)
      GoRoute(
        path: '/post/:postId',
        name: 'sharedPost',
        redirect: (context, state) {
          debugPrint('📮 [SHARED POST ROUTE] Matched /post/:postId route');
          debugPrint('📮 [SHARED POST ROUTE] Full URI: ${state.uri}');
          debugPrint(
            '📮 [SHARED POST ROUTE] Path parameters: ${state.pathParameters}',
          );
          debugPrint(
            '📮 [SHARED POST ROUTE] Post ID: ${state.pathParameters['postId']}',
          );
          debugPrint('📮 [SHARED POST ROUTE] Redirecting to: /main');
          return '/main';
        },
      ),

      // Catch-all route for custom scheme deep links (stateapp://post/ID)
      // When app_links receives stateapp://post/ID, GoRouter sees path as /:postId
      // This route catches those and redirects to main, letting DeepLinkService handle navigation
      GoRoute(
        path: '/:postId',
        name: 'customSchemePost',
        redirect: (context, state) {
          final postId = state.pathParameters['postId'];
          debugPrint('🔗 [CUSTOM SCHEME ROUTE] Matched /:postId route');
          debugPrint('🔗 [CUSTOM SCHEME ROUTE] Full URI: ${state.uri}');
          debugPrint('🔗 [CUSTOM SCHEME ROUTE] Post ID: $postId');

          // Check if this looks like a post ID (not a regular route)
          // Regular routes start with specific paths like /splash, /signin, /main
          final knownRoutes = [
            'splash',
            'signin',
            'main',
            'post-creation',
            'post-details',
            'user-profile',
            'search',
          ];

          if (postId != null && !knownRoutes.contains(postId)) {
            debugPrint(
              '🔗 [CUSTOM SCHEME ROUTE] Detected deep link post ID, redirecting to /main',
            );
            // Let DeepLinkService handle the actual navigation
            return '/main';
          }

          debugPrint('🔗 [CUSTOM SCHEME ROUTE] Not a deep link, no redirect');
          return null;
        },
      ),
    ],
  );

  /// Get the router instance
  static GoRouter get router => _router;

  /// Navigation methods using GoRouter
  static Future<void> goToMainScaffold(BuildContext context) async {
    context.go(Routes.main);
  }

  static Future<void> goToSignIn(BuildContext context) async {
    context.go(Routes.signin);
  }

  static Future<bool?> goToPostCreation(BuildContext context) async {
    final result = await context.push<bool>(Routes.postCreation);
    return result;
  }

  static Future<void> goToPostDetails(
    BuildContext context,
    String postId, {
    String? commentId,
  }) async {
    String path = '${Routes.postDetails}/$postId';
    if (commentId != null && commentId.isNotEmpty) {
      path += '?commentId=$commentId';
    }
    context.push(path);
  }

  static void goToUserProfile(BuildContext context, String userId) {
    context.push('${Routes.userProfile}/$userId');
  }

  static void goToSearch(BuildContext context) {
    context.push(Routes.search);
  }

  /// Tab navigation methods
  static void goToHomeTab(BuildContext context) {
    context.go('${Routes.main}${Routes.home}');
  }

  static void goToFollowingTab(BuildContext context) {
    context.go('${Routes.main}${Routes.following}');
  }

  static void goToNotificationsTab(BuildContext context) {
    context.go('${Routes.main}${Routes.notifications}');
  }

  static void goToUserTab(BuildContext context) {
    context.go('${Routes.main}${Routes.user}');
  }

  /// Utility navigation methods
  static void pop<T>(BuildContext context, [T? result]) {
    context.pop(result);
  }

  static void popUntilRoot(BuildContext context) {
    context.go(Routes.splash);
  }

  static void popUntil(BuildContext context, String routeName) {
    context.go(routeName);
  }

  /// Deep linking support
  static void handleDeepLink(String path) {
    _router.go(path);
  }

  /// Check if current route matches
  static bool isCurrentRoute(BuildContext context, String route) {
    return GoRouterState.of(context).matchedLocation == route;
  }

  /// Get current route location
  static String getCurrentLocation(BuildContext context) {
    return GoRouterState.of(context).matchedLocation;
  }
}
