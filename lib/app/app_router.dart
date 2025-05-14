import 'package:flutter/material.dart';
import 'package:state/core/constants/routes.dart';
import 'package:state/core/widgets/main_scaffold.dart';
import 'package:state/features/auth/ui/signin_screen.dart';
import 'package:state/features/splash/ui/splash_screen.dart';

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

  // static void push(BuildContext context) {
  // Navigator.push(
  // context,
  // MaterialPageRoute(builder: (_) => const SignInScreen()),
  // );
  // }

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
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('No route defined'))),
        );
    }
  }
}
