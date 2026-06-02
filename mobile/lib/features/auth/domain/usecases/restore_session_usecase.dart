import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/session.dart';
import '../repositories/i_auth_repository.dart';

class RestoreSessionUseCase extends UseCase<Session, NoParams> {
  final IAuthRepository _repository;

  RestoreSessionUseCase(this._repository);

  @override
  Future<Either<Failure, Session>> call(NoParams params) {
    return _repository.restoreSession();
  }
}
