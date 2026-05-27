import 'app_logger.dart';
import 'dart:convert';
import 'database_service.dart';
import 'remote_config_service.dart';

class QuickCommand {
  final String id;
  final String name;
  final String emoji;
  final String prompt;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuickCommand({
    required this.id,
    required this.name,
    required this.emoji,
    required this.prompt,
    this.category = 'general',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'prompt': prompt,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory QuickCommand.fromJson(Map<String, dynamic> json) => QuickCommand(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String? ?? '⚡',
    prompt: json['prompt'] as String,
    category: json['category'] as String? ?? 'general',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  QuickCommand copyWith({
    String? name,
    String? emoji,
    String? prompt,
    String? category,
  }) {
    return QuickCommand(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      prompt: prompt ?? this.prompt,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class QuickCommandService {
  static final QuickCommandService _instance = QuickCommandService._();
  static QuickCommandService get instance => _instance;
  QuickCommandService._();

  static const _boxKey = 'omnivium_quick_commands';

  List<QuickCommand> _commands = [];
  List<QuickCommand> get commands => List.unmodifiable(_commands);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final db = DatabaseService.instance;
    if (!db.isInitialized) return;

    final raw = db.data.get(_boxKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _commands = list
            .map((item) => QuickCommand.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e, stackTrace) {
        AppLogger.instance.warning(
          'App error',
          error: e,
          stackTrace: stackTrace,
        );
        _commands = [];
      }
    }

    if (_commands.isEmpty) {
      _commands = _defaultCommands();
      await _save();
    }

    _initialized = true;
  }

  List<QuickCommand> _defaultCommands() {
    final now = DateTime.now();
    final remote = RemoteConfigService.instance.getValue<List<dynamic>>(
      'default_quick_commands',
    );
    if (remote != null && remote.isNotEmpty) {
      return remote.map((item) {
        final m = item as Map<String, dynamic>;
        return QuickCommand(
          id: m['id'] as String? ?? '',
          name: m['name'] as String? ?? '',
          emoji: m['emoji'] as String? ?? '📋',
          prompt: m['prompt'] as String? ?? '',
          category: m['category'] as String? ?? 'tool',
          createdAt: now,
          updatedAt: now,
        );
      }).toList();
    }
    return [
      QuickCommand(
        id: 'qc_search',
        name: '搜索',
        emoji: '🔍',
        prompt: '帮我搜索最新的',
        category: 'tool',
        createdAt: now,
        updatedAt: now,
      ),
      QuickCommand(
        id: 'qc_summarize',
        name: '总结',
        emoji: '📝',
        prompt: '请总结一下我们之前的对话',
        category: 'tool',
        createdAt: now,
        updatedAt: now,
      ),
      QuickCommand(
        id: 'qc_translate',
        name: '翻译',
        emoji: '🌐',
        prompt: '请将以下内容翻译成英文：',
        category: 'tool',
        createdAt: now,
        updatedAt: now,
      ),
      QuickCommand(
        id: 'qc_draw',
        name: '画图',
        emoji: '🎨',
        prompt: '请生成一张图片：',
        category: 'creative',
        createdAt: now,
        updatedAt: now,
      ),
      QuickCommand(
        id: 'qc_email',
        name: '邮件',
        emoji: '📧',
        prompt: '帮我写一封邮件：',
        category: 'creative',
        createdAt: now,
        updatedAt: now,
      ),
      QuickCommand(
        id: 'qc_explain',
        name: '解释',
        emoji: '💡',
        prompt: '请用简单的话解释一下：',
        category: 'tool',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  Future<void> _save() async {
    final db = DatabaseService.instance;
    final jsonList = _commands.map((c) => c.toJson()).toList();
    await db.data.put(_boxKey, jsonEncode(jsonList));
  }

  Future<void> addCommand(QuickCommand command) async {
    _commands.add(command);
    await _save();
  }

  Future<void> updateCommand(QuickCommand command) async {
    final idx = _commands.indexWhere((c) => c.id == command.id);
    if (idx != -1) {
      _commands[idx] = command;
      await _save();
    }
  }

  Future<void> deleteCommand(String id) async {
    _commands.removeWhere((c) => c.id == id);
    await _save();
  }

  Future<void> reorderCommands(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _commands.removeAt(oldIndex);
    _commands.insert(newIndex, item);
    await _save();
  }

  Future<void> resetToDefaults() async {
    _commands = _defaultCommands();
    await _save();
  }

  List<QuickCommand> getCommandsByCategory(String category) {
    return _commands.where((c) => c.category == category).toList();
  }

  Set<String> get categories => _commands.map((c) => c.category).toSet();
}
