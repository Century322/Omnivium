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
  final bool isVideo;
  final DateTime createdAt;

  CallState state;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<RTCIceCandidate> _pendingCandidates = [];
  void Function(VoIPCall call, RTCIceCandidate candidate)? onIceCandidate;
  void Function(VoIPCall call)? onStateChanged;
  void Function(VoIPCall call, MediaStream stream)? onRemoteStream;

  VoIPCall({
    required this.callId,
    required this.roomId,
    required this.remoteUserId,
    required this.isOutgoing,
    this.isVideo = false,
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

    final pc = await createPeerConnection(config);
    _peerConnection = pc;

    pc.onIceCandidate = (candidate) {
      onIceCandidate?.call(this, candidate);
    };

    pc.onIceConnectionState = (iceState) {
      AppLogger.instance.info('ICE state: $iceState');
      if (iceState == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        state = CallState.connected;
        onStateChanged?.call(this);
      } else if (iceState ==
              RTCIceConnectionState.RTCIceConnectionStateFailed ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        state = CallState.ended;
        onStateChanged?.call(this);
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final remote = event.streams[0];
        _remoteStream = remote;
        onRemoteStream?.call(this, remote);
      }
    };

    final local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo
          ? {
              'width': {'min': 640, 'ideal': 1280},
              'height': {'min': 480, 'ideal': 720},
              'facingMode': 'user',
            }
          : false,
    });
    _localStream = local;

    for (final track in local.getTracks()) {
      pc.addTrack(track, local);
    }
  }

  Future<String?> createOffer() async {
    await _setupPeerConnection();
    final pc = _peerConnection;
    if (pc == null) return null;
    final offer = await pc.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await pc.setLocalDescription(offer);
    state = CallState.inviting;
    return offer.sdp;
  }

  Future<void> handleAnswer(String sdp) async {
    final pc = _peerConnection;
    if (pc == null) return;
    final answer = RTCSessionDescription(sdp, 'answer');
    await pc.setRemoteDescription(answer);
    for (final candidate in _pendingCandidates) {
      try {
        await pc.addCandidate(candidate);
      } catch (e) {
        AppLogger.instance.debug('Add ICE candidate failed', error: e);
      }
    }
    _pendingCandidates.clear();
    state = CallState.connecting;
  }

  Future<String?> createAnswer(String offerSdp) async {
    await _setupPeerConnection();
    final pc = _peerConnection;
    if (pc == null) return null;
    final offer = RTCSessionDescription(offerSdp, 'offer');
    await pc.setRemoteDescription(offer);

    for (final candidate in _pendingCandidates) {
      pc.addCandidate(candidate);
    }
    _pendingCandidates.clear();

    final answer = await pc.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await pc.setLocalDescription(answer);
    state = CallState.connecting;
    return answer.sdp;
  }

  Future<void> addIceCandidate(
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex) async {
    final rtcCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
    final pc = _peerConnection;
    if (pc != null) {
      try {
        await pc.addCandidate(rtcCandidate);
      } catch (e) {
        AppLogger.instance.debug('ICE candidate add failed, queuing', error: e);
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
  Timer? _callTimeoutTimer;

  Stream<VoIPCall> get callStateStream => _callStateController.stream;
  VoIPCall? get currentCall => _currentCall;
  bool get isInCall => _currentCall?.isActive ?? false;

  VoIPCall get requireCurrentCall {
    final call = _currentCall;
    if (call == null) throw StateError('No active call');
    return call;
  }

  void init(matrix.Client client) {
    _eventSubscription?.cancel();
    _matrixClient = client;
    _eventSubscription = client.onTimelineEvent.stream.listen(
      _handleTimelineEvent);
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
          _handleIncomingCall(callId, roomId, callContent, event.senderId);
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
    return initiateCallWithVideo(roomId, remoteUserId, isVideo: false);
  }

  Future<void> initiateCallWithVideo(
    String roomId,
    String remoteUserId, {
    bool isVideo = false,
  }) async {
    final current = _currentCall;
    if (current != null && current.isActive) {
      AppLogger.instance.warning('Already in a call');
      return;
    }

    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    final call = VoIPCall(
      callId: callId,
      roomId: roomId,
      remoteUserId: remoteUserId,
      isOutgoing: true,
      isVideo: isVideo);

    call.onIceCandidate = (c, candidate) {
      _sendCallEvent(roomId, 'm.call.candidates', {
        'call_id': callId,
        'version': 1,
        'candidates': [
          {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        ],
      });
    };

    call.onStateChanged = (c) {
      _notifyState();
    };

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

    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(const Duration(seconds: 60), () {
      if (_currentCall == call && call.state == CallState.inviting) {
        hangup();
      }
    });

    AppLogger.instance.info('Outgoing call initiated: $callId');
  }

  void _handleIncomingCall(
    String callId,
    String roomId,
    Map<String, dynamic> content,
    String senderId) {
    final current = _currentCall;
    if (current != null && current.isActive) {
      _sendCallEvent(roomId, 'm.call.hangup', {
        'call_id': callId,
        'version': 1,
        'reason': 'busy',
      });
      return;
    }

    final offer = content['offer'] as Map<String, dynamic>?;
    if (offer == null) return;

    final call = VoIPCall(
      callId: callId,
      roomId: roomId,
      remoteUserId: senderId,
      isOutgoing: false,
      state: CallState.ringing);

    call.onIceCandidate = (c, candidate) {
      _sendCallEvent(roomId, 'm.call.candidates', {
        'call_id': callId,
        'version': 1,
        'candidates': [
          {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        ],
      });
    };

    call.onStateChanged = (c) {
      _notifyState();
    };

    _currentCall = call;
    _notifyState();
    AppLogger.instance.info('Incoming call: $callId from $senderId');
  }

  Future<void> answerCall() async {
    final call = _currentCall;
    if (call == null || call.state != CallState.ringing) {
      return;
    }

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
        error: e);
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
    final call = _currentCall;
    if (candidates == null || call == null) return;

    for (final c in candidates) {
      final candidate = c as Map<String, dynamic>;
      call.addIceCandidate(
        candidate['candidate'] as String? ?? '',
        candidate['sdpMid'] as String?,
        candidate['sdpMLineIndex'] as int?);
    }
  }

  void _handleCallAnswer(Map<String, dynamic> content) async {
    final call = _currentCall;
    if (call == null || !call.isOutgoing) return;
    final callId = content['call_id'] as String?;
    if (callId != call.callId) return;

    final answer = content['answer'] as Map<String, dynamic>?;
    if (answer == null) return;

    final sdp = answer['sdp'] as String?;
    if (sdp != null) {
      await call.handleAnswer(sdp);
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
    final call = _currentCall;
    if (call == null) return;
    await _sendCallEvent(call.roomId, 'm.call.hangup', {
      'call_id': call.callId,
      'version': 1,
      'reason': 'user_hangup',
    });
    call.end();
    _currentCall = null;
    _notifyState();
  }

  Future<void> hangup() async {
    _callTimeoutTimer?.cancel();
    final call = _currentCall;
    if (call == null) return;
    await _sendCallEvent(call.roomId, 'm.call.hangup', {
      'call_id': call.callId,
      'version': 1,
      'reason': 'user_hangup',
    });
    call.end();
    _currentCall = null;
    _notifyState();
  }

  Future<void> _sendCallEvent(
    String roomId,
    String type,
    Map<String, dynamic> content) async {
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
    final call = _currentCall;
    if (call != null) {
      _callStateController.add(call);
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
