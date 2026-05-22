import 'dart:async';

enum CardLifecycle {
  created,
  rendering,
  streaming,
  interactive,
  fullscreen,
  expired,
  dismissed,
}

class CardState {
  final String id;
  final String type;
  final CardLifecycle lifecycle;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final Duration ttl;

  const CardState({
    required this.id,
    required this.type,
    this.lifecycle = CardLifecycle.created,
    this.data = const {},
    required this.createdAt,
    this.ttl = const Duration(hours: 24),
  });

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;

  CardState copyWith({
    CardLifecycle? lifecycle,
    Map<String, dynamic>? data,
    Duration? ttl,
  }) =>
      CardState(
        id: id,
        type: type,
        lifecycle: lifecycle ?? this.lifecycle,
        data: data ?? this.data,
        createdAt: createdAt,
        ttl: ttl ?? this.ttl,
      );
}

class CardRuntime {
  final Map<String, CardState> _cards = {};
  Timer? _expiryTimer;
  static const _expiryCheckInterval = Duration(minutes: 5);

  Map<String, CardState> get cards => Map.unmodifiable(_cards);

  CardRuntime({bool autoStartTimer = true}) {
    if (autoStartTimer) _startExpiryTimer();
  }

  void ensureTimerStarted() {
    if (_expiryTimer == null) _startExpiryTimer();
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(_expiryCheckInterval, (_) => expireCards());
  }

  CardState create(String type, {Map<String, dynamic> data = const {}, Duration? ttl}) {
    final baseId = DateTime.now().millisecondsSinceEpoch;
    var id = 'card_$baseId';
    var counter = 0;
    while (_cards.containsKey(id)) {
      counter++;
      id = 'card_${baseId}_$counter';
    }
    final card = CardState(
      id: id,
      type: type,
      data: data,
      createdAt: DateTime.now(),
      ttl: ttl ?? const Duration(hours: 24),
    );
    _cards[id] = card;
    return card;
  }

  CardState? get(String id) => _cards[id];

  CardState? update(String id, {CardLifecycle? lifecycle, Map<String, dynamic>? data, Duration? ttl}) {
    final card = _cards[id];
    if (card == null) return null;
    final updated = card.copyWith(lifecycle: lifecycle, data: data, ttl: ttl);
    _cards[id] = updated;
    return updated;
  }

  void dismiss(String id) {
    _cards.remove(id);
  }

  void expireCards() {
    _cards.removeWhere((_, card) => card.isExpired);
  }

  void dispose() {
    _expiryTimer?.cancel();
    _cards.clear();
  }
}
