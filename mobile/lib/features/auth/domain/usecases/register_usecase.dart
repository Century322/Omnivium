import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/i_auth_repository.dart';

class RegisterUseCase extends UseCase<User, RegisterParams> {
  final IAuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) {
    return _repository.register(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String? displayName;

  const RegisterParams({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}
