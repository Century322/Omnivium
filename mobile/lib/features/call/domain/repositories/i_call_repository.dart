import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/call_entities.dart';

abstract class ICallRepository {
  Future<Either<Failure, void>> startCall(String roomId, String userId, {bool isVideo = false});
  Future<Either<Failure, void>> answerCall(String callId);
  Future<Either<Failure, void>> declineCall(String callId);
  Future<Either<Failure, void>> endCall(String callId);
  Future<Either<Failure, void>> toggleMute(bool muted);
  Future<Either<Failure, void>> toggleSpeaker(bool speaker);
  Future<Either<Failure, void>> toggleCamera(bool enabled);
  Stream<CallState> get onCallStateChanged;
}
