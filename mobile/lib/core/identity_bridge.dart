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

  SovereignIdentity? _identity;
  String? _omniviumId;
  String? _matrixUserId;
  String? _supabaseUserId;

  SovereignIdentity? get identity => _identity;
  String? get omniviumId => _omniviumId;
  String? get matrixUserId => _matrixUserId;
  String? get supabaseUserId => _supabaseUserId;
  bool get isBound => _identity != null;

  String get did => _identity?.did ?? '';
  String get nodeId => _identity?.nodeId ?? '';
  String get publicKey => _identity?.publicKey ?? '';
  TrustLevel get trustLevel => _identity?.trustLevel ?? TrustLevel.untrusted;

  Future<void> onRegistration(String email, {String? omniviumId}) async {
    _omniviumId = omniviumId ?? email.split('@').first;
    final existing = await _loadFromStorage();
    if (existing != null) {
      _identity = existing;
      AppLogger.instance.info(
        'IdentityBridge: restored identity ${_identity!.did}',
      );
      return;
    }
    _identity = SovereignIdentity.generate(federationId: _omniviumId);
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

  SovereignIdentity deriveShadowIdentity(String shadowId) {
    if (_identity == null) throw StateError('No root identity bound');
    return SovereignIdentity.deriveSubIdentity(
      _identity!,
      'shadow.$shadowId',
      federationId: _matrixUserId,
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
    final storage = SecureStorageService.instance;
    await storage.delete(_storageKey);
    await storage.delete(_omniviumIdKey);
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
    if (_identity == null) return {};
    return {
      'X-DID': _identity!.did,
      'X-Node-Id': _identity!.nodeId,
      'X-Public-Key': _identity!.publicKey,
      'X-Trust-Level': _identity!.trustLevel.name,
      if (_omniviumId != null) 'X-Omnivium-Id': _omniviumId,
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

  // ignore: unused_element
  Future<void> _loadOmniviumId() async {
    try {
      final storage = SecureStorageService.instance;
      _omniviumId = await storage.read(_omniviumIdKey);
    } catch (e) {
      AppLogger.instance.warning(
        'IdentityBridge: failed to load Omnivium ID',
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
