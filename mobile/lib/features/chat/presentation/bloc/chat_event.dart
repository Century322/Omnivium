import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatRoomsLoadRequested extends ChatEvent {
  const ChatRoomsLoadRequested();
}

class ChatRoomSelected extends ChatEvent {
  final String roomId;
  const ChatRoomSelected(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class ChatMessagesLoadRequested extends ChatEvent {
  final String roomId;
  final int limit;
  final String? fromToken;
  const ChatMessagesLoadRequested(this.roomId, {this.limit = 50, this.fromToken});
  @override
  List<Object?> get props => [roomId, limit, fromToken];
}

class ChatMessageSent extends ChatEvent {
  final String roomId;
  final String text;
  final String? replyToId;
  const ChatMessageSent({required this.roomId, required this.text, this.replyToId});
  @override
  List<Object?> get props => [roomId, text, replyToId];
}

class ChatImageSent extends ChatEvent {
  final String roomId;
  final String filePath;
  final String fileName;
  const ChatImageSent({required this.roomId, required this.filePath, required this.fileName});
  @override
  List<Object?> get props => [roomId, filePath, fileName];
}

class ChatFileSent extends ChatEvent {
  final String roomId;
  final String filePath;
  final String fileName;
  const ChatFileSent({required this.roomId, required this.filePath, required this.fileName});
  @override
  List<Object?> get props => [roomId, filePath, fileName];
}

class ChatVoiceSent extends ChatEvent {
  final String roomId;
  final String filePath;
  final int duration;
  const ChatVoiceSent({required this.roomId, required this.filePath, required this.duration});
  @override
  List<Object?> get props => [roomId, filePath, duration];
}

class ChatMessageRecalled extends ChatEvent {
  final String roomId;
  final String eventId;
  const ChatMessageRecalled({required this.roomId, required this.eventId});
  @override
  List<Object?> get props => [roomId, eventId];
}

class ChatMessageEdited extends ChatEvent {
  final String roomId;
  final String eventId;
  final String newContent;
  const ChatMessageEdited({required this.roomId, required this.eventId, required this.newContent});
  @override
  List<Object?> get props => [roomId, eventId, newContent];
}

class ChatNewMessageReceived extends ChatEvent {
  final ChatMessage message;
  const ChatNewMessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class ChatTypingSent extends ChatEvent {
  final String roomId;
  final bool isTyping;
  const ChatTypingSent({required this.roomId, required this.isTyping});
  @override
  List<Object?> get props => [roomId, isTyping];
}

class ChatRoomCleared extends ChatEvent {
  const ChatRoomCleared();
}

class AiMessageSent extends ChatEvent {
  final String content;
  final String modelId;
  final double temperature;
  final int maxTokens;
  const AiMessageSent({
    required this.content,
    required this.modelId,
    this.temperature = 0.7,
    this.maxTokens = 4096,
  });
  @override
  List<Object?> get props => [content, modelId, temperature, maxTokens];
}

class AiStreamChunkReceived extends ChatEvent {
  final String chunk;
  const AiStreamChunkReceived(this.chunk);
  @override
  List<Object?> get props => [chunk];
}

class AiGenerationStopped extends ChatEvent {
  const AiGenerationStopped();
}

class AiModelChanged extends ChatEvent {
  final String modelId;
  const AiModelChanged(this.modelId);
  @override
  List<Object?> get props => [modelId];
}

class AiChatCleared extends ChatEvent {
  const AiChatCleared();
}
