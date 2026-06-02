import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/matrix/matrix_service.dart';
import '../../../../core/app_logger.dart';
import '../../domain/entities/call_entities.dart';
import '../../domain/repositories/i_call_repository.dart';

class CallRepositoryImpl implements ICallRepository {
  final MatrixService _matrix;
  final _callStateController = StreamController<CallState>.broadcast();

  CallRepositoryImpl(this._matrix);

  @override
  Future<Either<Failure, void>> startCall(String roomId, String userId, {bool isVideo = false}) async {
    try {
      if (!_matrix.isLoggedIn) return const Left(ServerFailure(message: 'Not logged in'));
      final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
      final callState = CallState(
        callId: callId,
        roomId: roomId,
        remoteUserId: userId,
        remoteUserName: userId.split(':').first.replaceFirst('@', ''),
        status: CallStatus.connecting,
        isVideo: isVideo,
        startedAt: DateTime.now());
      _callStateController.add(callState);
      return const Right(null);
    } catch (e, st) {
      AppLogger.instance.error('startCall failed', error: e, stackTrace: st);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> answerCall(String callId) async {
    try {
      return const Right(null);
    } catch (e, st) {
      AppLogger.instance.error('answerCall failed', error: e, stackTrace: st);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> declineCall(String callId) async {
    try {
      return const Right(null);
    } catch (e, st) {
      AppLogger.instance.error('declineCall failed', error: e, stackTrace: st);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endCall(String callId) async {
    try {
      return const Right(null);
    } catch (e, st) {
      AppLogger.instance.error('endCall failed', error: e, stackTrace: st);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleMute(bool muted) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> toggleSpeaker(bool speaker) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> toggleCamera(bool enabled) async {
    return const Right(null);
  }

  @override
  Stream<CallState> get onCallStateChanged => _callStateController.stream;
}
