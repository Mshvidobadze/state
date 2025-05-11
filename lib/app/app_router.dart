import 'package:flutter/material.dart';
import 'package:state/core/constants/routes.dart';
import 'package:state/core/widgets/main_scaffold.dart';

class AppRouter {
  static void goToMainScaffold(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScaffold()),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.home:
      case Routes.following:
      case Routes.user:
        return MaterialPageRoute(builder: (_) => const MainScaffold());
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text('No route defined'))),
        );
    }
  }
}
