import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/app/app_router.dart';
import 'package:state/core/constants/routes.dart';
import 'package:state/features/auth/bloc/auth_cubit.dart';
import 'package:state/features/splash/bloc/splash_cubit.dart';
import 'package:state/features/home/bloc/home_cubit.dart';
import 'package:state/service_locator.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<SplashCubit>()..appStarted()),
        BlocProvider(create: (_) => sl<AuthCubit>()),
        BlocProvider(create: (_) => sl<HomeCubit>()),
      ],
      child: MaterialApp(
        title: 'State',
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
