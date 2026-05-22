enum AgentState {
  idle,
  thinking,
  planning,
  executing,
  waitingTool,
  checking,
  reflecting,
  memorizing,
  recovering,
  interrupted,
  failed,
  completed,
}

enum IntentChannel { fast, slow, mixed }

enum PermissionLevel { auto, confirm, deny }

enum ToolCallPhase {
  created,
  validating,
  pendingPermission,
  executing,
  streamingResult,
  completed,
  failed,
  cancelled,
  timeout,
}

enum ThoughtType {
  analysis,
  planning,
  toolSelection,
  evaluation,
  reflection,
  memory,
}

class ThoughtStep {
  final ThoughtType type;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const ThoughtStep({
    required this.type,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  String get icon {
    switch (type) {
      case ThoughtType.analysis:
        return '🔍';
      case ThoughtType.planning:
        return '📋';
      case ThoughtType.toolSelection:
        return '🔧';
      case ThoughtType.evaluation:
        return '✅';
      case ThoughtType.reflection:
        return '🤔';
      case ThoughtType.memory:
        return '🧠';
    }
  }

  String get label {
    switch (type) {
      case ThoughtType.analysis:
        return 'Analysis';
      case ThoughtType.planning:
        return 'Planning';
      case ThoughtType.toolSelection:
        return 'Tool Selection';
      case ThoughtType.evaluation:
        return 'Evaluation';
      case ThoughtType.reflection:
        return 'Reflection';
      case ThoughtType.memory:
        return 'Memory';
    }
  }
}
