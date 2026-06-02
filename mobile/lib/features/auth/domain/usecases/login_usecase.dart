import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/i_auth_repository.dart';

class LoginWithEmailUseCase extends UseCase<User, EmailLoginParams> {
  final IAuthRepository _repository;

  LoginWithEmailUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(EmailLoginParams params) {
    return _repository.loginWithEmail(email: params.email, password: params.password);
  }
}

class LoginWithGoogleUseCase extends UseCase<User, NoParams> {
  final IAuthRepository _repository;

  LoginWithGoogleUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) {
    return _repository.loginWithGoogle();
  }
}

class LoginWithAppleUseCase extends UseCase<User, NoParams> {
  final IAuthRepository _repository;

  LoginWithAppleUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) {
    return _repository.loginWithApple();
  }
}

class EmailLoginParams extends Equatable {
  final String email;
  final String password;

  const EmailLoginParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
