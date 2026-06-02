import 'package:matrix/matrix.dart';
import '../../../core/di/app_di.dart';
import '../../../core/matrix/matrix_cubit.dart';
import '../../../core/matrix/friend_chat_cubit.dart';
import '../../../core/app_logger.dart';
import 'friend_message_parser.dart';

mixin FriendChatMessageLoader on State {
  String get chatTargetId;
  List<FriendMessageData> get friendMessages;

  Future<List<FriendMessageData>> loadMatrixMessages(String roomId) async {
    try {
      final matrix = getIt<MatrixCubit>();
      if (!matrix.isLoggedIn || roomId.isEmpty) return [];
      final client = matrix.client;
      if (client == null) return [];
      final room = client.getRoomById(roomId);
      if (room == null) return [];
      final timeline = await room.getTimeline();
      return FriendMessageParser.parseTimeline(timeline);
    } catch (e) {
      AppLogger.instance.warning('loadMatrixMessages failed', error: e);
      return [];
    }
  }

  Future<List<FriendMessageData>> loadMoreHistory(String roomId) async {
    try {
      final matrix = getIt<MatrixCubit>();
      if (!matrix.isLoggedIn || roomId.isEmpty) return [];
      final client = matrix.client;
      if (client == null) return [];
      final room = client.getRoomById(roomId);
      if (room == null) return [];
      final timeline = await room.getTimeline();
      if (timeline.canRequestHistory) {
        await timeline.requestHistory();
      }
      return FriendMessageParser.parseTimeline(timeline);
    } catch (e) {
      AppLogger.instance.warning('loadMoreHistory failed', error: e);
      return [];
    }
  }
}
