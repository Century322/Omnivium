import 'dart:async';
import '../app_logger.dart';
import '../push_notification_service.dart';
import '../database_service.dart';

enum ReminderType { messageNotification, recurring, scheduled, aiSmart }

enum ReminderStatus { active, paused, completed, cancelled }

class ReminderFrequency {
  final Duration interval;
  final bool isCustom;

  const ReminderFrequency({required this.interval, this.isCustom = false});

  static const everyMinute = ReminderFrequency(
    interval: Duration(minutes: 1),
    isCustom: true,
  );
  static const every30Minutes = ReminderFrequency(
    interval: Duration(minutes: 30),
  );
  static const every2Hours = ReminderFrequency(interval: Duration(hours: 2));
  static const every6Hours = ReminderFrequency(interval: Duration(hours: 6));
  static const everyDay = ReminderFrequency(interval: Duration(hours: 24));

  static ReminderFrequency custom(Duration interval) =>
      ReminderFrequency(interval: interval, isCustom: true);
}

class Reminder {
  final String id;
  final ReminderType type;
  final String title;
  final String description;
  final ReminderFrequency frequency;
  final DateTime createdAt;
  final DateTime? nextTriggerAt;
  final ReminderStatus status;
  final Map<String, dynamic> metadata;
  final String? matrixRoomId;
  final String? aiPrompt;

  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.frequency,
    required this.createdAt,
    this.nextTriggerAt,
    this.status = ReminderStatus.active,
    this.metadata = const {},
    this.matrixRoomId,
    this.aiPrompt,
  });

  Reminder copyWith({ReminderStatus? status, DateTime? nextTriggerAt}) =>
      Reminder(
        id: id,
        type: type,
        title: title,
        description: description,
        frequency: frequency,
        createdAt: createdAt,
        nextTriggerAt: nextTriggerAt ?? this.nextTriggerAt,
        status: status ?? this.status,
        metadata: metadata,
        matrixRoomId: matrixRoomId,
        aiPrompt: aiPrompt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'description': description,
    'frequencyMs': frequency.interval.inMilliseconds,
    'isCustom': frequency.isCustom,
    'createdAt': createdAt.toIso8601String(),
    'nextTriggerAt': nextTriggerAt?.toIso8601String(),
    'status': status.name,
    'metadata': metadata,
    'matrixRoomId': matrixRoomId,
    'aiPrompt': aiPrompt,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    type: ReminderType.values.firstWhere((t) => t.name == json['type']),
    title: json['title'] as String,
    description: json['description'] as String,
    frequency: ReminderFrequency(
      interval: Duration(milliseconds: json['frequencyMs'] as int),
      isCustom: json['isCustom'] as bool? ?? false,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    nextTriggerAt: json['nextTriggerAt'] != null
        ? DateTime.parse(json['nextTriggerAt'] as String)
        : null,
    status: ReminderStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => ReminderStatus.active,
    ),
    metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    matrixRoomId: json['matrixRoomId'] as String?,
    aiPrompt: json['aiPrompt'] as String?,
  );
}

class ReminderService {
  static ReminderService? _instance;
  static ReminderService get instance => _instance ??= ReminderService._();

  ReminderService._();

  Timer? _checkTimer;
  final List<Reminder> _reminders = [];
  final Map<String, int> _consecutiveFailures = {};
  bool _initialized = false;
  Future<String?> Function(String prompt)? _onAiTrigger;
  void Function(Reminder reminder)? _onReminderFired;
  final Map<String, bool> _messageNotificationRooms = {};

  static const _storageKey = 'omnivium_reminders';
  static const _messageNotificationKey = 'omnivium_msg_notifications';

  Future<void> init({
    Future<String?> Function(String prompt)? onAiTrigger,
    void Function(Reminder reminder)? onReminderFired,
  }) async {
    if (_initialized) return;
    _onAiTrigger = onAiTrigger;
    _onReminderFired = onReminderFired;
    await _loadFromStorage();
    _initialized = true;
    AppLogger.instance.info(
      'ReminderService initialized with ${_reminders.length} reminders',
    );
  }

  Future<void> _loadFromStorage() async {
    try {
      final db = DatabaseService.instance;
      final data = db.getData(_storageKey);
      if (data != null) {
        final list = data['reminders'] as List<dynamic>? ?? [];
        for (final json in list) {
          _reminders.add(Reminder.fromJson(json as Map<String, dynamic>));
        }
      }
      final notifData = db.getData(_messageNotificationKey);
      if (notifData != null) {
        final rooms = notifData['rooms'] as List<dynamic>? ?? [];
        for (final entry in rooms) {
          final map = entry as Map<String, dynamic>;
          _messageNotificationRooms[map['roomId'] as String] =
              map['enabled'] as bool? ?? true;
        }
      }
    } catch (e) {
      AppLogger.instance.error(
        'Failed to load reminders from storage',
        error: e,
      );
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final db = DatabaseService.instance;
      await db.putData(_storageKey, {
        'reminders': _reminders.map((r) => r.toJson()).toList(),
      });
      await db.putData(_messageNotificationKey, {
        'rooms': _messageNotificationRooms.entries
            .map((e) => {'roomId': e.key, 'enabled': e.value})
            .toList(),
      });
    } catch (e) {
      AppLogger.instance.error('Failed to save reminders to storage', error: e);
    }
  }

  void setMessageNotification(String roomId, bool enabled) {
    _messageNotificationRooms[roomId] = enabled;
    _saveToStorage();
  }

  bool isMessageNotificationEnabled(String roomId) {
    return _messageNotificationRooms[roomId] ?? true;
  }

  Future<Reminder> createReminder({
    required ReminderType type,
    required String title,
    required String description,
    required ReminderFrequency frequency,
    String? matrixRoomId,
    String? aiPrompt,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    DateTime? nextTrigger;
    switch (type) {
      case ReminderType.messageNotification:
        nextTrigger = null;
        break;
      case ReminderType.recurring:
        nextTrigger = now.add(frequency.interval);
        break;
      case ReminderType.scheduled:
        nextTrigger = now.add(frequency.interval);
        break;
      case ReminderType.aiSmart:
        nextTrigger = now.add(frequency.interval);
        break;
    }

    final reminder = Reminder(
      id: 'rem_${now.millisecondsSinceEpoch}_${_reminders.length}',
      type: type,
      title: title,
      description: description,
      frequency: frequency,
      createdAt: now,
      nextTriggerAt: nextTrigger,
      metadata: metadata ?? {},
      matrixRoomId: matrixRoomId,
      aiPrompt: aiPrompt,
    );

    _reminders.add(reminder);
    await _saveToStorage();
    AppLogger.instance.info(
      'Reminder created: ${reminder.id} (${reminder.type.name})',
    );
    return reminder;
  }

  Future<void> cancelReminder(String reminderId) async {
    final idx = _reminders.indexWhere((r) => r.id == reminderId);
    if (idx < 0) return;
    _reminders[idx] = _reminders[idx].copyWith(
      status: ReminderStatus.cancelled,
    );
    await _saveToStorage();
    AppLogger.instance.info('Reminder cancelled: $reminderId');
  }

  Future<void> pauseReminder(String reminderId) async {
    final idx = _reminders.indexWhere((r) => r.id == reminderId);
    if (idx < 0) return;
    _reminders[idx] = _reminders[idx].copyWith(status: ReminderStatus.paused);
    await _saveToStorage();
  }

  Future<void> resumeReminder(String reminderId) async {
    final idx = _reminders.indexWhere((r) => r.id == reminderId);
    if (idx < 0) return;
    final now = DateTime.now();
    _reminders[idx] = _reminders[idx].copyWith(
      status: ReminderStatus.active,
      nextTriggerAt: now.add(_reminders[idx].frequency.interval),
    );
    await _saveToStorage();
  }

  void startChecking() {
    if (_checkTimer != null) return;
    _checkTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _runChecks(),
    );
    AppLogger.instance.info('ReminderService started periodic checks');
  }

  void stopChecking() {
    _checkTimer?.cancel();
    _checkTimer = null;
    AppLogger.instance.info('ReminderService stopped periodic checks');
  }

  Future<void> _runChecks() async {
    final now = DateTime.now();
    for (int i = 0; i < _reminders.length; i++) {
      final reminder = _reminders[i];
      if (reminder.status != ReminderStatus.active) continue;
      if (reminder.type == ReminderType.messageNotification) continue;

      if (reminder.nextTriggerAt != null &&
          now.isAfter(reminder.nextTriggerAt!)) {
        try {
          await _fireReminder(reminder);
          _consecutiveFailures[reminder.id] = 0;

          if (reminder.type == ReminderType.scheduled) {
            _reminders[i] = reminder.copyWith(status: ReminderStatus.completed);
          } else {
            _reminders[i] = reminder.copyWith(
              nextTriggerAt: now.add(reminder.frequency.interval),
            );
          }
          await _saveToStorage();
        } catch (e) {
          final count = (_consecutiveFailures[reminder.id] ?? 0) + 1;
          _consecutiveFailures[reminder.id] = count;
          if (count >= 5) {
            _reminders[i] = reminder.copyWith(status: ReminderStatus.paused);
            await _saveToStorage();
            AppLogger.instance.warning(
              'Reminder "${reminder.id}" paused after $count failures',
            );
          } else {
            AppLogger.instance.error(
              'Reminder "${reminder.id}" failed',
              error: e,
            );
          }
        }
      }
    }
  }

  Future<void> _fireReminder(Reminder reminder) async {
    String body = reminder.description;

    if (reminder.type == ReminderType.aiSmart && _onAiTrigger != null) {
      final aiResponse = await _onAiTrigger!(
        reminder.aiPrompt ?? reminder.description,
      );
      if (aiResponse != null && aiResponse.isNotEmpty) {
        body = aiResponse.length > 200
            ? '${aiResponse.substring(0, 200)}...'
            : aiResponse;
      }
    }

    await PushNotificationService.instance.showLocalNotification(
      title: reminder.title,
      body: body,
    );

    _onReminderFired?.call(reminder);
    AppLogger.instance.info(
      'Reminder fired: ${reminder.id} (${reminder.type.name})',
    );
  }

  Future<void> fireMessageNotification(
    String roomId,
    String senderName,
    String messagePreview,
  ) async {
    if (!isMessageNotificationEnabled(roomId)) return;
    await PushNotificationService.instance.showLocalNotification(
      title: senderName,
      body: messagePreview.length > 100
          ? '${messagePreview.substring(0, 100)}...'
          : messagePreview,
    );
  }

  List<Reminder> get activeReminders =>
      _reminders.where((r) => r.status == ReminderStatus.active).toList();

  List<Reminder> get allReminders => List.unmodifiable(_reminders);

  List<Reminder> remindersByType(ReminderType type) =>
      _reminders.where((r) => r.type == type).toList();

  Map<String, dynamic> get statusSummary => {
    'total': _reminders.length,
    'active': _reminders.where((r) => r.status == ReminderStatus.active).length,
    'paused': _reminders.where((r) => r.status == ReminderStatus.paused).length,
    'completed': _reminders
        .where((r) => r.status == ReminderStatus.completed)
        .length,
    'messageNotifications': _messageNotificationRooms.length,
  };

  void dispose() {
    stopChecking();
    _reminders.clear();
    _consecutiveFailures.clear();
    _messageNotificationRooms.clear();
    _initialized = false;
    _instance = null;
  }
}
