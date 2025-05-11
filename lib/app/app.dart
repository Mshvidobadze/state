import 'package:flutter/material.dart';
import 'package:state/app/app_router.dart';
import 'package:state/core/widgets/main_scaffold.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'State',
      initialRoute: '/home',
      onGenerateRoute: AppRouter.generateRoute,
      home: const MainScaffold(),
    );
  }
}
