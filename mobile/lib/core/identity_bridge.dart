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

  SovereignIdentity get activeIdentity {
    if (_activeShadowId != null) {
      final shadow = _shadowIdentities.where(
        (s) => s.nodeId == _activeShadowId,
      );
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
        _identity = existing.joinFederation(matrixId);
        await _persistToStorage(_identity!);
      }
      await _loadShadowIdentities();
      AppLogger.instance.info(
        'IdentityBridge: restored identity ${_identity!.did}',
      );
      return;
    }
    _identity = SovereignIdentity.generate(
      nodeId: _omniviumId,
      federationId: matrixId,
    );
    await _persistToStorage(_identity!);
    await _persistOmniviumId(_omniviumId!);
    AppLogger.instance.info(
      'IdentityBridge: generated root identity ${_identity!.did}',
    );
  }

  Future<void> onUserAuthenticated(String userId, {String? matrixId}) async {
    _supabaseUserId = userId;
    _matrixUserId = matrixId;
    final existing = await _loadFromStorage();
    if (existing != null) {
      _identity = existing;
      if (matrixId != null && existing.federationId != matrixId) {
        _identity = existing.joinFederation(matrixId);
        await _persistToStorage(_identity!);
      }
      await _loadShadowIdentities();
      AppLogger.instance.info(
        'IdentityBridge: restored identity ${_identity!.did}',
      );
      return;
    }
    _identity = SovereignIdentity.generate(
      nodeId: userId,
      federationId: matrixId,
    );
    await _persistToStorage(_identity!);
    AppLogger.instance.info(
      'IdentityBridge: generated identity ${_identity!.did}',
    );
  }

  Future<void> onMatrixLinked(String matrixId) async {
    _matrixUserId = matrixId;
    if (_identity != null && _identity!.federationId != matrixId) {
      _identity = _identity!.joinFederation(matrixId);
      await _persistToStorage(_identity!);
    }
  }

  Future<void> updateOmniviumId(String newId) async {
    _omniviumId = newId;
    await _persistOmniviumId(newId);
    AppLogger.instance.info('IdentityBridge: updated Omnivium ID to $newId');
  }

  Future<void> rotateKey() async {
    if (_identity == null) return;
    _identity = _identity!.rotateKey();
    await _persistToStorage(_identity!);
    AppLogger.instance.info(
      'IdentityBridge: rotated key for ${_identity!.did}',
    );
  }

  Future<SovereignIdentity> createShadowIdentity(String label) async {
    if (_identity == null) throw StateError('No root identity bound');
    final shadow = SovereignIdentity.deriveSubIdentity(
      _identity!,
      'shadow.$label',
      federationId: _matrixUserId,
    );
    _shadowIdentities.add(shadow);
    await _persistShadowIdentities();
    AppLogger.instance.info(
      'IdentityBridge: created shadow identity ${shadow.did}',
    );
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
      'IdentityBridge: ${_activeShadowId != null ? "activated shadow $_activeShadowId" : "switched to root identity"}',
    );
  }

  Future<void> revokeShadow(String shadowNodeId) async {
    _shadowIdentities.removeWhere((s) => s.nodeId == shadowNodeId);
    if (_activeShadowId == shadowNodeId) {
      _activeShadowId = null;
      await _persistActiveShadow();
    }
    await _persistShadowIdentities();
    AppLogger.instance.info(
      'IdentityBridge: revoked shadow identity $shadowNodeId',
    );
  }

  SovereignIdentity deriveAgentIdentity(String agentId) {
    if (_identity == null) throw StateError('No root identity bound');
    return SovereignIdentity.deriveSubIdentity(_identity!, 'agent.$agentId');
  }

  Future<void> onLogout() async {
    _identity = null;
    _omniviumId = null;
    _matrixUserId = null;
    _supabaseUserId = null;
    _shadowIdentities = [];
    _activeShadowId = null;
    final storage = SecureStorageService.instance;
    await storage.delete(_storageKey);
    await storage.delete(_omniviumIdKey);
    await storage.delete(_shadowIdentitiesKey);
    await storage.delete(_activeShadowKey);
    AppLogger.instance.info('IdentityBridge: identity cleared');
  }

  SovereignIdentity? requireIdentity() {
    if (_identity == null) {
      AppLogger.instance.warning(
        'IdentityBridge: identity required but not bound',
      );
    }
    return _identity;
  }

  Map<String, String> authHeaders() {
    final active = activeIdentity;
    return {
      'X-DID': active.did,
      'X-Node-Id': active.nodeId,
      'X-Public-Key': active.publicKey,
      'X-Trust-Level': active.trustLevel.name,
      'X-Omnivium-Id': ?_omniviumId,
      if (_activeShadowId != null) 'X-Shadow-Id': ?_activeShadowId,
    };
  }

  Future<SovereignIdentity?> _loadFromStorage() async {
    try {
      final storage = SecureStorageService.instance;
      final raw = await storage.read(_storageKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _deserializeIdentity(json);
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to load identity',
        error: e,
      );
      return null;
    }
  }

  Future<void> _persistToStorage(SovereignIdentity identity) async {
    try {
      final storage = SecureStorageService.instance;
      await storage.write(_storageKey, jsonEncode(identity.toJson()));
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to persist identity',
        error: e,
      );
    }
  }

  Future<void> _persistOmniviumId(String id) async {
    try {
      final storage = SecureStorageService.instance;
      await storage.write(_omniviumIdKey, id);
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to persist Omnivium ID',
        error: e,
      );
    }
  }

  Future<void> _loadShadowIdentities() async {
    try {
      final storage = SecureStorageService.instance;
      final raw = await storage.read(_shadowIdentitiesKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List<dynamic>;
      _shadowIdentities = list
          .map((j) => _deserializeIdentity(j as Map<String, dynamic>))
          .toList();
      final activeId = await storage.read(_activeShadowKey);
      if (activeId != null &&
          _shadowIdentities.any((s) => s.nodeId == activeId)) {
        _activeShadowId = activeId;
      }
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to load shadow identities',
        error: e,
      );
    }
  }

  Future<void> _persistShadowIdentities() async {
    try {
      final storage = SecureStorageService.instance;
      final data = _shadowIdentities.map((s) => s.toJson()).toList();
      await storage.write(_shadowIdentitiesKey, jsonEncode(data));
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to persist shadow identities',
        error: e,
      );
    }
  }

  Future<void> _persistActiveShadow() async {
    try {
      final storage = SecureStorageService.instance;
      if (_activeShadowId != null) {
        await storage.write(_activeShadowKey, _activeShadowId!);
      } else {
        await storage.delete(_activeShadowKey);
      }
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to persist active shadow',
        error: e,
      );
    }
  }

  SovereignIdentity _deserializeIdentity(Map<String, dynamic> json) {
    final keyPairJson = json['keyPair'] as Map<String, dynamic>;
    final sigJson = json['selfSig'] as Map<String, dynamic>;
    final credsJson = json['credentials'] as List<dynamic>? ?? [];
    final rotationsJson = json['keyRotations'] as List<dynamic>? ?? [];

    return SovereignIdentity(
      did: json['did'] as String,
      nodeId: json['nodeId'] as String,
      keyPair: SovereignKeyPair.fromJson(keyPairJson),
      civilizationEpoch: json['epoch'] as int,
      federationId: json['federation'] as String?,
      trustLevel: TrustLevel.values.firstWhere(
        (t) => t.name == json['trust'],
        orElse: () => TrustLevel.untrusted,
      ),
      constitutionalAncestry: (json['ancestry'] as List<dynamic>)
          .cast<String>(),
      createdAt: json['created'] as int,
      selfSignature: SovereignSignature.fromJson(sigJson),
      credentials: credsJson
          .map((c) => _deserializeCredential(c as Map<String, dynamic>))
          .toList(),
      keyRotationHistory: rotationsJson
          .map((r) => KeyRotationRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  VerifiableCredential _deserializeCredential(Map<String, dynamic> json) {
    return VerifiableCredential(
      credentialId: json['id'] as String,
      issuerDid: json['issuer'] as String,
      subjectDid: json['subject'] as String,
      credentialType: json['type'] as String,
      claims: (json['claims'] as Map<String, dynamic>?) ?? {},
      issuedAt: json['issuedAt'] as int,
      expiresAt: json['expiresAt'] as int? ?? 0,
      proof: json['proof'] as String? ?? '',
      verificationTag: json['verificationTag'] as String? ?? '',
    );
  }
}
