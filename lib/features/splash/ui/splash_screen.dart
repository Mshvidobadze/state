import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:state/core/services/navigation_service.dart';
import 'package:state/service_locator.dart';
import 'package:state/core/configs/assets/app_vectors.dart';
import 'package:state/features/splash/bloc/splash_cubit.dart';
import 'package:state/features/splash/bloc/splash_state.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        final navigationService = sl<INavigationService>();
        if (state is Unauthenticated) {
          navigationService.goToSignIn(context);
        } else if (state is Authenticated) {
          navigationService.goToMainScaffold(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SvgPicture.asset(
            AppVectors.appLogo,
            width: 192,
            height: 192,
            colorFilter: ColorFilter.mode(Color(0xFF800020), BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
