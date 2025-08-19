import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/core/constants/routes.dart';
import 'package:state/core/widgets/main_scaffold.dart';
import 'package:state/features/auth/ui/signin_screen.dart';
import 'package:state/features/postCreation/bloc/post_creation_cubit.dart';
import 'package:state/features/postCreation/ui/post_creation_screen.dart';
import 'package:state/features/postDetails/bloc/post_details_cubit.dart';
import 'package:state/features/postDetails/ui/post_details_screen.dart';
import 'package:state/features/splash/ui/splash_screen.dart';
import 'package:state/service_locator.dart';

class AppRouter {
  static void goToMainScaffold(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScaffold()),
    );
  }

  static void goToSignIn(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  static Future<bool?> goToPostCreation(BuildContext context) async {
    return Navigator.pushNamed(context, Routes.postCreation);
  }

  static Future<void> goToPostDetails(
    BuildContext context,
    String postId,
  ) async {
    await Navigator.pushNamed(context, Routes.postDetails, arguments: postId);
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
      case Routes.following:
      case Routes.user:
        return MaterialPageRoute(builder: (_) => const MainScaffold());
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case Routes.signin:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case Routes.postCreation:
        return MaterialPageRoute<bool?>(
          builder:
              (_) => BlocProvider<PostCreationCubit>(
                create: (_) => sl<PostCreationCubit>(),
                child: const PostCreationScreen(),
              ),
        );
      case Routes.postDetails:
        final postId = settings.arguments as String;
        return MaterialPageRoute(
          builder:
              (_) => BlocProvider<PostDetailsCubit>(
                create: (_) => sl<PostDetailsCubit>(),
                child: PostDetailsScreen(postId: postId),
              ),
        );
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('No route defined'))),
        );
    }
  }
}
