import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../stability/security.dart';

enum SovereignIdentityAlgorithm {
  hmacSha256,
}

class SovereignKeyPair {
  final String publicKey;
  final String signingKey;
  final String verificationKey;
  final SovereignIdentityAlgorithm algorithm;
  final int createdAt;

  const SovereignKeyPair({
    required this.publicKey,
    required this.signingKey,
    required this.verificationKey,
    required this.algorithm,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'signingKey': signingKey,
        'verificationKey': verificationKey,
        'algorithm': algorithm.name,
        'createdAt': createdAt,
      };
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
      );

  SovereignIdentity addCredential(VerifiableCredential credential) => SovereignIdentity(
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
      );

  static SovereignIdentity generate(String nodeId, {String? federationId}) {
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final keyPair = _generateKeyPair(nodeId, createdAt);
    final did = _computeDid(nodeId, keyPair.publicKey);
    final selfSignature = _signSelf(did, keyPair, createdAt);
    return SovereignIdentity(
      did: did,
      nodeId: nodeId,
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
    final expectedDid = _computeDid(identity.nodeId, identity.keyPair.publicKey);
    if (identity.did != expectedDid) return false;

    final sigData = _computeSignatureData(
      identity.did,
      identity.keyPair.publicKey,
      identity.createdAt,
    );
    return _verify(sigData, identity.selfSignature.data, identity.keyPair.verificationKey, identity.selfSignature.verificationTag);
  }

  static bool verifySignature(String data, SovereignSignature signature, String verificationKey) {
    return _verify(data, signature.data, verificationKey, signature.verificationTag);
  }

  static SovereignKeyPair _generateKeyPair(String nodeId, int createdAt) {
    final seed = utf8.encode('sovereign_seed_$nodeId|$createdAt');
    final signingKey = sha256.convert(seed).toString();
    final pubSeed = utf8.encode('sovereign_pub_${signingKey}_$nodeId');
    final publicKey = sha256.convert(pubSeed).toString().substring(0, 64);
    final vkSeed = utf8.encode('sovereign_vk_${signingKey}_$nodeId');
    final verificationKey = sha256.convert(vkSeed).toString().substring(0, 64);
    return SovereignKeyPair(
      publicKey: publicKey,
      signingKey: signingKey,
      verificationKey: verificationKey,
      algorithm: SovereignIdentityAlgorithm.hmacSha256,
      createdAt: createdAt,
    );
  }

  static String _computeDid(String nodeId, String publicKey) {
    final input = utf8.encode('did:omnivium:$nodeId:$publicKey');
    final hash = sha256.convert(input).toString().substring(0, 32);
    return 'did:omnivium:$hash';
  }

  static String _computeSignatureData(String did, String publicKey, int createdAt) {
    return '$did|$publicKey|$createdAt';
  }

  static SovereignSignature _signSelf(String did, SovereignKeyPair keyPair, int createdAt) {
    final data = _computeSignatureData(did, keyPair.publicKey, createdAt);
    final signature = _sign(data, keyPair.signingKey);
    final verificationTag = _computeVerificationTag(data, signature, keyPair.verificationKey);
    return SovereignSignature(
      data: signature,
      signerPublicKey: keyPair.publicKey,
      algorithm: keyPair.algorithm.name,
      timestamp: createdAt,
      verificationTag: verificationTag,
    );
  }

  static String _sign(String data, String signingKey) {
    final key = utf8.encode(signingKey);
    final message = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(message);
    return digest.toString();
  }

  static bool _verify(String data, String signature, String verificationKey, String verificationTag) {
    final expectedTag = _computeVerificationTag(data, signature, verificationKey);
    return verificationTag == expectedTag;
  }

  static String _computeVerificationTag(String data, String signature, String verificationKey) {
    final key = utf8.encode(verificationKey);
    final message = utf8.encode('$data|$signature');
    final hmac = Hmac(sha256, key);
    return hmac.convert(message).toString();
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

  bool get isValid => DateTime.now().millisecondsSinceEpoch < expiresAt;

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
    required String issuerSigningKey,
    required String issuerPublicKey,
    required String issuerVerificationKey,
  }) {
    final issuedAt = DateTime.now().millisecondsSinceEpoch;
    final credentialId = 'vc:${sha256.convert(utf8.encode('$issuerDid|$subjectDid|$issuedAt')).toString().substring(0, 16)}';
    final proofInput = '$credentialId|$issuerDid|$subjectDid|$issuedAt|${claims.toString()}';
    final proof = _hmacSign(issuerSigningKey, proofInput);
    final verificationTag = _hmacSign(issuerPublicKey, '$proofInput|$proof');
    return VerifiableCredential(
      credentialId: credentialId,
      issuerDid: issuerDid,
      subjectDid: subjectDid,
      credentialType: credentialType,
      claims: claims,
      issuedAt: issuedAt,
      expiresAt: issuedAt + ttl,
      proof: proof,
      verificationTag: verificationTag,
    );
  }

  static bool verifyCredential(VerifiableCredential credential, String issuerPublicKey) {
    if (!credential.isValid) return false;
    final proofInput = '${credential.credentialId}|${credential.issuerDid}|${credential.subjectDid}|${credential.issuedAt}|${credential.claims.toString()}';
    final expectedTag = _hmacSign(issuerPublicKey, '$proofInput|${credential.proof}');
    return credential.verificationTag == expectedTag;
  }

  static bool verifyCredentialWithSigningKey(VerifiableCredential credential, String issuerSigningKey) {
    if (!credential.isValid) return false;
    final proofInput = '${credential.credentialId}|${credential.issuerDid}|${credential.subjectDid}|${credential.issuedAt}|${credential.claims.toString()}';
    final expectedProof = _hmacSign(issuerSigningKey, proofInput);
    return credential.proof == expectedProof;
  }

  static String _hmacSign(String key, String data) {
    final hmacKey = utf8.encode(key);
    final message = utf8.encode(data);
    final hmac = Hmac(sha256, hmacKey);
    return hmac.convert(message).toString();
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
    required String issuerSigningKey,
    required String issuerPublicKey,
    required String issuerVerificationKey,
    int ttl = 3600000,
  }) {
    final issuedAt = DateTime.now().millisecondsSinceEpoch;
    final passportId = 'passport:${sha256.convert(utf8.encode('${holder.did}|$issuedAt')).toString().substring(0, 16)}';

    final identityCredential = VerifiableCredential.issue(
      issuerDid: 'did:omnivium:authority',
      subjectDid: holder.did,
      credentialType: 'ConstitutionalIdentity',
      claims: {'nodeId': holder.nodeId, 'epoch': holder.civilizationEpoch},
      ttl: ttl,
      issuerSigningKey: issuerSigningKey,
      issuerPublicKey: issuerPublicKey,
      issuerVerificationKey: issuerVerificationKey,
    );

    final reputationCredential = VerifiableCredential.issue(
      issuerDid: 'did:omnivium:authority',
      subjectDid: holder.did,
      credentialType: 'ReputationScore',
      claims: {'score': reputationScore, 'trustLevel': holder.trustLevel.name},
      ttl: ttl,
      issuerSigningKey: issuerSigningKey,
      issuerPublicKey: issuerPublicKey,
      issuerVerificationKey: issuerVerificationKey,
    );

    final federationCredential = VerifiableCredential.issue(
      issuerDid: 'did:omnivium:authority',
      subjectDid: holder.did,
      credentialType: 'FederationMembership',
      claims: {'federationId': federationId, 'memberSince': issuedAt},
      ttl: ttl,
      issuerSigningKey: issuerSigningKey,
      issuerPublicKey: issuerPublicKey,
      issuerVerificationKey: issuerVerificationKey,
    );

    final proofInput = '$passportId|${holder.did}|$issuedAt|$reputationScore|$federationId';
    final proof = VerifiableCredential._hmacSign(issuerSigningKey, proofInput);
    final verificationTag = VerifiableCredential._hmacSign(issuerPublicKey, '$proofInput|$proof');

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

  static bool verifyPassport(ConstitutionalPassport passport, String issuerPublicKey) {
    if (!passport.isValid) return false;
    if (!SovereignIdentity.verify(passport.holder)) return false;

    final proofInput = '${passport.passportId}|${passport.holder.did}|${passport.issuedAt}|${passport.reputationCredential.claims['score']}|${passport.federationCredential.claims['federationId']}';
    final expectedTag = VerifiableCredential._hmacSign(issuerPublicKey, '$proofInput|${passport.proof}');
    return passport.verificationTag == expectedTag;
  }

  static bool verifyPassportWithSigningKey(ConstitutionalPassport passport, String issuerSigningKey) {
    if (!passport.isValid) return false;
    if (!SovereignIdentity.verify(passport.holder)) return false;

    final proofInput = '${passport.passportId}|${passport.holder.did}|${passport.issuedAt}|${passport.reputationCredential.claims['score']}|${passport.federationCredential.claims['federationId']}';
    final expectedProof = VerifiableCredential._hmacSign(issuerSigningKey, proofInput);
    return passport.proof == expectedProof;
  }
}
