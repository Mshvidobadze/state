import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/splash/bloc/splash_state.dart';
import 'package:state/features/auth/domain/auth_repository.dart';

class SplashCubit extends Cubit<SplashState> {
  final AuthRepository authRepository;

  SplashCubit(this.authRepository) : super(DisplaySplash());

  void appStarted() async {
    await Future.delayed(const Duration(seconds: 1));
    final isSignedIn = await authRepository.isSignedIn();
    emit(isSignedIn ? Authenticated() : Unauthenticated());
  }
}
