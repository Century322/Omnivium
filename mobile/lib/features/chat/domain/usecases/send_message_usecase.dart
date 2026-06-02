import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/chat_message.dart';
import '../repositories/i_chat_repository.dart';

class SendMessageUseCase extends UseCase<ChatMessage, SendMessageParams> {
  final IChatRepository _repository;

  SendMessageUseCase(this._repository);

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) {
    return _repository.sendMessage(params.roomId, params.text, replyToId: params.replyToId);
  }
}

class SendMessageParams extends Equatable {
  final String roomId;
  final String text;
  final String? replyToId;

  const SendMessageParams({required this.roomId, required this.text, this.replyToId});

  @override
  List<Object?> get props => [roomId, text, replyToId];
}
