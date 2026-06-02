import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/call_entities.dart';
import '../../domain/repositories/i_call_repository.dart';
import 'call_event.dart';
import 'call_state.dart' as bloc_state;

class CallBloc extends Bloc<CallEvent, bloc_state.CallBlocState> {
  final ICallRepository _repository;
  StreamSubscription<CallState>? _callStateSub;

  CallBloc(this._repository) : super(const bloc_state.CallIdle()) {
    on<CallStarted>(_onStartCall);
    on<CallAnswered>(_onAnswerCall);
    on<CallDeclined>(_onDeclineCall);
    on<CallEnded>(_onEndCall);
    on<CallMuteToggled>(_onMuteToggle);
    on<CallSpeakerToggled>(_onSpeakerToggle);
    on<CallCameraToggled>(_onCameraToggle);
    on<CallStateChanged>(_onCallStateChanged);

    _callStateSub = _repository.onCallStateChanged.listen((callState) {
      add(CallStateChanged(callState));
    });
  }

  Future<void> _onStartCall(CallStarted event, Emitter<bloc_state.CallBlocState> emit) async {
    await _repository.startCall(event.roomId, event.userId, isVideo: event.isVideo);
  }

  Future<void> _onAnswerCall(CallAnswered event, Emitter<bloc_state.CallBlocState> emit) async {
    await _repository.answerCall(event.callId);
  }

  Future<void> _onDeclineCall(CallDeclined event, Emitter<bloc_state.CallBlocState> emit) async {
    await _repository.declineCall(event.callId);
  }

  Future<void> _onEndCall(CallEnded event, Emitter<bloc_state.CallBlocState> emit) async {
    await _repository.endCall(event.callId);
  }

  Future<void> _onMuteToggle(CallMuteToggled event, Emitter<bloc_state.CallBlocState> emit) async {
    await _repository.toggleMute(event.muted);
  }

  Future<void> _onSpeakerToggle(CallSpeakerToggled event, Emitter<bloc_state.CallBlocState> emit) async {
    await _repository.toggleSpeaker(event.speaker);
  }

  Future<void> _onCameraToggle(CallCameraToggled event, Emitter<bloc_state.CallBlocState> emit) async {
    await _repository.toggleCamera(event.enabled);
  }

  void _onCallStateChanged(CallStateChanged event, Emitter<bloc_state.CallBlocState> emit) {
    switch (event.state.status) {
      case CallStatus.ringing:
        emit(bloc_state.CallRinging(event.state));
      case CallStatus.connecting:
        emit(bloc_state.CallConnecting(event.state));
      case CallStatus.connected:
        emit(bloc_state.CallConnected(event.state));
      case CallStatus.ended:
      case CallStatus.missed:
        emit(bloc_state.CallEnded(event.state));
      case CallStatus.idle:
        emit(const bloc_state.CallIdle());
    }
  }

  @override
  Future<void> close() {
    _callStateSub?.cancel();
    return super.close();
  }
}
