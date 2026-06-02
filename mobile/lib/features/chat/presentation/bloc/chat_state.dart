import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../data/models/unified_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatRoomsLoading extends ChatState {
  const ChatRoomsLoading();
}

class ChatRoomsLoaded extends ChatState {
  final List<ChatRoom> rooms;
  const ChatRoomsLoaded(this.rooms);
  @override
  List<Object?> get props => [rooms];
}

class ChatMessagesLoading extends ChatState {
  final List<ChatMessage> currentMessages;
  const ChatMessagesLoading(this.currentMessages);
  @override
  List<Object?> get props => [currentMessages];
}

class ChatMessagesLoaded extends ChatState {
  final List<ChatRoom> rooms;
  final String activeRoomId;
  final List<ChatMessage> messages;
  final bool hasMoreHistory;
  const ChatMessagesLoaded({
    required this.rooms,
    required this.activeRoomId,
    required this.messages,
    this.hasMoreHistory = true,
  });
  @override
  List<Object?> get props => [rooms, activeRoomId, messages, hasMoreHistory];
}

class ChatMessageSending extends ChatState {
  final List<ChatRoom> rooms;
  final String activeRoomId;
  final List<ChatMessage> messages;
  const ChatMessageSending({
    required this.rooms,
    required this.activeRoomId,
    required this.messages,
  });
  @override
  List<Object?> get props => [rooms, activeRoomId, messages];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}

class AiChatReady extends ChatState {
  final List<UnifiedMessage> messages;
  final String currentModel;
  const AiChatReady({required this.messages, required this.currentModel});
  @override
  List<Object?> get props => [messages, currentModel];
}

class AiChatGenerating extends ChatState {
  final List<UnifiedMessage> messages;
  final String currentModel;
  final String partialContent;
  const AiChatGenerating({
    required this.messages,
    required this.currentModel,
    this.partialContent = '',
  });
  @override
  List<Object?> get props => [messages, currentModel, partialContent];
}

class AiChatError extends ChatState {
  final String message;
  final List<UnifiedMessage> messages;
  final String currentModel;
  const AiChatError({
    required this.message,
    required this.messages,
    required this.currentModel,
  });
  @override
  List<Object?> get props => [message, messages, currentModel];
}
