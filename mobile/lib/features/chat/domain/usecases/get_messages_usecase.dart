import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/i_chat_repository.dart';

class GetMessagesUseCase extends UseCase<List<ChatMessage>, GetMessagesParams> {
  final IChatRepository _repository;

  GetMessagesUseCase(this._repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(GetMessagesParams params) {
    return _repository.getMessages(params.roomId, limit: params.limit, fromToken: params.fromToken);
  }
}

class GetMessagesParams extends Equatable {
  final String roomId;
  final int limit;
  final String? fromToken;

  const GetMessagesParams({required this.roomId, this.limit = 50, this.fromToken});

  @override
  List<Object?> get props => [roomId, limit, fromToken];
}
