import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import '../stability/security.dart';

enum SovereignIdentityAlgorithm { ed25519 }

class SovereignKeyPair {
  final String publicKey;
  final String privateKey;
  final String verificationKey;
  final SovereignIdentityAlgorithm algorithm;
  final int createdAt;

  const SovereignKeyPair({
    required this.publicKey,
    required this.privateKey,
    required this.verificationKey,
    required this.algorithm,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'publicKey': publicKey,
    'privateKey': privateKey,
    'verificationKey': verificationKey,
    'algorithm': algorithm.name,
    'createdAt': createdAt,
  };

  static SovereignKeyPair fromJson(Map<String, dynamic> json) =>
      SovereignKeyPair(
        publicKey: json['publicKey'] as String,
        privateKey: json['privateKey'] as String,
        verificationKey: json['verificationKey'] as String,
        algorithm: SovereignIdentityAlgorithm.values.firstWhere(
          (a) => a.name == json['algorithm'],
          orElse: () => SovereignIdentityAlgorithm.ed25519,
        ),
        createdAt: json['createdAt'] as int,
      );
}

class SovereignSignature {
  final String data;
  final String signerPublicKey;
  final String algorithm;
  final int timestamp;
  final String verificationTag;

  const SovereignSignature({
    required this.data,
    required this.signerPublicKey,
    required this.algorithm,
    required this.timestamp,
    required this.verificationTag,
  });

  Map<String, dynamic> toJson() => {
    'data': data,
    'signer': signerPublicKey,
    'algorithm': algorithm,
    'timestamp': timestamp,
    'verificationTag': verificationTag,
  };

  static SovereignSignature fromJson(Map<String, dynamic> json) =>
      SovereignSignature(
        data: json['data'] as String,
        signerPublicKey: json['signer'] as String,
        algorithm: json['algorithm'] as String,
        timestamp: json['timestamp'] as int,
        verificationTag: json['verificationTag'] as String,
      );
}

class KeyRotationRecord {
  final String oldPublicKey;
  final String newPublicKey;
  final int rotatedAt;
  final String rotationSignature;

  const KeyRotationRecord({
    required this.oldPublicKey,
    required this.newPublicKey,
    required this.rotatedAt,
    required this.rotationSignature,
  });

  Map<String, dynamic> toJson() => {
    'oldPublicKey': oldPublicKey,
    'newPublicKey': newPublicKey,
    'rotatedAt': rotatedAt,
    'rotationSignature': rotationSignature,
  };

  static KeyRotationRecord fromJson(Map<String, dynamic> json) =>
      KeyRotationRecord(
        oldPublicKey: json['oldPublicKey'] as String,
        newPublicKey: json['newPublicKey'] as String,
        rotatedAt: json['rotatedAt'] as int,
        rotationSignature: json['rotationSignature'] as String,
      );
}

class SovereignIdentity {
  final String did;
  final String nodeId;
  final SovereignKeyPair keyPair;
  final int civilizationEpoch;
  final String? federationId;
  final TrustLevel trustLevel;
  final List<String> constitutionalAncestry;
  final int createdAt;
  final SovereignSignature selfSignature;
  final List<VerifiableCredential> credentials;
  final List<KeyRotationRecord> keyRotationHistory;

  const SovereignIdentity({
    required this.did,
    required this.nodeId,
    required this.keyPair,
    required this.civilizationEpoch,
    this.federationId,
    required this.trustLevel,
    required this.constitutionalAncestry,
    required this.createdAt,
    required this.selfSignature,
    this.credentials = const [],
    this.keyRotationHistory = const [],
  });

  String get publicKey => keyPair.publicKey;
  String get verificationKey => keyPair.verificationKey;

  Map<String, dynamic> toJson() => {
    'did': did,
    'nodeId': nodeId,
    'keyPair': keyPair.toJson(),
    'epoch': civilizationEpoch,
    'federation': federationId,
    'trust': trustLevel.name,
    'ancestry': constitutionalAncestry,
    'created': createdAt,
    'selfSig': selfSignature.toJson(),
    'credentials': credentials.map((c) => c.toJson()).toList(),
    'keyRotations': keyRotationHistory.map((r) => r.toJson()).toList(),
  };

  SovereignIdentity bumpEpoch() => SovereignIdentity(
    did: did,
    nodeId: nodeId,
    keyPair: keyPair,
    civilizationEpoch: civilizationEpoch + 1,
    federationId: federationId,
    trustLevel: trustLevel,
    constitutionalAncestry: constitutionalAncestry,
    createdAt: createdAt,
    selfSignature: selfSignature,
    credentials: credentials,
    keyRotationHistory: keyRotationHistory,
  );

  SovereignIdentity joinFederation(String fedId) => SovereignIdentity(
    did: did,
    nodeId: nodeId,
    keyPair: keyPair,
    civilizationEpoch: civilizationEpoch,
    federationId: fedId,
    trustLevel: trustLevel,
    constitutionalAncestry: constitutionalAncestry,
    createdAt: createdAt,
    selfSignature: selfSignature,
    credentials: credentials,
    keyRotationHistory: keyRotationHistory,
  );

  SovereignIdentity updateTrust(TrustLevel newLevel) => SovereignIdentity(
    did: did,
    nodeId: nodeId,
    keyPair: keyPair,
    civilizationEpoch: civilizationEpoch,
    federationId: federationId,
    trustLevel: newLevel,
    constitutionalAncestry: constitutionalAncestry,
    createdAt: createdAt,
    selfSignature: selfSignature,
    credentials: credentials,
    keyRotationHistory: keyRotationHistory,
  );

  SovereignIdentity addCredential(VerifiableCredential credential) =>
      SovereignIdentity(
        did: did,
        nodeId: nodeId,
        keyPair: keyPair,
        civilizationEpoch: civilizationEpoch,
        federationId: federationId,
        trustLevel: trustLevel,
        constitutionalAncestry: constitutionalAncestry,
        createdAt: createdAt,
        selfSignature: selfSignature,
        credentials: [...credentials, credential],
        keyRotationHistory: keyRotationHistory,
      );

  SovereignIdentity rotateKey() {
    final newKeyPair = _generateKeyPair();
    final rotatedAt = DateTime.now().millisecondsSinceEpoch;
    final rotationData = '${keyPair.publicKey}|${newKeyPair.publicKey}|$rotatedAt';
    final oldPrivateKey = _decodePrivateKey(keyPair.privateKey);
    final rotationSignature = ed.sign(oldPrivateKey, utf8.encode(rotationData));
    final newSelfSignature = _signSelf(did, newKeyPair, createdAt);
    final rotationRecord = KeyRotationRecord(
      oldPublicKey: keyPair.publicKey,
      newPublicKey: newKeyPair.publicKey,
      rotatedAt: rotatedAt,
      rotationSignature: base64Encode(rotationSignature),
    );
    return SovereignIdentity(
      did: did,
      nodeId: nodeId,
      keyPair: newKeyPair,
      civilizationEpoch: civilizationEpoch,
      federationId: federationId,
      trustLevel: trustLevel,
      constitutionalAncestry: constitutionalAncestry,
      createdAt: createdAt,
      selfSignature: newSelfSignature,
      credentials: credentials,
      keyRotationHistory: [...keyRotationHistory, rotationRecord],
    );
  }

  bool verifyKeyRotation(KeyRotationRecord record) {
    final rotationData = '${record.oldPublicKey}|${record.newPublicKey}|${record.rotatedAt}';
    final oldPublicKey = _decodePublicKey(record.oldPublicKey);
    final signature = base64Decode(record.rotationSignature);
    return ed.verify(oldPublicKey, utf8.encode(rotationData), signature);
  }

  static SovereignIdentity generate({String? nodeId, String? federationId}) {
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final effectiveNodeId = nodeId ?? _generateNodeId();
    final keyPair = _generateKeyPair();
    final did = _computeDid(effectiveNodeId, keyPair.publicKey);
    final selfSignature = _signSelf(did, keyPair, createdAt);
    return SovereignIdentity(
      did: did,
      nodeId: effectiveNodeId,
      keyPair: keyPair,
      civilizationEpoch: 0,
      federationId: federationId,
      trustLevel: TrustLevel.verified,
      constitutionalAncestry: ['genesis'],
      createdAt: createdAt,
      selfSignature: selfSignature,
    );
  }

  static bool verify(SovereignIdentity identity) {
    if (identity.keyRotationHistory.isNotEmpty) {
      final originalPublicKey = identity.keyRotationHistory.first.oldPublicKey;
      final expectedDid = _computeDid(identity.nodeId, originalPublicKey);
      if (identity.did != expectedDid) return false;
      final sigData = _computeSignatureData(
        identity.did,
        identity.keyPair.publicKey,
        identity.createdAt,
      );
      final publicKey = _decodePublicKey(identity.keyPair.publicKey);
      final signature = base64Decode(identity.selfSignature.data);
      return ed.verify(publicKey, utf8.encode(sigData), signature);
    }
    final expectedDid = _computeDid(
      identity.nodeId,
      identity.keyPair.publicKey,
    );
    if (identity.did != expectedDid) return false;
    final sigData = _computeSignatureData(
      identity.did,
      identity.keyPair.publicKey,
      identity.createdAt,
    );
    final publicKey = _decodePublicKey(identity.keyPair.publicKey);
    final signature = base64Decode(identity.selfSignature.data);
    return ed.verify(publicKey, utf8.encode(sigData), signature);
  }

  static bool verifySignature(
    String data,
    SovereignSignature signature,
    String publicKeyBase64,
  ) {
    final publicKey = _decodePublicKey(publicKeyBase64);
    final sig = base64Decode(signature.data);
    return ed.verify(publicKey, utf8.encode(data), sig);
  }

  static SovereignIdentity deriveSubIdentity(
    SovereignIdentity parent,
    String subId, {
    String? federationId,
  }) {
    final privateKey = _decodePrivateKey(parent.keyPair.privateKey);
    final derivationInput = '${parent.did}|$subId|${parent.civilizationEpoch}';
    final signature = ed.sign(privateKey, utf8.encode(derivationInput));
    final subNodeId = '${parent.nodeId}.$subId';
    final keyPair = _generateKeyPair();
    final did = _computeDid(subNodeId, keyPair.publicKey);
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final selfSignature = _signSelf(did, keyPair, createdAt);
    final credential = VerifiableCredential.issue(
      issuerDid: parent.did,
      subjectDid: did,
      credentialType: 'DerivedIdentity',
      claims: {
        'subId': subId,
        'parentDid': parent.did,
        'derivationProof': base64Encode(signature),
      },
      ttl: 0,
      issuerPrivateKey: parent.keyPair.privateKey,
      issuerPublicKey: parent.keyPair.publicKey,
    );
    return SovereignIdentity(
      did: did,
      nodeId: subNodeId,
      keyPair: keyPair,
      civilizationEpoch: 0,
      federationId: federationId ?? parent.federationId,
      trustLevel: TrustLevel.verified,
      constitutionalAncestry: [...parent.constitutionalAncestry, parent.did],
      createdAt: createdAt,
      selfSignature: selfSignature,
      credentials: [credential],
    );
  }

  static String _generateNodeId() {
    final random = DateTime.now().microsecondsSinceEpoch.toString() +
        DateTime.now().millisecond.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  static SovereignKeyPair _generateKeyPair() {
    final keyPair = ed.generateKey();
    final publicKeyBase64 = base64Encode(keyPair.publicKey.bytes);
    final privateKeyBase64 = base64Encode(keyPair.privateKey.bytes);
    final vkSeed = utf8.encode('vk_$publicKeyBase64');
    final verificationKey = sha256.convert(vkSeed).toString().substring(0, 64);
    return SovereignKeyPair(
      publicKey: publicKeyBase64,
      privateKey: privateKeyBase64,
      verificationKey: verificationKey,
      algorithm: SovereignIdentityAlgorithm.ed25519,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static String _computeDid(String nodeId, String publicKey) {
    final input = utf8.encode('did:omnivium:$nodeId:$publicKey');
    final hash = sha256.convert(input).toString().substring(0, 32);
    return 'did:omnivium:$hash';
  }

  static String _computeSignatureData(
    String did,
    String publicKey,
    int createdAt,
  ) {
    return '$did|$publicKey|$createdAt';
  }

  static SovereignSignature _signSelf(
    String did,
    SovereignKeyPair keyPair,
    int createdAt,
  ) {
    final data = _computeSignatureData(did, keyPair.publicKey, createdAt);
    final privateKey = _decodePrivateKey(keyPair.privateKey);
    final signature = ed.sign(privateKey, utf8.encode(data));
    final verificationTag = sha256
        .convert(utf8.encode('${keyPair.publicKey}|${base64Encode(signature)}'))
        .toString();
    return SovereignSignature(
      data: base64Encode(signature),
      signerPublicKey: keyPair.publicKey,
      algorithm: keyPair.algorithm.name,
      timestamp: createdAt,
      verificationTag: verificationTag,
    );
  }

  static ed.PrivateKey _decodePrivateKey(String privateKeyBase64) {
    final bytes = base64Decode(privateKeyBase64);
    return ed.PrivateKey(bytes);
  }

  static ed.PublicKey _decodePublicKey(String publicKeyBase64) {
    final bytes = base64Decode(publicKeyBase64);
    return ed.PublicKey(bytes);
  }
}

class VerifiableCredential {
  final String credentialId;
  final String issuerDid;
  final String subjectDid;
  final String credentialType;
  final Map<String, dynamic> claims;
  final int issuedAt;
  final int expiresAt;
  final String proof;
  final String verificationTag;

  const VerifiableCredential({
    required this.credentialId,
    required this.issuerDid,
    required this.subjectDid,
    required this.credentialType,
    required this.claims,
    required this.issuedAt,
    required this.expiresAt,
    required this.proof,
    required this.verificationTag,
  });

  bool get isValid => expiresAt == 0 || DateTime.now().millisecondsSinceEpoch < expiresAt;

  Map<String, dynamic> toJson() => {
    'id': credentialId,
    'issuer': issuerDid,
    'subject': subjectDid,
    'type': credentialType,
    'claims': claims,
    'issuedAt': issuedAt,
    'expiresAt': expiresAt,
    'proof': proof,
    'verificationTag': verificationTag,
  };

  static VerifiableCredential issue({
    required String issuerDid,
    required String subjectDid,
    required String credentialType,
    required Map<String, dynamic> claims,
    required int ttl,
    required String issuerPrivateKey,
    required String issuerPublicKey,
  }) {
    final issuedAt = DateTime.now().millisecondsSinceEpoch;
    final credentialId =
        'vc:${sha256.convert(utf8.encode('$issuerDid|$subjectDid|$issuedAt')).toString().substring(0, 16)}';
    final proofInput =
        '$credentialId|$issuerDid|$subjectDid|$issuedAt|${claims.toString()}';
    final privateKey = ed.PrivateKey(base64Decode(issuerPrivateKey));
    final signature = ed.sign(privateKey, utf8.encode(proofInput));
    final proof = base64Encode(signature);
    final verificationTag = sha256
        .convert(utf8.encode('$issuerPublicKey|$proof'))
        .toString();
    return VerifiableCredential(
      credentialId: credentialId,
      issuerDid: issuerDid,
      subjectDid: subjectDid,
      credentialType: credentialType,
      claims: claims,
      issuedAt: issuedAt,
      expiresAt: ttl == 0 ? 0 : issuedAt + ttl,
      proof: proof,
      verificationTag: verificationTag,
    );
  }

  static bool verifyCredential(
    VerifiableCredential credential,
    String issuerPublicKeyBase64,
  ) {
    if (!credential.isValid) return false;
    final proofInput =
        '${credential.credentialId}|${credential.issuerDid}|${credential.subjectDid}|${credential.issuedAt}|${credential.claims.toString()}';
    final publicKey = ed.PublicKey(base64Decode(issuerPublicKeyBase64));
    final signature = base64Decode(credential.proof);
    return ed.verify(publicKey, utf8.encode(proofInput), signature);
  }
}

class ConstitutionalPassport {
  final String passportId;
  final SovereignIdentity holder;
  final VerifiableCredential identityCredential;
  final VerifiableCredential reputationCredential;
  final VerifiableCredential federationCredential;
  final int issuedAt;
  final int expiresAt;
  final String proof;
  final String verificationTag;

  const ConstitutionalPassport({
    required this.passportId,
    required this.holder,
    required this.identityCredential,
    required this.reputationCredential,
    required this.federationCredential,
    required this.issuedAt,
    required this.expiresAt,
    required this.proof,
    required this.verificationTag,
  });

  bool get isValid => DateTime.now().millisecondsSinceEpoch < expiresAt;

  Map<String, dynamic> toJson() => {
    'passportId': passportId,
    'holder': holder.toJson(),
    'identityCredential': identityCredential.toJson(),
    'reputationCredential': reputationCredential.toJson(),
    'federationCredential': federationCredential.toJson(),
    'issuedAt': issuedAt,
    'expiresAt': expiresAt,
    'proof': proof,
    'verificationTag': verificationTag,
  };

  static ConstitutionalPassport issue({
    required SovereignIdentity holder,
    required double reputationScore,
    required String federationId,
    required String issuerPrivateKey,
    required String issuerPublicKey,
    int ttl = 3600000,
  }) {
    final issuedAt = DateTime.now().millisecondsSinceEpoch;
    final passportId =
        'passport:${sha256.convert(utf8.encode('${holder.did}|$issuedAt')).toString().substring(0, 16)}';

    final identityCredential = VerifiableCredential.issue(
      issuerDid: 'did:omnivium:authority',
      subjectDid: holder.did,
      credentialType: 'ConstitutionalIdentity',
      claims: {'nodeId': holder.nodeId, 'epoch': holder.civilizationEpoch},
      ttl: ttl,
      issuerPrivateKey: issuerPrivateKey,
      issuerPublicKey: issuerPublicKey,
    );

    final reputationCredential = VerifiableCredential.issue(
      issuerDid: 'did:omnivium:authority',
      subjectDid: holder.did,
      credentialType: 'ReputationScore',
      claims: {'score': reputationScore, 'trustLevel': holder.trustLevel.name},
      ttl: ttl,
      issuerPrivateKey: issuerPrivateKey,
      issuerPublicKey: issuerPublicKey,
    );

    final federationCredential = VerifiableCredential.issue(
      issuerDid: 'did:omnivium:authority',
      subjectDid: holder.did,
      credentialType: 'FederationMembership',
      claims: {'federationId': federationId, 'memberSince': issuedAt},
      ttl: ttl,
      issuerPrivateKey: issuerPrivateKey,
      issuerPublicKey: issuerPublicKey,
    );

    final proofInput =
        '$passportId|${holder.did}|$issuedAt|$reputationScore|$federationId';
    final privateKey = ed.PrivateKey(base64Decode(issuerPrivateKey));
    final signature = ed.sign(privateKey, utf8.encode(proofInput));
    final proof = base64Encode(signature);
    final verificationTag = sha256
        .convert(utf8.encode('$issuerPublicKey|$proof'))
        .toString();

    return ConstitutionalPassport(
      passportId: passportId,
      holder: holder,
      identityCredential: identityCredential,
      reputationCredential: reputationCredential,
      federationCredential: federationCredential,
      issuedAt: issuedAt,
      expiresAt: issuedAt + ttl,
      proof: proof,
      verificationTag: verificationTag,
    );
  }

  static bool verifyPassport(
    ConstitutionalPassport passport,
    String issuerPublicKeyBase64,
  ) {
    if (!passport.isValid) return false;
    if (!SovereignIdentity.verify(passport.holder)) return false;

    final proofInput =
        '${passport.passportId}|${passport.holder.did}|${passport.issuedAt}|${passport.reputationCredential.claims['score']}|${passport.federationCredential.claims['federationId']}';
    final publicKey = ed.PublicKey(base64Decode(issuerPublicKeyBase64));
    final signature = base64Decode(passport.proof);
    return ed.verify(publicKey, utf8.encode(proofInput), signature);
  }
}
