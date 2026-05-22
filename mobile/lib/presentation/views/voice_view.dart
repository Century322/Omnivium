import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';
import '../../core/app_provider.dart';
import '../../core/navigation_provider.dart';
import '../../core/voice_service.dart';

class VoiceView extends StatefulWidget {
  final AppProvider provider;
  const VoiceView({super.key, required this.provider});

  @override
  State<VoiceView> createState() => _VoiceViewState();
}

class _VoiceViewState extends State<VoiceView> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  final VoiceService _voice = VoiceService.instance;
  StreamSubscription? _speechSub;
  StreamSubscription? _finalResultSub;
  StreamSubscription? _listeningSub;
  StreamSubscription? _speakingSub;

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isMuted = false;
  bool _isProcessing = false;
  String _recognizedText = '';
  String _aiResponse = '';
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _statusText = localeProvider.t('voice_tap_to_start');
    _setupListeners();
    widget.provider.orchestrator.addListener(_onOrchestratorChanged);
  }

  void _onOrchestratorChanged() {
    if (!mounted) return;
    final orch = widget.provider.orchestrator;
    if (orch.isStreaming || orch.isThinking) {
      setState(() {
        _isProcessing = true;
        _statusText = localeProvider.t('voice_thinking');
      });
    }

    if (orch.isIdle &&
        _responseCompleter != null &&
        !_responseCompleter!.isCompleted) {
      _responseCompleter!.complete();
      _responseCompleter = null;
    }

    final messages = orch.messages;
    if (messages.isNotEmpty) {
      final last = messages.last;
      if (last.role == 'assistant' &&
          !last.isStreaming &&
          last.content.isNotEmpty) {
        if (_aiResponse != last.content) {
          _aiResponse = last.content;
          setState(() {
            _isProcessing = false;
            _statusText = last.content;
          });
        }
      }
    }
  }

  void _setupListeners() {
    _speechSub = _voice.onSpeechResult.listen((text) {
      if (mounted && text.isNotEmpty) {
        setState(() {
          _recognizedText = text;
          _statusText = text;
        });
      }
    });

    _finalResultSub = _voice.onFinalResult.listen((text) {
      if (mounted && text.isNotEmpty) {
        _sendToAI(text);
      }
    });

    _listeningSub = _voice.onListeningStateChanged.listen((listening) {
      if (mounted) {
        setState(() {
          _isListening = listening;
          if (listening) {
            _statusText = localeProvider.t('listening');
            _recognizedText = '';
          }
        });
      }
    });

    _speakingSub = _voice.onSpeakingStateChanged.listen((speaking) {
      if (mounted) {
        setState(() {
          _isSpeaking = speaking;
          if (!speaking && !_isListening && !_isProcessing) {
            _statusText = localeProvider.t('voice_tap_to_start');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _speechSub?.cancel();
    _finalResultSub?.cancel();
    _listeningSub?.cancel();
    _speakingSub?.cancel();
    widget.provider.orchestrator.removeListener(_onOrchestratorChanged);
    _voice.stopListening();
    _voice.stopSpeaking();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isSpeaking) {
      await _voice.stopSpeaking();
    }

    if (_isListening) {
      await _voice.stopListening();
      return;
    }

    if (_isProcessing) return;

    if (!_voice.isSTTAvailable) {
      setState(() => _statusText = localeProvider.t('voice_not_available'));
      return;
    }

    _aiResponse = '';
    final started = await _voice.startListening();
    if (!started) {
      if (!mounted) return;
      setState(() => _statusText = localeProvider.t('voice_start_failed'));
    }
  }

  Future<void> _sendToAI(String text) async {
    if (text.trim().isEmpty) return;
    final orch = widget.provider.orchestrator;
    if (!orch.isIdle) return;
    await orch.sendMessage(text);

    if (_continuousMode) {
      _waitForResponseAndContinue();
    }
  }

  final bool _continuousMode =
      VoiceService.instance.voiceMode == VoiceMode.handsFree;
  Completer<void>? _responseCompleter;

  Future<void> _waitForResponseAndContinue() async {
    final orch = widget.provider.orchestrator;
    if (orch.isIdle) {
      _onResponseComplete();
      return;
    }

    _responseCompleter = Completer<void>();
    await _responseCompleter!.future;
    _onResponseComplete();
  }

  void _onResponseComplete() {
    final messages = widget.provider.orchestrator.messages;
    final lastMsg = messages.isNotEmpty ? messages.last : null;
    if (lastMsg != null &&
        lastMsg.role == 'assistant' &&
        lastMsg.content.isNotEmpty &&
        !_isMuted) {
      VoiceService.instance.speak(lastMsg.content).then((_) {
        if (_continuousMode && mounted) {
          _toggleListening();
        }
      });
    } else if (_continuousMode && mounted) {
      _toggleListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: AppColors.isLightMode(context)
                ? [AppColors.lightAccentBg, AppColors.lightBackground]
                : [AppColors.voiceDarkGradient, AppColors.bg(context)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildConversationArea()),
              _buildTranscriptArea(),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_aiResponse.isNotEmpty || _recognizedText.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _clearConversation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.divider(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    localeProvider.t('clear'),
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.provider.navigation.setIsSettingsOpen(true),
              child: Icon(
                LucideIcons.settings,
                color: AppColors.textHint(context),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationArea() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleListening,
        child: SizedBox(
          width: 288,
          height: 288,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseScale = _isListening
                      ? 1 + 0.12 * _pulseController.value
                      : 1 + 0.05 * _pulseController.value;
                  return Transform.scale(
                    scale: pulseScale,
                    child: Container(
                      width: 288,
                      height: 288,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening
                              ? AppColors.accentDark.withValues(alpha: 0.7)
                              : _isSpeaking
                              ? AppColors.accentDark.withValues(alpha: 0.6)
                              : AppColors.accentDark.withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isListening
                                ? AppColors.accentDark.withValues(alpha: 0.4)
                                : _isSpeaking
                                ? AppColors.accentDark.withValues(alpha: 0.3)
                                : AppColors.accentDark.withValues(alpha: 0.2),
                            blurRadius: 80,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  final shouldRotate =
                      _isListening || _isSpeaking || _isProcessing;
                  return Transform.rotate(
                    angle: shouldRotate
                        ? _rotateController.value * 2 * math.pi
                        : 0,
                    child: Container(
                      width: 224,
                      height: 224,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening
                              ? AppColors.accentDark.withValues(alpha: 0.6)
                              : _isSpeaking
                              ? AppColors.accentDark.withValues(alpha: 0.5)
                              : AppColors.accentDark.withValues(alpha: 0.4),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _DashedCirclePainter(
                          color: _isListening
                              ? AppColors.accentDark.withValues(alpha: 0.6)
                              : _isSpeaking
                              ? AppColors.accentDark.withValues(alpha: 0.5)
                              : AppColors.accentDark.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? AppColors.accentDark.withValues(alpha: 0.4)
                      : _isSpeaking
                      ? AppColors.accentDark.withValues(alpha: 0.3)
                      : AppColors.accentDark.withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: _isListening
                          ? AppColors.accentDark.withValues(alpha: 0.4)
                          : _isSpeaking
                          ? AppColors.accentDark.withValues(alpha: 0.3)
                          : AppColors.accentDark.withValues(alpha: 0.3),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Center(child: _buildCenterIcon()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterIcon() {
    if (_isProcessing) {
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.textPrimary(context).withValues(alpha: 0.8),
        ),
      );
    }
    if (_isListening) {
      return Icon(
        LucideIcons.mic,
        color: AppColors.textPrimary(context),
        size: 36,
      );
    }
    if (_isSpeaking) {
      return Icon(
        LucideIcons.volume2,
        color: AppColors.textPrimary(context),
        size: 36,
      );
    }
    return Icon(
      LucideIcons.mic,
      color: AppColors.textPrimary(context).withValues(alpha: 0.7),
      size: 36,
    );
  }

  Widget _buildTranscriptArea() {
    if (_statusText.isEmpty && _recognizedText.isEmpty && _aiResponse.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      constraints: const BoxConstraints(maxHeight: 120),
      child: SingleChildScrollView(
        child: Text(
          _statusText,
          style: TextStyle(
            color: _isSpeaking
                ? AppColors.accentDark.withValues(alpha: 0.9)
                : AppColors.textPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _voice.stopListening();
              _voice.stopSpeaking();
              widget.provider.navigation.setCurrentView(ViewState.home);
            },
            child: Semantics(
              button: true,
              label: localeProvider.t('close_voice_mode'),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.divider(context),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  LucideIcons.x,
                  color: AppColors.textSecondary(context),
                  size: 24,
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleListening,
            onLongPress: _isListening ? null : _toggleListening,
            child: Semantics(
              button: true,
              label: _isListening
                  ? localeProvider.t('stop_listening')
                  : localeProvider.t('start_listening'),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.accentDark
                      : _isProcessing
                      ? AppColors.accentDark.withValues(alpha: 0.5)
                      : AppColors.accentDark.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: AppColors.accentDark.withValues(alpha: 0.4),
                            blurRadius: 20,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _isListening ? LucideIcons.square : LucideIcons.mic,
                  color: AppColors.textPrimary(context),
                  size: 28,
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _isMuted = !_isMuted);
              if (_isMuted) {
                _voice.stopSpeaking();
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _isMuted
                    ? AppColors.dng(context).withValues(alpha: 0.8)
                    : AppColors.divider(context),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                _isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                color: _isMuted
                    ? AppColors.textPrimary(context)
                    : AppColors.textSecondary(context),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearConversation() {
    setState(() {
      _recognizedText = '';
      _aiResponse = '';
      _statusText = localeProvider.t('voice_tap_to_start');
    });
    widget.provider.orchestrator.clearConversation();
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashCount = 36;
    final radius = size.width / 2;
    final dashAngle = math.pi * 2 / dashCount;
    final gapAngle = dashAngle * 0.5;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - 1),
        startAngle,
        dashAngle - gapAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
