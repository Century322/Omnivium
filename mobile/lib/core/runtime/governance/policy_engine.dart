enum PolicyEffect { allow, deny }

enum PolicyScope { own, session, node, cluster }

class PolicyRule {
  final String id;
  final String description;
  final PolicyEffect effect;
  final String callerPattern;
  final String targetPattern;
  final PolicyScope maxScope;
  final int priority;
  final Map<String, dynamic> conditions;

  const PolicyRule({
    required this.id,
    required this.description,
    required this.effect,
    this.callerPattern = '*',
    this.targetPattern = '*',
    this.maxScope = PolicyScope.cluster,
    this.priority = 0,
    this.conditions = const {},
  });

  bool matchesCaller(String callerId) => _match(callerPattern, callerId);
  bool matchesTarget(String capabilityId) =>
      _match(targetPattern, capabilityId);

  bool _match(String pattern, String value) {
    if (pattern == '*') return true;
    if (pattern.endsWith('.*')) {
      return value.startsWith(pattern.substring(0, pattern.length - 1));
    }
    return pattern == value;
  }
}

class PolicyDecision {
  final bool allowed;
  final String? matchedRuleId;
  final String reason;

  const PolicyDecision({
    required this.allowed,
    this.matchedRuleId,
    this.reason = '',
  });

  factory PolicyDecision.allow(String ruleId) => PolicyDecision(
    allowed: true,
    matchedRuleId: ruleId,
    reason: 'Allowed by rule: $ruleId',
  );

  factory PolicyDecision.deny(String ruleId) => PolicyDecision(
    allowed: false,
    matchedRuleId: ruleId,
    reason: 'Denied by rule: $ruleId',
  );

  factory PolicyDecision.implicitDeny(String caller, String target) =>
      PolicyDecision(
        allowed: false,
        reason: 'No matching policy for $caller -> $target',
      );
}

class PolicyEngine {
  final List<PolicyRule> _rules = [];

  List<PolicyRule> get rules => List.unmodifiable(_rules);
  int get ruleCount => _rules.length;

  void addRule(PolicyRule rule) {
    _rules.add(rule);
    _rules.sort((a, b) => b.priority.compareTo(a.priority));
  }

  void removeRule(String ruleId) {
    _rules.removeWhere((r) => r.id == ruleId);
  }

  void clearRules() => _rules.clear();

  PolicyDecision evaluate({
    required String callerId,
    required String targetCapability,
    PolicyScope scope = PolicyScope.own,
  }) {
    PolicyDecision? lastMatch;

    for (final rule in _rules) {
      if (!rule.matchesCaller(callerId)) continue;
      if (!rule.matchesTarget(targetCapability)) continue;

      if (scope.index > rule.maxScope.index) {
        lastMatch = PolicyDecision.deny(rule.id);
        continue;
      }

      if (rule.effect == PolicyEffect.deny) {
        return PolicyDecision.deny(rule.id);
      }

      lastMatch = PolicyDecision.allow(rule.id);
    }

    return lastMatch ?? PolicyDecision.implicitDeny(callerId, targetCapability);
  }

  bool isAllowed(
    String callerId,
    String targetCapability, {
    PolicyScope scope = PolicyScope.own,
  }) {
    return evaluate(
      callerId: callerId,
      targetCapability: targetCapability,
      scope: scope,
    ).allowed;
  }

  static PolicyEngine defaultPolicy() {
    final engine = PolicyEngine();

    engine.addRule(
      const PolicyRule(
        id: 'deny-agent-delete-storage',
        description: 'agent.* cannot storage.delete',
        effect: PolicyEffect.deny,
        callerPattern: 'agent.*',
        targetPattern: 'storage.delete',
        priority: 100,
      ),
    );

    engine.addRule(
      const PolicyRule(
        id: 'deny-background-network',
        description: 'background plugins cannot access network.*',
        effect: PolicyEffect.deny,
        callerPattern: 'background.*',
        targetPattern: 'network.*',
        priority: 100,
      ),
    );

    engine.addRule(
      const PolicyRule(
        id: 'deny-sandbox-runtime',
        description: 'Level 2+ plugins cannot access runtime.*',
        effect: PolicyEffect.deny,
        callerPattern: 'sandbox.*',
        targetPattern: 'runtime.*',
        priority: 100,
      ),
    );

    engine.addRule(
      const PolicyRule(
        id: 'deny-chaos-production',
        description: 'chaos-agent cannot run in production',
        effect: PolicyEffect.deny,
        callerPattern: 'chaos-agent',
        targetPattern: '*',
        priority: 200,
        conditions: {'environment': 'production'},
      ),
    );

    engine.addRule(
      const PolicyRule(
        id: 'allow-all-default',
        description: 'Default allow all',
        effect: PolicyEffect.allow,
        callerPattern: '*',
        targetPattern: '*',
        priority: 0,
      ),
    );

    return engine;
  }
}
