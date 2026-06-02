import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/get_rooms_usecase.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../../data/models/unified_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetRoomsUseCase _getRoomsUseCase;
  final GetMessagesUseCase _getMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final IChatRepository _repository;

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<UnifiedMessage>? _aiStreamSub;

  ChatBloc(
    this._getRoomsUseCase,
    this._getMessagesUseCase,
    this._sendMessageUseCase,
    this._repository) : super(const ChatInitial()) {
    on<ChatRoomsLoadRequested>(_onLoadRooms);
    on<ChatRoomSelected>(_onSelectRoom);
    on<ChatMessagesLoadRequested>(_onLoadMessages);
    on<ChatMessageSent>(_onSendMessage);
    on<ChatImageSent>(_onSendImage);
    on<ChatFileSent>(_onSendFile);
    on<ChatVoiceSent>(_onSendVoice);
    on<ChatMessageRecalled>(_onRecallMessage);
    on<ChatMessageEdited>(_onEditMessage);
    on<ChatNewMessageReceived>(_onNewMessage);
    on<ChatTypingSent>(_onTyping);
    on<ChatRoomCleared>(_onClearRoom);
    on<AiMessageSent>(_onSendAiMessage);
    on<AiStreamChunkReceived>(_onAiChunk);
    on<AiGenerationStopped>(_onAiStop);
    on<AiModelChanged>(_onAiModelChange);
    on<AiChatCleared>(_onAiClear);

    _messageSubscription = _repository.onNewMessage.listen((message) {
      add(ChatNewMessageReceived(message));
    });
  }

  Future<void> _onLoadRooms(ChatRoomsLoadRequested event, Emitter<ChatState> emit) async {
    emit(const ChatRoomsLoading());
    final result = await _getRoomsUseCase(const NoParams());
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (rooms) => emit(ChatRoomsLoaded(rooms)));
  }

  Future<void> _onSelectRoom(ChatRoomSelected event, Emitter<ChatState> emit) async {
    final currentState = state;
    List<ChatMessage> existing = [];
    List<ChatRoom> rooms = [];
    if (currentState is ChatRoomsLoaded) {
      rooms = currentState.rooms;
    } else if (currentState is ChatMessagesLoaded) {
      rooms = currentState.rooms;
      existing = currentState.messages;
    }
    emit(ChatMessagesLoading(existing));
    final result = await _getMessagesUseCase(GetMessagesParams(roomId: event.roomId));
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (messages) => emit(ChatMessagesLoaded(
        rooms: rooms,
        activeRoomId: event.roomId,
        messages: messages)));
  }

  Future<void> _onLoadMessages(ChatMessagesLoadRequested event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! ChatMessagesLoaded) return;
    final result = await _getMessagesUseCase(GetMessagesParams(
      roomId: event.roomId,
      limit: event.limit,
      fromToken: event.fromToken));
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (olderMessages) => emit(ChatMessagesLoaded(
        rooms: currentState.rooms,
        activeRoomId: currentState.activeRoomId,
        messages: [...olderMessages, ...currentState.messages],
        hasMoreHistory: olderMessages.length >= event.limit)));
  }

  Future<void> _onSendMessage(ChatMessageSent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! ChatMessagesLoaded) return;
    emit(ChatMessageSending(
      rooms: currentState.rooms,
      activeRoomId: currentState.activeRoomId,
      messages: currentState.messages));
    final result = await _sendMessageUseCase(SendMessageParams(
      roomId: event.roomId,
      text: event.text,
      replyToId: event.replyToId));
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (message) => emit(ChatMessagesLoaded(
        rooms: currentState.rooms,
        activeRoomId: currentState.activeRoomId,
        messages: [...currentState.messages, message])));
  }

  Future<void> _onSendImage(ChatImageSent event, Emitter<ChatState> emit) async {
    await _repository.sendImage(event.roomId, event.filePath, event.fileName);
  }

  Future<void> _onSendFile(ChatFileSent event, Emitter<ChatState> emit) async {
    await _repository.sendFile(event.roomId, event.filePath, event.fileName);
  }

  Future<void> _onSendVoice(ChatVoiceSent event, Emitter<ChatState> emit) async {
    await _repository.sendVoiceMessage(event.roomId, event.filePath, event.duration);
  }

  Future<void> _onRecallMessage(ChatMessageRecalled event, Emitter<ChatState> emit) async {
    await _repository.recallMessage(event.roomId, event.eventId);
  }

  Future<void> _onEditMessage(ChatMessageEdited event, Emitter<ChatState> emit) async {
    await _repository.editMessage(event.roomId, event.eventId, event.newContent);
  }

  void _onNewMessage(ChatNewMessageReceived event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatMessagesLoaded && event.message.roomId == currentState.activeRoomId) {
      emit(ChatMessagesLoaded(
        rooms: currentState.rooms,
        activeRoomId: currentState.activeRoomId,
        messages: [...currentState.messages, event.message]));
    }
  }

  Future<void> _onTyping(ChatTypingSent event, Emitter<ChatState> emit) async {
    await _repository.sendTyping(event.roomId, isTyping: event.isTyping);
  }

  void _onClearRoom(ChatRoomCleared event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatMessagesLoaded) {
      emit(ChatRoomsLoaded(currentState.rooms));
    }
  }

  Future<void> _onSendAiMessage(AiMessageSent event, Emitter<ChatState> emit) async {
    final currentModel = state is AiChatReady
        ? (state as AiChatReady).currentModel
        : state is AiChatGenerating
            ? (state as AiChatGenerating).currentModel
            : event.modelId;

    final existingMessages = state is AiChatReady
        ? (state as AiChatReady).messages
        : state is AiChatGenerating
            ? (state as AiChatGenerating).messages
            : <UnifiedMessage>[];

    final userMessage = UnifiedMessage(
      id: 'ai_user_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'user',
      content: event.content,
      type: MessageType.aiChat,
      format: MessageFormat.text,
      timestamp: DateTime.now(),
      metadata: {'is_mine': true, 'model': currentModel});

    final updatedMessages = [...existingMessages, userMessage];

    emit(AiChatGenerating(
      messages: updatedMessages,
      currentModel: currentModel));

    try {
      final stream = _repository.sendAiMessage(
        event.content,
        event.modelId,
        temperature: event.temperature,
        maxTokens: event.maxTokens);

      _aiStreamSub = stream.listen(
        (msg) {
          if (msg.sourceContext == 'streaming') {
            add(AiStreamChunkReceived(msg.content));
          }
        },
        onDone: () {
          add(const AiGenerationStopped());
        },
        onError: (e) {
          AppLogger.instance.error('AI stream error', error: e);
          add(const AiGenerationStopped());
        },
        cancelOnError: true);
    } catch (e) {
      final current = state;
      final msgs = current is AiChatGenerating ? current.messages : updatedMessages;
      emit(AiChatError(message: e.toString(), messages: msgs, currentModel: currentModel));
    }
  }

  void _onAiChunk(AiStreamChunkReceived event, Emitter<ChatState> emit) {
    final current = state;
    if (current is AiChatGenerating) {
      emit(AiChatGenerating(
        messages: current.messages,
        currentModel: current.currentModel,
        partialContent: event.chunk));
    }
  }

  void _onAiStop(AiGenerationStopped event, Emitter<ChatState> emit) {
    final current = state;
    if (current is AiChatGenerating) {
      final assistantMessage = UnifiedMessage(
        id: 'ai_resp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'assistant',
        content: current.partialContent,
        type: MessageType.aiChat,
        format: MessageFormat.text,
        timestamp: DateTime.now(),
        metadata: {'is_mine': false, 'model': current.currentModel});
      emit(AiChatReady(
        messages: [...current.messages, assistantMessage],
        currentModel: current.currentModel));
    }
  }

  void _onAiModelChange(AiModelChanged event, Emitter<ChatState> emit) {
    final current = state;
    if (current is AiChatReady) {
      emit(AiChatReady(messages: current.messages, currentModel: event.modelId));
    } else if (current is ChatInitial) {
      emit(const AiChatReady(messages: [], currentModel: 'default'));
    }
  }

  void _onAiClear(AiChatCleared event, Emitter<ChatState> emit) {
    _aiStreamSub?.cancel();
    final current = state;
    String model = 'default';
    if (current is AiChatReady) model = current.currentModel;
    if (current is AiChatGenerating) model = current.currentModel;
    emit(AiChatReady(messages: const [], currentModel: model));
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _aiStreamSub?.cancel();
    return super.close();
  }
}
