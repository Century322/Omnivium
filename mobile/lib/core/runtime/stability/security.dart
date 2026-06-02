import 'dart:typed_data';

enum TrustLevel { system, signed, verified, untrusted, blocked }

enum SignatureAlgorithm { ed25519, rsa256, hmacSha256 }

class PluginSignature {
  final String pluginId;
  final String version;
  final SignatureAlgorithm algorithm;
  final String signerId;
  final Uint8List signature;
  final Uint8List publicKey;
  final int signedAt;

  const PluginSignature({
    required this.pluginId,
    required this.version,
    required this.algorithm,
    required this.signerId,
    required this.signature,
    required this.publicKey,
    required this.signedAt,
  });

  Map<String, dynamic> toJson() => {
    'pluginId': pluginId,
    'version': version,
    'algorithm': algorithm.name,
    'signerId': signerId,
    'signedAt': signedAt,
  };
}

class TrustBoundary {
  final String boundaryId;
  final TrustLevel minimumTrustLevel;
  final Set<String> allowedCapabilities;
  final Set<String> allowedNodes;
  final int maxResourceBudget;
  final bool allowNetworkAccess;
  final bool allowFileSystemAccess;
  final bool allowSubprocess;

  const TrustBoundary({
    required this.boundaryId,
    this.minimumTrustLevel = TrustLevel.verified,
    this.allowedCapabilities = const {},
    this.allowedNodes = const {},
    this.maxResourceBudget = 10000,
    this.allowNetworkAccess = false,
    this.allowFileSystemAccess = false,
    this.allowSubprocess = false,
  });

  bool isCapabilityAllowed(String capabilityId) {
    if (allowedCapabilities.isEmpty) return true;
    return allowedCapabilities.contains(capabilityId) ||
        allowedCapabilities.contains('*');
  }

  bool isNodeAllowed(String nodeId) {
    if (allowedNodes.isEmpty) return true;
    return allowedNodes.contains(nodeId) || allowedNodes.contains('*');
  }

  TrustBoundary merge(TrustBoundary other) => TrustBoundary(
    boundaryId: '${boundaryId}_merged',
    minimumTrustLevel: minimumTrustLevel.index > other.minimumTrustLevel.index
        ? minimumTrustLevel
        : other.minimumTrustLevel,
    allowedCapabilities: allowedCapabilities.intersection(
      other.allowedCapabilities),
    allowedNodes: allowedNodes.intersection(other.allowedNodes),
    maxResourceBudget: maxResourceBudget < other.maxResourceBudget
        ? maxResourceBudget
        : other.maxResourceBudget,
    allowNetworkAccess: allowNetworkAccess && other.allowNetworkAccess,
    allowFileSystemAccess: allowFileSystemAccess && other.allowFileSystemAccess,
    allowSubprocess: allowSubprocess && other.allowSubprocess);
}

class SecretRef {
  final String id;
  final String scope;
  final int createdAt;
  final int expiresAt;

  const SecretRef({
    required this.id,
    required this.scope,
    required this.createdAt,
    required this.expiresAt,
  });

  bool isValidAt(int timestamp) => timestamp < expiresAt;
}

class SecretStore {
  final Map<String, String> _secrets = {};
  final Map<String, SecretRef> _refs = {};
  final Map<String, TrustLevel> _accessLog = {};

  void store(
    String id,
    String value, {
    required String scope,
    required int expiresAt,
  }) {
    _secrets[id] = value;
    _refs[id] = SecretRef(
      id: id,
      scope: scope,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      expiresAt: expiresAt);
  }

  String? retrieve(
    String id, {
    required String requesterId,
    required TrustLevel trustLevel,
  }) {
    final ref = _refs[id];
    if (ref == null) return null;
    if (!ref.isValidAt(DateTime.now().millisecondsSinceEpoch)) {
      _secrets.remove(id);
      _refs.remove(id);
      return null;
    }

    _accessLog[requesterId] = trustLevel;
    return _secrets[id];
  }

  void revoke(String id) {
    _secrets.remove(id);
    _refs.remove(id);
  }

  bool exists(String id) => _secrets.containsKey(id);

  void clear() {
    _secrets.clear();
    _refs.clear();
    _accessLog.clear();
  }
}

class CapabilityAuth {
  final String capabilityId;
  final TrustLevel requiredTrustLevel;
  final bool requiresSignature;
  final bool requiresAudit;
  final int maxInvokePerMinute;
  final Set<String> allowedCallerPatterns;

  const CapabilityAuth({
    required this.capabilityId,
    this.requiredTrustLevel = TrustLevel.verified,
    this.requiresSignature = false,
    this.requiresAudit = false,
    this.maxInvokePerMinute = 1000,
    this.allowedCallerPatterns = const {},
  });

  bool isCallerAllowed(String callerId) {
    if (allowedCallerPatterns.isEmpty) return true;
    for (final pattern in allowedCallerPatterns) {
      if (_matchesPattern(pattern, callerId)) return true;
    }
    return false;
  }

  bool _matchesPattern(String pattern, String value) {
    if (pattern == '*') return true;
    if (pattern.endsWith('.*')) {
      return value.startsWith(pattern.substring(0, pattern.length - 1));
    }
    return pattern == value;
  }
}

class TransportEncryption {
  final bool enabled;
  final String algorithm;
  final int keySize;
  final bool certificatePinning;

  const TransportEncryption({
    this.enabled = false,
    this.algorithm = 'AES-256-GCM',
    this.keySize = 256,
    this.certificatePinning = false,
  });
}

class SecurityPolicy {
  final TrustLevel minimumPluginTrustLevel;
  final TrustLevel minimumRemoteNodeTrustLevel;
  final bool enforcePluginSigning;
  final bool enforceTransportEncryption;
  final TransportEncryption transportEncryption;
  final int maxAuthRetries;
  final Duration authLockoutDuration;
  final bool auditAllCapabilityInvocations;
  final bool auditAllPolicyDecisions;

  const SecurityPolicy({
    this.minimumPluginTrustLevel = TrustLevel.verified,
    this.minimumRemoteNodeTrustLevel = TrustLevel.verified,
    this.enforcePluginSigning = false,
    this.enforceTransportEncryption = false,
    this.transportEncryption = const TransportEncryption(),
    this.maxAuthRetries = 5,
    this.authLockoutDuration = const Duration(minutes: 5),
    this.auditAllCapabilityInvocations = true,
    this.auditAllPolicyDecisions = true,
  });
}

class SecurityManager {
  final SecurityPolicy _policy;
  final SecretStore _secretStore;
  final Map<String, PluginSignature> _signatures = {};
  final Map<String, TrustLevel> _pluginTrustLevels = {};
  final Map<String, CapabilityAuth> _capabilityAuths = {};
  final Map<String, TrustBoundary> _trustBoundaries = {};
  final Map<String, int> _authRetryCount = {};
  final Map<String, int> _authLockoutUntil = {};
  final List<SecurityAuditEntry> _auditLog = [];
  int _auditSeq = 0;

  SecurityManager({SecurityPolicy policy = const SecurityPolicy()})
    : _policy = policy,
      _secretStore = SecretStore();

  SecurityPolicy get policy => _policy;
  SecretStore get secretStore => _secretStore;

  void registerSignature(PluginSignature signature) {
    _signatures[signature.pluginId] = signature;
    _pluginTrustLevels[signature.pluginId] = TrustLevel.signed;
  }

  void setPluginTrustLevel(String pluginId, TrustLevel level) {
    _pluginTrustLevels[pluginId] = level;
  }

  void registerCapabilityAuth(CapabilityAuth auth) {
    _capabilityAuths[auth.capabilityId] = auth;
  }

  void registerTrustBoundary(TrustBoundary boundary) {
    _trustBoundaries[boundary.boundaryId] = boundary;
  }

  TrustLevel pluginTrustLevel(String pluginId) =>
      _pluginTrustLevels[pluginId] ?? TrustLevel.untrusted;

  bool isPluginAllowed(String pluginId) {
    final trust = _pluginTrustLevels[pluginId] ?? TrustLevel.untrusted;
    if (trust == TrustLevel.blocked) return false;
    if (trust.index > _policy.minimumPluginTrustLevel.index) return false;

    if (_policy.enforcePluginSigning && _signatures[pluginId] == null) {
      return false;
    }

    return true;
  }

  bool isCapabilityInvocationAllowed(
    String capabilityId,
    String callerId,
    TrustLevel callerTrust) {
    final auth = _capabilityAuths[capabilityId];
    if (auth == null)
      return callerTrust.index <= _policy.minimumPluginTrustLevel.index;

    if (callerTrust.index > auth.requiredTrustLevel.index) return false;
    if (!auth.isCallerAllowed(callerId)) return false;

    return true;
  }

  bool isRemoteNodeAllowed(String nodeId, TrustLevel trustLevel) {
    if (trustLevel == TrustLevel.blocked) return false;
    return trustLevel.index <= _policy.minimumRemoteNodeTrustLevel.index;
  }

  bool checkAuthRateLimit(String identityId) {
    final now = DateTime.now().millisecondsSinceEpoch;

    final lockoutUntil = _authLockoutUntil[identityId];
    if (lockoutUntil != null && now < lockoutUntil) return false;

    final retries = _authRetryCount[identityId] ?? 0;
    if (retries >= _policy.maxAuthRetries) {
      _authLockoutUntil[identityId] =
          now + _policy.authLockoutDuration.inMilliseconds;
      _authRetryCount[identityId] = 0;
      return false;
    }

    return true;
  }

  void recordAuthFailure(String identityId) {
    _authRetryCount[identityId] = (_authRetryCount[identityId] ?? 0) + 1;
  }

  void recordAuthSuccess(String identityId) {
    _authRetryCount.remove(identityId);
    _authLockoutUntil.remove(identityId);
  }

  void audit(
    String action,
    String actorId, {
    Map<String, dynamic> context = const {},
    bool success = true,
  }) {
    _auditLog.add(
      SecurityAuditEntry(
        id: _auditSeq++,
        action: action,
        actorId: actorId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        context: context,
        success: success));
  }

  List<SecurityAuditEntry> auditLog({int? limit}) {
    final log = List<SecurityAuditEntry>.unmodifiable(_auditLog);
    if (limit != null && log.length > limit) {
      return log.sublist(log.length - limit);
    }
    return log;
  }

  TrustBoundary? trustBoundary(String boundaryId) =>
      _trustBoundaries[boundaryId];

  void clearAuditLog() => _auditLog.clear();
}

class SecurityAuditEntry {
  final int id;
  final String action;
  final String actorId;
  final int timestamp;
  final Map<String, dynamic> context;
  final bool success;

  const SecurityAuditEntry({
    required this.id,
    required this.action,
    required this.actorId,
    required this.timestamp,
    this.context = const {},
    required this.success,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'action': action,
    'actor': actorId,
    'ts': timestamp,
    'ctx': context,
    'ok': success,
  };
}
