import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../../data/models/unified_message.dart';
import '../../../../core/matrix/matrix_service.dart';
import '../../../../core/di/app_di.dart';
import '../../../../core/providers/ai_provider.dart' as ai_provider;
import '../../../../core/app_logger.dart';
import 'package:matrix/matrix.dart' as matrix;

class ChatRepositoryImpl implements IChatRepository {
  final MatrixService _matrixService;
  StreamSubscription<String>? _aiStreamSub;
  bool _aiGenerationStopped = false;

  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  ChatRepositoryImpl(this._matrixService) {
    _listenToMatrixEvents();
  }

  void _listenToMatrixEvents() {
    _matrixService.client?.onSync.stream.listen((sync) {
      final joinRooms = sync.rooms?.join;
      if (joinRooms == null) return;
      for (final entry in joinRooms.entries) {
        final roomId = entry.key;
        final room = _matrixService.client?.getRoomById(roomId);
        if (room == null) continue;
        final roomData = entry.value;
        for (final event in roomData.timeline?.events ?? []) {
          if (event.type == matrix.EventTypes.Message) {
            final msg = _parseEvent(room, event);
            if (msg != null && !msg.isMine) {
              _messageController.add(msg);
            }
          }
        }
      }
    });
  }

  @override
  Future<Either<Failure, List<ChatRoom>>> getRooms() async {
    try {
      final rooms = _matrixService.rooms;
      final chatRooms = rooms.map(_mapRoom).toList();
      return Right(chatRooms);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(
    String roomId, {
    int limit = 50,
    String? fromToken,
  }) async {
    try {
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) {
        return const Left(ServerFailure(message: 'Room not found'));
      }
      final timeline = await room.getTimeline();
      final events = timeline.events;
      final messages = events.map((e) => _parseEvent(room, e)).whereType<ChatMessage>().toList();
      return Right(messages);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(
    String roomId,
    String text, {
    String? replyToId,
  }) async {
    try {
      String? eventId;
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) {
        return const Left(ServerFailure(message: 'Room not found'));
      }
      if (replyToId != null) {
        final replyEvent = await room.getEventById(replyToId);
        if (replyEvent != null) {
          eventId = await room.sendTextEvent(text, inReplyTo: replyEvent);
        } else {
          eventId = await room.sendTextEvent(text);
        }
      } else {
        eventId = await room.sendTextEvent(text);
      }
      if (eventId == null) {
        return const Left(ServerFailure(message: 'Failed to send message: no event ID returned'));
      }
      final profile = await _matrixService.client?.getProfileFromUserId(
        _matrixService.client!.userID!,
      );
      return Right(ChatMessage(
        id: eventId,
        roomId: roomId,
        senderId: _matrixService.client?.userID ?? '',
        senderName: profile?.displayName ?? '',
        content: text,
        timestamp: DateTime.now(),
        metadata: {'is_mine': true}));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendImage(
    String roomId,
    String filePath,
    String fileName) async {
    try {
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) {
        return const Left(ServerFailure(message: 'Room not found'));
      }
      final file = matrix.MatrixFile(
        bytes: await _readFile(filePath),
        name: fileName);
      await room.sendFileEvent(file);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendFile(
    String roomId,
    String filePath,
    String fileName) async {
    try {
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) {
        return const Left(ServerFailure(message: 'Room not found'));
      }
      final file = matrix.MatrixFile(
        bytes: await _readFile(filePath),
        name: fileName);
      await room.sendFileEvent(file);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendVoiceMessage(
    String roomId,
    String filePath,
    int duration) async {
    try {
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) {
        return const Left(ServerFailure(message: 'Room not found'));
      }
      final file = matrix.MatrixAudioFile(
        name: 'voice_message.ogg',
        bytes: await _readFile(filePath),
        mimeType: 'audio/ogg',
        duration: duration);
      await room.sendFileEvent(file);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recallMessage(String roomId, String eventId) async {
    try {
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) {
        return const Left(ServerFailure(message: 'Room not found'));
      }
      await room.redactEvent(eventId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> editMessage(
    String roomId,
    String eventId,
    String newContent) async {
    try {
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) {
        return const Left(ServerFailure(message: 'Room not found'));
      }
      await room.sendTextEvent(
        newContent,
        editEventId: eventId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> createDirectChat(String userId) async {
    try {
      final roomId = await _matrixService.createDirectChat(userId);
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) {
        return const Left(ServerFailure(message: 'Room not found after creation'));
      }
      return Right(_mapRoom(room));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatRoom>> createGroupChat(
    String name, {
    List<String>? userIds,
    String? topic,
  }) async {
    try {
      final roomId = await _matrixService.createGroupChat(
        name,
        userIds: userIds,
        topic: topic);
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) {
        return const Left(ServerFailure(message: 'Room not found after creation'));
      }
      return Right(_mapRoom(room));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String roomId) async {
    try {
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) return const Right(null);
      await room.postReceipt(room.lastEvent?.eventId ?? '');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendTyping(
    String roomId, {
    required bool isTyping,
  }) async {
    try {
      final room = _matrixService.client?.getRoomById(roomId);
      if (room == null) return const Right(null);
      await room.setTyping(isTyping, timeout: isTyping ? 30000 : 0);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<ChatMessage> get onNewMessage => _messageController.stream;

  @override
  Stream<String> get onTyping {
    try {
      final client = _matrixService.client;
      if (client == null) return const Stream.empty();
      return client.onRoomUpdate.asyncMap((event) {
        if (event.type == matrix.UpdateType.typing) {
          final room = client.getRoomById(event.roomID);
          if (room != null) {
            final typingUsers = room.typingUsers
                .where((u) => u.id != client.userID)
                .map((u) => u.id)
                .join(',');
            return typingUsers;
          }
        }
        return '';
      }).where((id) => id.isNotEmpty);
    } catch (_) {
      return const Stream.empty();
    }
  }

  ChatRoom _mapRoom(matrix.Room room) {
    return ChatRoom(
      id: room.id,
      name: room.getLocalizedDisplayname(),
      avatarUrl: room.avatar != null
          ? room.avatar!.getThumbnail(
              _matrixService.client!,
              width: 64,
              height: 64).toString()
          : null,
      isDirect: room.isDirectChat,
      isGroup: !room.isDirectChat,
      unreadCount: room.notificationCount,
      lastMessage: room.lastEvent?.body,
      lastMessageTime: room.lastEvent?.originServerTs,
      memberIds: room.getParticipants().map((u) => u.id).toList(),
      topic: room.topic,
      isEncrypted: room.encrypted);
  }

  ChatMessage? _parseEvent(matrix.Room room, matrix.Event event) {
    if (event.type != matrix.EventTypes.Message &&
        event.type != matrix.EventTypes.Encrypted) {
      return null;
    }
    final isMine = event.senderId == _matrixService.client?.userID;
    MessageType type = MessageType.text;
    if (event.messageType == matrix.MessageTypes.Image) {
      type = MessageType.image;
    } else if (event.messageType == matrix.MessageTypes.File) {
      type = MessageType.file;
    } else if (event.messageType == matrix.MessageTypes.Audio) {
      type = MessageType.audio;
    } else if (event.messageType == matrix.MessageTypes.Video) {
      type = MessageType.video;
    }
    return ChatMessage(
      id: event.eventId,
      roomId: room.id,
      senderId: event.senderId,
      senderName: event.senderFromMemoryOrFallback.displayName ?? event.senderId,
      senderAvatarUrl: event.senderFromMemoryOrFallback.avatarUrl?.toString(),
      content: event.body,
      type: type,
      timestamp: event.originServerTs,
      isEdited: event.relationshipType == 'm.replace',
      isRecalled: event.redacted,
      metadata: {'is_mine': isMine});
  }

  Future<Uint8List> _readFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }
    return await file.readAsBytes();
  }

  @override
  Stream<UnifiedMessage> sendAiMessage(
    String content,
    String modelId, {
    double temperature = 0.7,
    int maxTokens = 4096,
  }) {
    _aiGenerationStopped = false;
    final controller = StreamController<UnifiedMessage>();

    final userMessage = UnifiedMessage(
      id: 'ai_user_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'user',
      content: content,
      type: MessageType.aiChat,
      format: MessageFormat.text,
      timestamp: DateTime.now(),
      metadata: {'is_mine': true, 'model': modelId},
    );
    controller.add(userMessage);

    () async {
      try {
        final chatService = ai_provider.ChatService.instance;
        final chatMessages = [
          ai_provider.ChatMessage(role: 'user', content: content),
        ];
        final stream = await chatService.chat(
          chatMessages,
          model: modelId,
          temperature: temperature,
          maxTokens: maxTokens,
        );

        final buffer = StringBuffer();
        String? assistantId;

        _aiStreamSub = stream.listen(
          (chunk) {
            if (_aiGenerationStopped) return;
            buffer.write(chunk);
            if (assistantId == null) {
              assistantId = 'ai_resp_${DateTime.now().millisecondsSinceEpoch}';
            }
            controller.add(UnifiedMessage(
              id: '${assistantId}_partial',
              senderId: 'assistant',
              content: buffer.toString(),
              type: MessageType.aiChat,
              format: MessageFormat.text,
              timestamp: DateTime.now(),
              sourceContext: 'streaming',
              metadata: {'is_mine': false, 'model': modelId},
            ));
          },
          onDone: () {
            if (!_aiGenerationStopped && buffer.isNotEmpty) {
              controller.add(UnifiedMessage(
                id: assistantId ?? 'ai_resp_${DateTime.now().millisecondsSinceEpoch}',
                senderId: 'assistant',
                content: buffer.toString(),
                type: MessageType.aiChat,
                format: MessageFormat.text,
                timestamp: DateTime.now(),
                metadata: {'is_mine': false, 'model': modelId},
              ));
            }
            controller.close();
          },
          onError: (e) {
            AppLogger.instance.error('AI stream error', error: e);
            controller.addError(e);
            controller.close();
          },
          cancelOnError: true,
        );
      } catch (e) {
        AppLogger.instance.error('AI chat failed', error: e);
        controller.addError(e);
        controller.close();
      }
    }();

    return controller.stream;
  }

  @override
  Future<Either<Failure, void>> stopAiGeneration() async {
    _aiGenerationStopped = true;
    await _aiStreamSub?.cancel();
    _aiStreamSub = null;
    return const Right(null);
  }
}
