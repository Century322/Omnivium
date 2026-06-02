import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';
import '../entities/chat_room.dart';
import '../models/unified_message.dart';

abstract class IChatRepository {
  Future<Either<Failure, List<ChatRoom>>> getRooms();
  Future<Either<Failure, List<ChatMessage>>> getMessages(String roomId, {int limit, String? fromToken});
  Future<Either<Failure, ChatMessage>> sendMessage(String roomId, String text, {String? replyToId});
  Future<Either<Failure, void>> sendImage(String roomId, String filePath, String fileName);
  Future<Either<Failure, void>> sendFile(String roomId, String filePath, String fileName);
  Future<Either<Failure, void>> sendVoiceMessage(String roomId, String filePath, int duration);
  Future<Either<Failure, void>> recallMessage(String roomId, String eventId);
  Future<Either<Failure, void>> editMessage(String roomId, String eventId, String newContent);
  Future<Either<Failure, ChatRoom>> createDirectChat(String userId);
  Future<Either<Failure, ChatRoom>> createGroupChat(String name, {List<String>? userIds, String? topic});
  Future<Either<Failure, void>> markAsRead(String roomId);
  Future<Either<Failure, void>> sendTyping(String roomId, {required bool isTyping});
  Stream<ChatMessage> get onNewMessage;
  Stream<String> get onTyping;

  Stream<UnifiedMessage> sendAiMessage(String content, String modelId, {double temperature, int maxTokens});
  Future<Either<Failure, void>> stopAiGeneration();
}
