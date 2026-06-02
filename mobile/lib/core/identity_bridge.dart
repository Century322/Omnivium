
import 'di/app_di.dart';
import 'dart:convert';
import 'app_logger.dart';
import 'secure_storage_service.dart';
import 'runtime/sandbox/sovereign_identity.dart';
import 'runtime/stability/security.dart';

class IdentityBridge {
  static final IdentityBridge _instance = IdentityBridge._();
  static IdentityBridge get instance => _instance;
  IdentityBridge._();

  static const _storageKey = 'omnivium_sovereign_identity';
  static const _omniviumIdKey = 'omnivium_user_id';
  static const _shadowIdentitiesKey = 'omnivium_shadow_identities';
  static const _activeShadowKey = 'omnivium_active_shadow_id';

  SovereignIdentity? _identity;
  String? _omniviumId;
  String? _matrixUserId;
  String? _supabaseUserId;
  List<SovereignIdentity> _shadowIdentities = [];
  String? _activeShadowId;

  SovereignIdentity? get identity => _identity;
  String? get omniviumId => _omniviumId;
  String? get matrixUserId => _matrixUserId;
  String? get supabaseUserId => _supabaseUserId;
  bool get isBound => _identity != null;
  List<SovereignIdentity> get shadowIdentities =>
      List.unmodifiable(_shadowIdentities);
  String? get activeShadowId => _activeShadowId;
  bool get isShadowActive => _activeShadowId != null;

  SovereignIdentity get requireIdentity {
    final id = _identity;
    if (id == null) throw StateError('No identity bound');
    return id;
  }

  SovereignIdentity get activeIdentity {
    if (_activeShadowId != null) {
      final shadow = _shadowIdentities.where(
        (s) => s.nodeId == _activeShadowId);
      if (shadow.isNotEmpty) return shadow.first;
    }
    return _identity ?? SovereignIdentity.generate();
  }

  String get did => activeIdentity.did;
  String get nodeId => activeIdentity.nodeId;
  String get publicKey => activeIdentity.publicKey;
  TrustLevel get trustLevel => activeIdentity.trustLevel;

  Future<void> onRegistration(String email, {String? matrixId}) async {
    _omniviumId = email.split('@').first;
    _matrixUserId = matrixId;
    final existing = await _loadFromStorage();
    if (existing != null) {
      _identity = existing;
      if (matrixId != null && existing.federationId != matrixId) {
        final joined = existing.joinFederation(matrixId);
        _identity = joined;
        await _persistToStorage(joined);
      }
      await _loadShadowIdentities();
      AppLogger.instance.info(
        'IdentityBridge: restored identity ${requireIdentity.did}');
      return;
    }
    final generated = SovereignIdentity.generate(
      nodeId: _omniviumId,
      federationId: matrixId);
    _identity = generated;
    await _persistToStorage(generated);
    final oid = _omniviumId;
    if (oid != null) await _persistOmniviumId(oid);
    AppLogger.instance.info(
      'IdentityBridge: generated root identity ${generated.did}');
  }

  Future<void> onUserAuthenticated(String userId, {String? matrixId}) async {
    _supabaseUserId = userId;
    _matrixUserId = matrixId;
    final existing = await _loadFromStorage();
    if (existing != null) {
      _identity = existing;
      if (matrixId != null && existing.federationId != matrixId) {
        final joined = existing.joinFederation(matrixId);
        _identity = joined;
        await _persistToStorage(joined);
      }
      await _loadShadowIdentities();
      AppLogger.instance.info(
        'IdentityBridge: restored identity ${requireIdentity.did}');
      return;
    }
    final generated = SovereignIdentity.generate(
      nodeId: userId,
      federationId: matrixId);
    _identity = generated;
    await _persistToStorage(generated);
    AppLogger.instance.info(
      'IdentityBridge: generated identity ${generated.did}');
  }

  Future<void> onMatrixLinked(String matrixId) async {
    _matrixUserId = matrixId;
    final id = _identity;
    if (id != null && id.federationId != matrixId) {
      final joined = id.joinFederation(matrixId);
      _identity = joined;
      await _persistToStorage(joined);
    }
  }

  Future<void> updateOmniviumId(String newId) async {
    _omniviumId = newId;
    await _persistOmniviumId(newId);
    AppLogger.instance.info('IdentityBridge: updated Omnivium ID to $newId');
  }

  Future<void> rotateKey() async {
    final id = _identity;
    if (id == null) return;
    final rotated = id.rotateKey();
    _identity = rotated;
    await _persistToStorage(rotated);
    AppLogger.instance.info('IdentityBridge: rotated key for ${rotated.did}');
  }

  Future<SovereignIdentity> createShadowIdentity(String label) async {
    final id = _identity;
    if (id == null) throw StateError('No root identity bound');
    final shadow = SovereignIdentity.deriveSubIdentity(
      id,
      'shadow.$label',
      federationId: _matrixUserId);
    _shadowIdentities.add(shadow);
    await _persistShadowIdentities();
    AppLogger.instance.info(
      'IdentityBridge: created shadow identity ${shadow.did}');
    return shadow;
  }

  Future<void> activateShadow(String? shadowNodeId) async {
    if (shadowNodeId == null) {
      _activeShadowId = null;
    } else {
      final exists = _shadowIdentities.any((s) => s.nodeId == shadowNodeId);
      if (!exists) throw StateError('Shadow identity not found');
      _activeShadowId = shadowNodeId;
    }
    await _persistActiveShadow();
    AppLogger.instance.info(
      'IdentityBridge: ${_activeShadowId != null ? "activated shadow $_activeShadowId" : "switched to root identity"}');
  }

  Future<void> revokeShadow(String shadowNodeId) async {
    _shadowIdentities.removeWhere((s) => s.nodeId == shadowNodeId);
    if (_activeShadowId == shadowNodeId) {
      _activeShadowId = null;
      await _persistActiveShadow();
    }
    await _persistShadowIdentities();
    AppLogger.instance.info(
      'IdentityBridge: revoked shadow identity $shadowNodeId');
  }

  SovereignIdentity deriveAgentIdentity(String agentId) {
    final id = _identity;
    if (id == null) throw StateError('No root identity bound');
    return SovereignIdentity.deriveSubIdentity(id, 'agent.$agentId');
  }

  Future<void> onLogout() async {
    _identity = null;
    _omniviumId = null;
    _matrixUserId = null;
    _supabaseUserId = null;
    _shadowIdentities = [];
    _activeShadowId = null;
    final storage = getIt<SecureStorageService>();
    await storage.delete(_storageKey);
    await storage.delete(_omniviumIdKey);
    await storage.delete(_shadowIdentitiesKey);
    await storage.delete(_activeShadowKey);
    AppLogger.instance.info('IdentityBridge: identity cleared');
  }

  SovereignIdentity? requireIdentityOrNull() {
    if (_identity == null) {
      AppLogger.instance.warning(
        'IdentityBridge: identity required but not bound');
    }
    return _identity;
  }

  Map<String, String> authHeaders() {
    final active = activeIdentity;
    final omniviumId = _omniviumId;
    final activeShadowId = _activeShadowId;
    return {
      'X-DID': active.did,
      'X-Node-Id': active.nodeId,
      'X-Public-Key': active.publicKey,
      'X-Trust-Level': active.trustLevel.name,
      if (omniviumId != null) 'X-Omnivium-Id': omniviumId,
      if (activeShadowId != null) 'X-Shadow-Id': activeShadowId,
    };
  }

  Future<SovereignIdentity?> _loadFromStorage() async {
    try {
      final storage = getIt<SecureStorageService>();
      final raw = await storage.read(_storageKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _deserializeIdentity(json);
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to load identity',
        error: e);
      return null;
    }
  }

  Future<void> _persistToStorage(SovereignIdentity identity) async {
    try {
      final storage = getIt<SecureStorageService>();
      await storage.write(_storageKey, jsonEncode(identity.toJson()));
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to persist identity',
        error: e);
    }
  }

  Future<void> _persistOmniviumId(String id) async {
    try {
      final storage = getIt<SecureStorageService>();
      await storage.write(_omniviumIdKey, id);
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to persist Omnivium ID',
        error: e);
    }
  }

  Future<void> _loadShadowIdentities() async {
    try {
      final storage = getIt<SecureStorageService>();
      final raw = await storage.read(_shadowIdentitiesKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _shadowIdentities = list
          .map((e) => _deserializeIdentity(e as Map<String, dynamic>))
          .toList();
      final activeRaw = await storage.read(_activeShadowKey);
      _activeShadowId = activeRaw;
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to load shadow identities',
        error: e);
    }
  }

  Future<void> _persistShadowIdentities() async {
    try {
      final storage = getIt<SecureStorageService>();
      final encoded = jsonEncode(
        _shadowIdentities.map((e) => e.toJson()).toList());
      await storage.write(_shadowIdentitiesKey, encoded);
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to persist shadow identities',
        error: e);
    }
  }

  Future<void> _persistActiveShadow() async {
    try {
      final storage = getIt<SecureStorageService>();
      final activeShadowId = _activeShadowId;
      if (activeShadowId != null) {
        await storage.write(_activeShadowKey, activeShadowId);
      } else {
        await storage.delete(_activeShadowKey);
      }
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to persist active shadow',
        error: e);
    }
  }

  SovereignIdentity _deserializeIdentity(Map<String, dynamic> json) {
    return SovereignIdentity(
      did: json['did'] as String,
      nodeId: json['nodeId'] as String,
      keyPair: SovereignKeyPair.fromJson(
        json['keyPair'] as Map<String, dynamic>),
      civilizationEpoch: json['epoch'] as int,
      federationId: json['federation'] as String?,
      trustLevel: TrustLevel.values.firstWhere(
        (t) => t.name == json['trust'],
        orElse: () => TrustLevel.untrusted),
      constitutionalAncestry: (json['ancestry'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created'] as int,
      selfSignature: SovereignSignature.fromJson(
        json['selfSig'] as Map<String, dynamic>),
      credentials:
          (json['credentials'] as List<dynamic>?)?.map((c) {
            final m = c as Map<String, dynamic>;
            return VerifiableCredential(
              credentialId: m['id'] as String,
              issuerDid: m['issuer'] as String,
              subjectDid: m['subject'] as String,
              credentialType: m['type'] as String,
              claims: m['claims'] as Map<String, dynamic>? ?? {},
              issuedAt: m['issuedAt'] as int,
              expiresAt: m['expiresAt'] as int,
              proof: m['proof'] as String,
              verificationTag: m['tag'] as String);
          }).toList() ??
          [],
      keyRotationHistory:
          (json['keyRotations'] as List<dynamic>?)
              ?.map(
                (r) => KeyRotationRecord.fromJson(r as Map<String, dynamic>))
              .toList() ??
          []);
  }
}
