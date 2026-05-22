import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'app_logger.dart';

enum CallState { idle, inviting, ringing, connecting, connected, ended }

class VoIPCall {
  final String callId;
  final String roomId;
  final String remoteUserId;
  final bool isOutgoing;
  final DateTime createdAt;

  CallState state;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<RTCIceCandidate> _pendingCandidates = [];

  VoIPCall({
    required this.callId,
    required this.roomId,
    required this.remoteUserId,
    required this.isOutgoing,
    this.state = CallState.idle,
  }) : createdAt = DateTime.now();

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get isActive =>
      state == CallState.connected || state == CallState.connecting;

  Future<void> _setupPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {};

    _peerConnection!.onIceConnectionState = (iceState) {
      AppLogger.instance.info('ICE state: $iceState');
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    for (final track in _localStream!.getTracks()) {
      _peerConnection!.addTrack(track, _localStream!);
    }
  }

  Future<String?> createOffer() async {
    await _setupPeerConnection();
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(offer);
    state = CallState.inviting;
    return offer.sdp;
  }

  Future<void> handleAnswer(String sdp) async {
    final answer = RTCSessionDescription(sdp, 'answer');
    await _peerConnection!.setRemoteDescription(answer);
    state = CallState.connecting;
  }

  Future<String?> createAnswer(String offerSdp) async {
    await _setupPeerConnection();
    final offer = RTCSessionDescription(offerSdp, 'offer');
    await _peerConnection!.setRemoteDescription(offer);

    for (final candidate in _pendingCandidates) {
      _peerConnection!.addCandidate(candidate);
    }
    _pendingCandidates.clear();

    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(answer);
    state = CallState.connecting;
    return answer.sdp;
  }

  Future<void> addIceCandidate(
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    final rtcCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
    if (_peerConnection != null) {
      try {
        await _peerConnection!.addCandidate(rtcCandidate);
      } catch (_) {
        _pendingCandidates.add(rtcCandidate);
      }
    } else {
      _pendingCandidates.add(rtcCandidate);
    }
  }

  void end() {
    state = CallState.ended;
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    _localStream?.dispose();
    _localStream = null;
    _remoteStream?.dispose();
    _remoteStream = null;
    _peerConnection?.close();
    _peerConnection = null;
    _pendingCandidates.clear();
  }
}

class CallService {
  static CallService? _instance;
  static CallService get instance => _instance ??= CallService._();

  CallService._();

  matrix.Client? _matrixClient;
  VoIPCall? _currentCall;
  StreamSubscription? _eventSubscription;
  final _callStateController = StreamController<VoIPCall>.broadcast();

  Stream<VoIPCall> get callStateStream => _callStateController.stream;
  VoIPCall? get currentCall => _currentCall;
  bool get isInCall => _currentCall?.isActive ?? false;

  void init(matrix.Client client) {
    _matrixClient = client;
    _eventSubscription = client.onTimelineEvent.stream.listen(
      _handleTimelineEvent,
    );
    AppLogger.instance.info('CallService initialized');
  }

  void _handleTimelineEvent(matrix.Event event) {
    try {
      final type = event.type;
      if (!type.startsWith('m.call.')) return;

      final callContent = event.content;
      if (callContent.isEmpty) return;

      final callId = callContent['call_id'] as String?;
      final roomId = event.room.id;
      if (callId == null) return;

      switch (type) {
        case 'm.call.invite':
          _handleIncomingCall(callId, roomId, callContent);
        case 'm.call.candidates':
          _handleCandidates(callContent);
        case 'm.call.answer':
          _handleCallAnswer(callContent);
        case 'm.call.hangup':
          _handleHangup(callContent);
      }
    } catch (e) {
      AppLogger.instance.error('CallService event handling error', error: e);
    }
  }

  Future<void> initiateCall(String roomId, String remoteUserId) async {
    if (_currentCall != null && _currentCall!.isActive) {
      AppLogger.instance.warning('Already in a call');
      return;
    }

    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    final call = VoIPCall(
      callId: callId,
      roomId: roomId,
      remoteUserId: remoteUserId,
      isOutgoing: true,
    );

    final offerSdp = await call.createOffer();
    if (offerSdp == null) {
      call.end();
      return;
    }

    _currentCall = call;
    _notifyState();

    await _sendCallEvent(roomId, 'm.call.invite', {
      'call_id': callId,
      'version': 1,
      'lifetime': 60000,
      'offer': {'type': 'offer', 'sdp': offerSdp},
    });

    AppLogger.instance.info('Outgoing call initiated: $callId');
  }

  void _handleIncomingCall(
    String callId,
    String roomId,
    Map<String, dynamic> content,
  ) {
    if (_currentCall != null && _currentCall!.isActive) {
      _sendCallEvent(roomId, 'm.call.hangup', {
        'call_id': callId,
        'version': 1,
        'reason': 'busy',
      });
      return;
    }

    final offer = content['offer'] as Map<String, dynamic>?;
    if (offer == null) return;

    final senderId = content['sender_id'] as String? ?? '';

    _currentCall = VoIPCall(
      callId: callId,
      roomId: roomId,
      remoteUserId: senderId,
      isOutgoing: false,
      state: CallState.ringing,
    );

    _notifyState();
    AppLogger.instance.info('Incoming call: $callId from $senderId');
  }

  Future<void> answerCall() async {
    if (_currentCall == null || _currentCall!.state != CallState.ringing) {
      return;
    }

    final call = _currentCall!;
    final client = _matrixClient;
    if (client == null) return;

    final room = client.getRoomById(call.roomId);
    if (room == null) return;

    String? offerSdp;
    try {
      final timeline = await room.getTimeline();
      for (final event in timeline.events.reversed) {
        if (event.type == 'm.call.invite') {
          final eventId = event.content['call_id'] as String?;
          if (eventId == call.callId) {
            offerSdp =
                (event.content['offer'] as Map<String, dynamic>?)?['sdp']
                    as String?;
            break;
          }
        }
      }
    } catch (e) {
      AppLogger.instance.error(
        'Failed to get timeline for call invite',
        error: e,
      );
    }

    if (offerSdp == null) {
      AppLogger.instance.error('Could not find call invite event');
      return;
    }

    final answerSdp = await call.createAnswer(offerSdp);
    if (answerSdp == null) {
      call.end();
      return;
    }

    await _sendCallEvent(call.roomId, 'm.call.answer', {
      'call_id': call.callId,
      'version': 1,
      'answer': {'type': 'answer', 'sdp': answerSdp},
    });

    _notifyState();
  }

  void _handleCandidates(Map<String, dynamic> content) {
    final candidates = content['candidates'] as List<dynamic>?;
    if (candidates == null || _currentCall == null) return;

    for (final c in candidates) {
      final candidate = c as Map<String, dynamic>;
      _currentCall!.addIceCandidate(
        candidate['candidate'] as String? ?? '',
        candidate['sdpMid'] as String?,
        candidate['sdpMLineIndex'] as int?,
      );
    }
  }

  void _handleCallAnswer(Map<String, dynamic> content) {
    if (_currentCall == null || !_currentCall!.isOutgoing) return;
    final callId = content['call_id'] as String?;
    if (callId != _currentCall!.callId) return;

    final answer = content['answer'] as Map<String, dynamic>?;
    if (answer == null) return;

    final sdp = answer['sdp'] as String?;
    if (sdp != null) {
      _currentCall!.handleAnswer(sdp);
      _currentCall!.state = CallState.connected;
      _notifyState();
    }
  }

  void _handleHangup(Map<String, dynamic> content) {
    final callId = content['call_id'] as String?;
    if (callId != _currentCall?.callId) return;

    _currentCall?.end();
    _currentCall = null;
    _notifyState();
    AppLogger.instance.info('Call ended');
  }

  Future<void> rejectCall() async {
    if (_currentCall == null) return;
    await _sendCallEvent(_currentCall!.roomId, 'm.call.hangup', {
      'call_id': _currentCall!.callId,
      'version': 1,
      'reason': 'user_hangup',
    });
    _currentCall?.end();
    _currentCall = null;
    _notifyState();
  }

  Future<void> hangup() async {
    if (_currentCall == null) return;
    await _sendCallEvent(_currentCall!.roomId, 'm.call.hangup', {
      'call_id': _currentCall!.callId,
      'version': 1,
      'reason': 'user_hangup',
    });
    _currentCall?.end();
    _currentCall = null;
    _notifyState();
  }

  Future<void> _sendCallEvent(
    String roomId,
    String type,
    Map<String, dynamic> content,
  ) async {
    final client = _matrixClient;
    if (client == null) return;

    try {
      final room = client.getRoomById(roomId);
      if (room == null) return;
      await room.sendEvent(content, type: type);
    } catch (e) {
      AppLogger.instance.error('Failed to send call event', error: e);
    }
  }

  void _notifyState() {
    if (_currentCall != null) {
      _callStateController.add(_currentCall!);
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _currentCall?.end();
    _currentCall = null;
    _callStateController.close();
    _instance = null;
  }
}
