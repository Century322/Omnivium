import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_room.dart';
import '../repositories/i_chat_repository.dart';

class GetRoomsUseCase extends UseCase<List<ChatRoom>, NoParams> {
  final IChatRepository _repository;

  GetRoomsUseCase(this._repository);

  @override
  Future<Either<Failure, List<ChatRoom>>> call(NoParams params) {
    return _repository.getRooms();
  }
}
