import '../remote_config_service.dart';

int estimateTokens(String text) {
  if (text.isEmpty) return 0;
  int tokens = 0;
  int i = 0;
  while (i < text.length) {
    final codeUnit = text.codeUnitAt(i);
    if (codeUnit > 0x7F) {
      tokens += 2;
      i++;
    } else if (_isWhitespace(codeUnit)) {
      tokens += 1;
      i++;
    } else {
      final wordStart = i;
      while (i < text.length && !_isWhitespace(text.codeUnitAt(i)) && text.codeUnitAt(i) <= 0x7F) {
        i++;
      }
      final wordLen = i - wordStart;
      tokens += 1 + (wordLen > 6 ? (wordLen - 6) ~/ 4 : 0);
    }
  }
  return (tokens * 1.1).ceil();
}

bool _isWhitespace(int codeUnit) =>
    codeUnit == 0x20 || codeUnit == 0x09 || codeUnit == 0x0A || codeUnit == 0x0D;

class ContextBudget {
  final int maxTokens;
  final int reservedForResponse;
  final int reservedForTools;
  final int reservedForMemory;
  final int reservedForSystem;

  const ContextBudget({
    this.maxTokens = 128000,
    this.reservedForResponse = 4096,
    this.reservedForTools = 2048,
    this.reservedForMemory = 4096,
    this.reservedForSystem = 1024,
  });

  factory ContextBudget.fromRemote() {
    final rc = RemoteConfigService.instance;
    return ContextBudget(
      maxTokens: rc.getValue<int>('context_max_tokens') ?? 128000,
      reservedForResponse: rc.getValue<int>('context_reserved_response') ?? 4096,
      reservedForTools: rc.getValue<int>('context_reserved_tools') ?? 2048,
      reservedForMemory: rc.getValue<int>('context_reserved_memory') ?? 4096,
      reservedForSystem: rc.getValue<int>('context_reserved_system') ?? 1024,
    );
  }

  int get availableForHistory {
    final available = maxTokens - reservedForResponse - reservedForTools - reservedForMemory - reservedForSystem;
    return available < 0 ? 0 : available;
  }
}

class ContextBudgetManager {
  final ContextBudget _budget;
  int _usedTokens = 0;

  ContextBudgetManager([ContextBudget? budget]) : _budget = budget ?? ContextBudget.fromRemote();

  ContextBudget get budget => _budget;
  int get usedTokens => _usedTokens;
  int get remainingTokens => (_budget.maxTokens - _usedTokens).clamp(0, _budget.maxTokens);
  double get usageRatio => _usedTokens / _budget.maxTokens;

  bool canFit(int tokens) => _usedTokens + tokens <= _budget.availableForHistory;

  bool allocate(int tokens) {
    if (_usedTokens + tokens > _budget.availableForHistory) return false;
    _usedTokens += tokens;
    return true;
  }

  void release(int tokens) {
    _usedTokens = (_usedTokens - tokens).clamp(0, _budget.maxTokens);
  }

  void reset() {
    _usedTokens = 0;
  }
}
