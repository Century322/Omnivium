import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../entities/session.dart';

abstract class IAuthRepository {
  Future<Either<Failure, User>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> loginWithGoogle();

  Future<Either<Failure, User>> loginWithApple();

  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    String? displayName,
  });

  Future<Either<Failure, Session>> restoreSession();

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, User>> getCurrentUser();

  Future<bool> isLoggedIn();

  Stream<AuthStateChange> get onAuthStateChange;
}

enum AuthStateChangeType { signedIn, signedOut, tokenRefreshed, userUpdated }

class AuthStateChange {
  final AuthStateChangeType type;
  final User? user;
  final Session? session;

  const AuthStateChange({
    required this.type,
    this.user,
    this.session,
  });
}
