import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthRepository _authRepository;
  StreamSubscription<AuthStateChange>? _authStateSubscription;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthEmailLoginRequested>(_onEmailLogin);
    on<AuthGoogleLoginRequested>(_onGoogleLogin);
    on<AuthAppleLoginRequested>(_onAppleLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthSessionRestoreRequested>(_onRestoreSession);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthStatusChecked>(_onStatusCheck);

    _authStateSubscription = _authRepository.onAuthStateChange.listen((change) {
      switch (change.type) {
        case AuthStateChangeType.signedIn:
          if (change.user != null) {
            add(const AuthStatusChecked());
          }
        case AuthStateChangeType.signedOut:
          add(const AuthStatusChecked());
        case AuthStateChangeType.tokenRefreshed:
          break;
        case AuthStateChangeType.userUpdated:
          if (change.user != null) {
            emit(AuthAuthenticated(change.user!));
          }
      }
    });
  }

  Future<void> _onEmailLogin(
    AuthEmailLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.loginWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onGoogleLogin(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.loginWithGoogle();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAppleLogin(
    AuthAppleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.loginWithApple();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.register(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onRestoreSession(
    AuthSessionRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.restoreSession();
    await result.fold(
      (failure) async {
        final userResult = await _authRepository.getCurrentUser();
        userResult.fold(
          (_) => emit(const AuthUnauthenticated()),
          (user) => emit(AuthAuthenticated(user)),
        );
      },
      (session) async {
        final userResult = await _authRepository.getCurrentUser();
        userResult.fold(
          (_) => emit(const AuthUnauthenticated()),
          (user) => emit(AuthAuthenticated(user)),
        );
      },
    );
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onStatusCheck(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await _authRepository.isLoggedIn();
    if (isLoggedIn) {
      final userResult = await _authRepository.getCurrentUser();
      userResult.fold(
        (_) => emit(const AuthUnauthenticated()),
        (user) => emit(AuthAuthenticated(user)),
      );
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
