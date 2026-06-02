import 'cognitive_types.dart';
import 'entity_store.dart';
import 'speaker_graph.dart';

class PerceptionResult {
  final String speakerId;
  final String speakerType;
  final String? speakerName;
  final MessageFormat format;
  final MemoryDomain domain;
  final List<String> detectedEntities;
  final List<String> detectedTopics;
  final bool isQuestion;
  final bool isCommand;
  final bool isEmotional;
  final String? language;
  final Map<String, dynamic> metadata;

  const PerceptionResult({
    this.speakerId = 'user',
    this.speakerType = 'user',
    this.speakerName,
    this.format = MessageFormat.text,
    this.domain = MemoryDomain.personal,
    this.detectedEntities = const [],
    this.detectedTopics = const [],
    this.isQuestion = false,
    this.isCommand = false,
    this.isEmotional = false,
    this.language,
    this.metadata = const {},
  });
}

enum MessageFormat {
  text,
  code,
  markdown,
  mixed,
}

class PerceptionEngine {
  final EntityStore entityStore;
  final SpeakerGraph speakerGraph;

  PerceptionEngine({
    required this.entityStore,
    required this.speakerGraph,
  });

  PerceptionResult perceive(String message, {String? speakerId}) {
    final resolvedSpeaker = _identifySpeaker(speakerId ?? 'user');
    final format = _detectFormat(message);
    final domain = _detectDomain(message);
    final entities = _detectEntities(message);
    final topics = _detectTopics(message);
    final isQuestion = _detectQuestion(message);
    final isCommand = _detectCommand(message);
    final isEmotional = _detectEmotional(message);
    final language = _detectLanguage(message);

    return PerceptionResult(
      speakerId: resolvedSpeaker.$1,
      speakerType: resolvedSpeaker.$2,
      speakerName: resolvedSpeaker.$3,
      format: format,
      domain: domain,
      detectedEntities: entities,
      detectedTopics: topics,
      isQuestion: isQuestion,
      isCommand: isCommand,
      isEmotional: isEmotional,
      language: language,
    );
  }

  (String, String, String?) _identifySpeaker(String speakerId) {
    if (speakerId == 'agent') return ('agent', 'agent', 'Omni');

    final speaker = speakerGraph.getSpeaker(speakerId);
    if (speaker != null) {
      return (speaker.speakerId, speaker.speakerType, speaker.displayName);
    }

    return (speakerId, 'user', null);
  }

  MessageFormat _detectFormat(String message) {
    final codeIndicators = [
      RegExp(r'```[\s\S]*?```'),
      RegExp(r'^\s*(import|class|function|def |var |let |const |return )', multiLine: true),
      RegExp(r'[{}\[\];]\s*$', multiLine: true),
      RegExp(r'^\s*//', multiLine: true),
    ];

    var codeScore = 0;
    for (final pattern in codeIndicators) {
      if (pattern.hasMatch(message)) codeScore++;
    }

    final hasMarkdown = RegExp(r'[#*_~`>|]').hasMatch(message);

    if (codeScore >= 2) return MessageFormat.code;
    if (codeScore == 1 && hasMarkdown) return MessageFormat.mixed;
    if (hasMarkdown) return MessageFormat.markdown;
    if (codeScore == 1) return MessageFormat.mixed;
    return MessageFormat.text;
  }

  MemoryDomain _detectDomain(String message) {
    final lower = message.toLowerCase();

    final domainKeywords = <MemoryDomain, List<String>>{
      MemoryDomain.project: ['项目', 'project', '开发', 'develop', '产品', 'product', 'app', '应用', '版本', 'release', '部署', 'deploy'],
      MemoryDomain.friend: ['朋友', 'friend', '好友', '聊天', '认识', '介绍'],
      MemoryDomain.business: ['公司', 'company', '商业', 'business', '客户', 'client', '合同', 'contract', '收入', 'revenue'],
      MemoryDomain.research: ['研究', 'research', '论文', 'paper', '实验', 'experiment', '分析', 'analysis', '数据', 'data'],
      MemoryDomain.entertainment: ['游戏', 'game', '电影', 'movie', '音乐', 'music', '书', 'book', '小说', 'novel'],
    };

    MemoryDomain bestDomain = MemoryDomain.personal;
    var bestScore = 0;

    for (final entry in domainKeywords.entries) {
      var score = 0;
      for (final kw in entry.value) {
        if (lower.contains(kw)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestDomain = entry.key;
      }
    }

    return bestDomain;
  }

  List<String> _detectEntities(String message) {
    final detected = <String>[];
    final lower = message.toLowerCase();

    for (final entity in entityStore.entities) {
      if (lower.contains(entity.name.toLowerCase())) {
        detected.add(entity.name);
      }
    }

    return detected;
  }

  List<String> _detectTopics(String message) {
    final lower = message.toLowerCase();
    final topicKeywords = <String, List<String>>{
      'architecture': ['架构', 'architecture', '设计', 'design', '结构', 'structure'],
      'performance': ['性能', 'performance', '优化', 'optimization', '速度', 'speed'],
      'security': ['安全', 'security', '加密', 'encryption', '认证', 'auth'],
      'testing': ['测试', 'test', '调试', 'debug', '验证', 'verify'],
      'deployment': ['部署', 'deploy', '上线', 'launch', '发布', 'release'],
      'ui': ['界面', 'ui', '交互', 'interaction', '样式', 'style'],
      'backend': ['后端', 'backend', '服务器', 'server', 'api', '数据库', 'database'],
      'ai': ['ai', '人工智能', '模型', 'model', '训练', 'training', 'agent'],
    };

    final topics = <String>[];
    for (final entry in topicKeywords.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) {
          topics.add(entry.key);
          break;
        }
      }
    }

    return topics;
  }

  bool _detectQuestion(String message) {
    return message.contains('?') || message.contains('？') ||
           message.toLowerCase().startsWith(RegExp(r'^(what|who|where|when|why|how|is|are|can|do|does|will|什么|谁|哪|为什么|怎么|如何|是否)'));
  }

  bool _detectCommand(String message) {
    final lower = message.toLowerCase();
    return lower.startsWith(RegExp(r'^(请|帮我|帮我|create|delete|remove|add|update|set|get|list|show|run|execute|start|stop|打开|关闭|删除|添加|创建|运行|执行)'));
  }

  bool _detectEmotional(String message) {
    final emotionalPatterns = [
      RegExp(r'[！!]{2,}'),
      RegExp(r'[？?]{2,}'),
      RegExp(r'(太|好|超|特别|非常|极其|真的|really|very|so|extremely)'),
      RegExp(r'(开心|难过|生气|焦虑|兴奋|沮丧|害怕|担心|happy|sad|angry|anxious|excited|frustrated|scared|worried)'),
    ];

    for (final pattern in emotionalPatterns) {
      if (pattern.hasMatch(message)) return true;
    }
    return false;
  }

  String? _detectLanguage(String message) {
    final chineseChars = RegExp(r'[\u4e00-\u9fff]').allMatches(message).length;
    final totalChars = message.replaceAll(RegExp(r'\s'), '').length;
    if (totalChars == 0) return null;

    final chineseRatio = chineseChars / totalChars;
    if (chineseRatio > 0.3) return 'zh';
    return 'en';
  }
}
