import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/features/auth/bloc/auth_state.dart';
import 'package:state/features/auth/domain/auth_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  final FirebaseAuth _firebaseAuth;

  AuthCubit(this.authRepository, this._firebaseAuth) : super(AuthInitial());

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      await authRepository.signInWithGoogle();
      await authRepository.createUserEntry();
      emit(
        Authenticated(
          userId: _firebaseAuth.currentUser?.uid ?? '',
          userName: _firebaseAuth.currentUser?.displayName ?? '',
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    emit(Unauthenticated());
  }

  Future<void> checkAuthStatus() async {
    final isSignedIn = await authRepository.isSignedIn();
    emit(
      isSignedIn
          ? Authenticated(
            userId: _firebaseAuth.currentUser?.uid ?? '',
            userName: _firebaseAuth.currentUser?.displayName ?? '',
          )
          : Unauthenticated(),
    );
  }
}
