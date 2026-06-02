import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final sp.SupabaseClient _supabase;
  final AuthLocalDataSource _localDataSource;
  late final StreamController<AuthStateChange> _authStateController;

  AuthRepositoryImpl({
    required sp.SupabaseClient supabase,
    required AuthLocalDataSource localDataSource,
  })  : _supabase = supabase,
        _localDataSource = localDataSource {
    _authStateController = StreamController<AuthStateChange>.broadcast();
    _supabase.auth.onAuthStateChange.listen(_onSupabaseAuthChange);
  }

  void _onSupabaseAuthChange(sp.AuthState event) {
    final change = _mapAuthState(event);
    if (change != null && !_authStateController.isClosed) {
      _authStateController.add(change);
    }
  }

  AuthStateChange? _mapAuthState(sp.AuthState event) {
    switch (event.event) {
      case sp.AuthChangeEvent.signedIn:
        final user = _mapSupabaseUser(event.session?.user);
        final session = _mapSupabaseSession(event.session);
        _persistAuth(user, session);
        return AuthStateChange(
          type: AuthStateChangeType.signedIn,
          user: user,
          session: session,
        );
      case sp.AuthChangeEvent.signedOut:
        _clearAuth();
        return const AuthStateChange(type: AuthStateChangeType.signedOut);
      case sp.AuthChangeEvent.tokenRefreshed:
        final session = _mapSupabaseSession(event.session);
        if (session != null) {
          _localDataSource.saveSession(session);
        }
        return AuthStateChange(
          type: AuthStateChangeType.tokenRefreshed,
          session: session,
        );
      case sp.AuthChangeEvent.userUpdated:
        final user = _mapSupabaseUser(event.session?.user);
        if (user != null) {
          _localDataSource.saveUser(user);
        }
        return AuthStateChange(
          type: AuthStateChangeType.userUpdated,
          user: user,
        );
      default:
        return null;
    }
  }

  User? _mapSupabaseUser(sp.User? supabaseUser) {
    if (supabaseUser == null) return null;
    final meta = supabaseUser.userMetadata;
    return User(
      id: supabaseUser.id,
      username: meta?['username'] as String? ?? supabaseUser.email?.split('@').first ?? '',
      email: supabaseUser.email,
      displayName: meta?['display_name'] as String?,
      avatarUrl: meta?['avatar_url'] as String?,
      matrixId: meta?['matrix_user_id'] as String?,
      did: meta?['did'] as String?,
      trustLevel: meta?['trust_level'] as int? ?? 0,
      createdAt: DateTime.parse(supabaseUser.createdAt),
    );
  }

  Session? _mapSupabaseSession(sp.Session? supabaseSession) {
    if (supabaseSession == null) return null;
    return Session(
      accessToken: supabaseSession.accessToken,
      refreshToken: supabaseSession.refreshToken ?? '',
      deviceId: supabaseSession.user?.id ?? '',
      userId: supabaseSession.user?.id ?? '',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (supabaseSession.expiresAt ?? 0) * 1000,
      ),
    );
  }

  Future<void> _persistAuth(User? user, Session? session) async {
    if (user != null) await _localDataSource.saveUser(user);
    if (session != null) await _localDataSource.saveSession(session);
  }

  Future<void> _clearAuth() async {
    await _localDataSource.clearSession();
    await _localDataSource.clearUser();
  }

  Future<void> _provisionMatrixAccount() async {
    final accessToken = _supabase.auth.currentSession?.accessToken;
    if (accessToken == null) return;
    try {
      final uri = Uri.parse('https://api.omnivium.app/auth/matrix-auto-provision');
      await http.post(uri, headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  @override
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = _mapSupabaseUser(response.user);
      final session = _mapSupabaseSession(response.session);
      await _persistAuth(user, session);
      if (user == null) {
        return const Left(ServerFailure(message: 'Login succeeded but user is null'));
      }
      await _provisionMatrixAccount();
      return Right(user);
    } on sp.AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        sp.OAuthProvider.google,
      );
      if (!response) {
        return const Left(ServerFailure(message: 'Google sign-in was cancelled'));
      }
      final currentUser = _supabase.auth.currentUser;
      final user = _mapSupabaseUser(currentUser);
      final session = _mapSupabaseSession(_supabase.auth.currentSession);
      await _persistAuth(user, session);
      if (user == null) {
        return const Left(ServerFailure(message: 'Google sign-in succeeded but user is null'));
      }
      await _provisionMatrixAccount();
      return Right(user);
    } on sp.AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithApple() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        sp.OAuthProvider.apple,
      );
      if (!response) {
        return const Left(ServerFailure(message: 'Apple sign-in was cancelled'));
      }
      final currentUser = _supabase.auth.currentUser;
      final user = _mapSupabaseUser(currentUser);
      final session = _mapSupabaseSession(_supabase.auth.currentSession);
      await _persistAuth(user, session);
      if (user == null) {
        return const Left(ServerFailure(message: 'Apple sign-in succeeded but user is null'));
      }
      await _provisionMatrixAccount();
      return Right(user);
    } on sp.AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          if (displayName != null) 'display_name': displayName,
        },
      );
      final user = _mapSupabaseUser(response.user);
      final session = _mapSupabaseSession(response.session);
      await _persistAuth(user, session);
      if (user == null) {
        return const Left(ServerFailure(message: 'Registration succeeded but user is null'));
      }
      await _provisionMatrixAccount();
      return Right(user);
    } on sp.AuthException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Session>> restoreSession() async {
    try {
      final currentSession = _supabase.auth.currentSession;
      if (currentSession != null) {
        final session = _mapSupabaseSession(currentSession);
        if (session != null && !session.isExpired) {
          return Right(session);
        }
      }
      final localSession = await _localDataSource.getSession();
      if (localSession == null) {
        return const Left(CacheFailure(message: 'No session found'));
      }
      return Right(localSession);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    await _clearAuth();
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser != null) {
        return Right(_mapSupabaseUser(supabaseUser)!);
      }
      final localUser = await _localDataSource.getUser();
      if (localUser == null) {
        return const Left(CacheFailure(message: 'No user found'));
      }
      return Right(localUser);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final session = _supabase.auth.currentSession;
    if (session != null && !session.isExpired) return true;
    final localSession = await _localDataSource.getSession();
    return localSession != null && !localSession.isExpired;
  }

  @override
  Stream<AuthStateChange> get onAuthStateChange => _authStateController.stream;
}
