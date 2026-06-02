import 'package:equatable/equatable.dart';
import '../../domain/entities/call_entities.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

class CallStarted extends CallEvent {
  final String roomId;
  final String userId;
  final bool isVideo;
  const CallStarted({required this.roomId, required this.userId, this.isVideo = false});
  @override
  List<Object?> get props => [roomId, userId, isVideo];
}

class CallAnswered extends CallEvent {
  final String callId;
  const CallAnswered(this.callId);
  @override
  List<Object?> get props => [callId];
}

class CallDeclined extends CallEvent {
  final String callId;
  const CallDeclined(this.callId);
  @override
  List<Object?> get props => [callId];
}

class CallEnded extends CallEvent {
  final String callId;
  const CallEnded(this.callId);
  @override
  List<Object?> get props => [callId];
}

class CallMuteToggled extends CallEvent {
  final bool muted;
  const CallMuteToggled(this.muted);
  @override
  List<Object?> get props => [muted];
}

class CallSpeakerToggled extends CallEvent {
  final bool speaker;
  const CallSpeakerToggled(this.speaker);
  @override
  List<Object?> get props => [speaker];
}

class CallCameraToggled extends CallEvent {
  final bool enabled;
  const CallCameraToggled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class CallStateChanged extends CallEvent {
  final CallState state;
  const CallStateChanged(this.state);
  @override
  List<Object?> get props => [state];
}
