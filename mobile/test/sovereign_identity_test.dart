import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/sovereign_identity.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  group('SovereignKeyPair — Ed25519 Key Generation', () {
    test('generate produces key pair with correct format', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(id.publicKey, isNotEmpty);
      expect(id.keyPair.privateKey, isNotEmpty);
      expect(id.keyPair.algorithm, SovereignIdentityAlgorithm.ed25519);
    });

    test('different nodeIds produce different keys', () {
      final idA = SovereignIdentity.generate(nodeId: 'node-A');
      final idB = SovereignIdentity.generate(nodeId: 'node-B');
      expect(idA.publicKey, isNot(equals(idB.publicKey)));
      expect(idA.did, isNot(equals(idB.did)));
    });

    test('verificationKey is derived from publicKey', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(id.verificationKey, isNotEmpty);
    });

    test('keyPair toJson includes all fields', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final json = id.keyPair.toJson();
      expect(json['algorithm'], 'ed25519');
      expect(json.containsKey('publicKey'), isTrue);
      expect(json.containsKey('privateKey'), isTrue);
      expect(json.containsKey('verificationKey'), isTrue);
    });

    test('keyPair fromJson round-trips correctly', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final json = id.keyPair.toJson();
      final restored = SovereignKeyPair.fromJson(json);
      expect(restored.publicKey, id.keyPair.publicKey);
      expect(restored.privateKey, id.keyPair.privateKey);
      expect(restored.algorithm, id.keyPair.algorithm);
    });
  });

  group('SovereignIdentity — DID Generation', () {
    test('DID follows did:omnivium format', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(id.did, startsWith('did:omnivium:'));
    });

    test('DID differs for different nodeIds', () {
      final idA = SovereignIdentity.generate(nodeId: 'node-A');
      final idB = SovereignIdentity.generate(nodeId: 'node-B');
      expect(idA.did, isNot(equals(idB.did)));
    });

    test('DID is 32 hex chars after prefix', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final hash = id.did.replaceFirst('did:omnivium:', '');
      expect(hash.length, 32);
    });
  });

  group('SovereignIdentity — Ed25519 Self-Signature Verification', () {
    test('verify returns true for valid identity', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(SovereignIdentity.verify(id), isTrue);
    });

    test('verify returns false for tampered publicKey', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final tamperedKeyPair = SovereignKeyPair(
        publicKey: base64Encode(List.filled(32, 0)),
        privateKey: id.keyPair.privateKey,
        verificationKey: id.keyPair.verificationKey,
        algorithm: id.keyPair.algorithm,
        createdAt: id.keyPair.createdAt,
      );
      final tampered = SovereignIdentity(
        did: id.did,
        nodeId: id.nodeId,
        keyPair: tamperedKeyPair,
        civilizationEpoch: id.civilizationEpoch,
        trustLevel: id.trustLevel,
        constitutionalAncestry: id.constitutionalAncestry,
        createdAt: id.createdAt,
        selfSignature: id.selfSignature,
      );
      expect(SovereignIdentity.verify(tampered), isFalse);
    });

    test('verify returns false for tampered DID', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final tampered = SovereignIdentity(
        did: 'did:omnivium:00000000000000000000000000000000',
        nodeId: id.nodeId,
        keyPair: id.keyPair,
        civilizationEpoch: id.civilizationEpoch,
        trustLevel: id.trustLevel,
        constitutionalAncestry: id.constitutionalAncestry,
        createdAt: id.createdAt,
        selfSignature: id.selfSignature,
      );
      expect(SovereignIdentity.verify(tampered), isFalse);
    });
  });

  group('SovereignIdentity — Identity Mutations', () {
    test('bumpEpoch increments epoch', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final bumped = id.bumpEpoch();
      expect(bumped.civilizationEpoch, id.civilizationEpoch + 1);
      expect(bumped.did, id.did);
      expect(bumped.publicKey, id.publicKey);
    });

    test('joinFederation sets federationId', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(id.federationId, isNull);
      final joined = id.joinFederation('fed-1');
      expect(joined.federationId, 'fed-1');
      expect(joined.did, id.did);
    });

    test('updateTrust changes trust level', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(id.trustLevel, TrustLevel.verified);
      final updated = id.updateTrust(TrustLevel.system);
      expect(updated.trustLevel, TrustLevel.system);
    });

    test('addCredential adds verifiable credential', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(id.credentials, isEmpty);
      final vc = VerifiableCredential.issue(
        issuerDid: 'did:omnivium:authority',
        subjectDid: id.did,
        credentialType: 'TestCredential',
        claims: {'test': true},
        ttl: 3600000,
        issuerPrivateKey: id.keyPair.privateKey,
        issuerPublicKey: id.keyPair.publicKey,
      );
      final withCred = id.addCredential(vc);
      expect(withCred.credentials.length, 1);
      expect(withCred.credentials.first.credentialType, 'TestCredential');
    });
  });

  group('SovereignIdentity — Key Rotation', () {
    test('rotateKey produces new keyPair but same DID', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final rotated = id.rotateKey();
      expect(rotated.did, id.did);
      expect(rotated.publicKey, isNot(equals(id.publicKey)));
      expect(rotated.keyRotationHistory.length, 1);
      expect(rotated.keyRotationHistory.first.oldPublicKey, id.publicKey);
      expect(rotated.keyRotationHistory.first.newPublicKey, rotated.publicKey);
    });

    test('rotated identity verifies with new key', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final rotated = id.rotateKey();
      expect(SovereignIdentity.verify(rotated), isTrue);
    });

    test('key rotation history is preserved across multiple rotations', () {
      var id = SovereignIdentity.generate(nodeId: 'node-A');
      final firstPubKey = id.publicKey;
      id = id.rotateKey();
      expect(id.keyRotationHistory.length, 1);
      final secondPubKey = id.publicKey;
      id = id.rotateKey();
      expect(id.keyRotationHistory.length, 2);
      expect(id.keyRotationHistory.first.oldPublicKey, firstPubKey);
      expect(id.keyRotationHistory.first.newPublicKey, secondPubKey);
      expect(id.keyRotationHistory.last.oldPublicKey, secondPubKey);
    });

    test('verifyKeyRotation validates rotation signature', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final rotated = id.rotateKey();
      final record = rotated.keyRotationHistory.first;
      expect(rotated.verifyKeyRotation(record), isTrue);
    });
  });

  group('SovereignIdentity — Sub-Identity Derivation', () {
    test('deriveSubIdentity creates child identity from parent', () {
      final parent = SovereignIdentity.generate(nodeId: 'parent');
      final child = SovereignIdentity.deriveSubIdentity(parent, 'shadow1');
      expect(child.did, startsWith('did:omnivium:'));
      expect(child.did, isNot(equals(parent.did)));
      expect(child.nodeId, contains('shadow1'));
      expect(child.constitutionalAncestry, contains(parent.did));
    });

    test('derived identity has credential from parent', () {
      final parent = SovereignIdentity.generate(nodeId: 'parent');
      final child = SovereignIdentity.deriveSubIdentity(parent, 'agent1');
      expect(child.credentials, isNotEmpty);
      expect(child.credentials.first.credentialType, 'DerivedIdentity');
      expect(child.credentials.first.issuerDid, parent.did);
      expect(child.credentials.first.subjectDid, child.did);
    });

    test('derived identity is independently verifiable', () {
      final parent = SovereignIdentity.generate(nodeId: 'parent');
      final child = SovereignIdentity.deriveSubIdentity(parent, 'shadow1');
      expect(SovereignIdentity.verify(child), isTrue);
    });

    test('different subIds produce different identities', () {
      final parent = SovereignIdentity.generate(nodeId: 'parent');
      final shadow = SovereignIdentity.deriveSubIdentity(parent, 'shadow1');
      final agent = SovereignIdentity.deriveSubIdentity(parent, 'agent1');
      expect(shadow.did, isNot(equals(agent.did)));
      expect(shadow.publicKey, isNot(equals(agent.publicKey)));
    });
  });

  group('SovereignIdentity — toJson / fromJson', () {
    test('toJson includes all fields', () {
      final id = SovereignIdentity.generate(
        nodeId: 'node-A',
        federationId: 'fed-1',
      );
      final json = id.toJson();
      expect(json['did'], id.did);
      expect(json['nodeId'], 'node-A');
      expect(json['epoch'], 0);
      expect(json['federation'], 'fed-1');
      expect(json['trust'], 'verified');
      expect(json['ancestry'], ['genesis']);
      expect(json.containsKey('keyPair'), isTrue);
      expect(json.containsKey('selfSig'), isTrue);
    });
  });

  group('VerifiableCredential — Ed25519 Credential Issuance and Verification', () {
    test('issue creates valid credential', () {
      final issuer = SovereignIdentity.generate(nodeId: 'authority');
      final vc = VerifiableCredential.issue(
        issuerDid: issuer.did,
        subjectDid: 'did:omnivium:1234',
        credentialType: 'ConstitutionalIdentity',
        claims: {'nodeId': 'node-A'},
        ttl: 3600000,
        issuerPrivateKey: issuer.keyPair.privateKey,
        issuerPublicKey: issuer.keyPair.publicKey,
      );
      expect(vc.credentialId, startsWith('vc:'));
      expect(vc.issuerDid, issuer.did);
      expect(vc.subjectDid, 'did:omnivium:1234');
      expect(vc.credentialType, 'ConstitutionalIdentity');
      expect(vc.isValid, isTrue);
    });

    test('verifyCredential returns true with correct issuer public key', () {
      final issuer = SovereignIdentity.generate(nodeId: 'authority');
      final vc = VerifiableCredential.issue(
        issuerDid: issuer.did,
        subjectDid: 'did:omnivium:1234',
        credentialType: 'Test',
        claims: {'test': true},
        ttl: 3600000,
        issuerPrivateKey: issuer.keyPair.privateKey,
        issuerPublicKey: issuer.keyPair.publicKey,
      );
      expect(
        VerifiableCredential.verifyCredential(vc, issuer.keyPair.publicKey),
        isTrue,
      );
    });

    test('verifyCredential returns false for wrong public key', () {
      final issuer = SovereignIdentity.generate(nodeId: 'authority');
      final other = SovereignIdentity.generate(nodeId: 'other');
      final vc = VerifiableCredential.issue(
        issuerDid: issuer.did,
        subjectDid: 'did:omnivium:1234',
        credentialType: 'Test',
        claims: {'test': true},
        ttl: 3600000,
        issuerPrivateKey: issuer.keyPair.privateKey,
        issuerPublicKey: issuer.keyPair.publicKey,
      );
      expect(
        VerifiableCredential.verifyCredential(vc, other.keyPair.publicKey),
        isFalse,
      );
    });

    test('verifyCredential returns false for tampered claims', () {
      final issuer = SovereignIdentity.generate(nodeId: 'authority');
      final vc = VerifiableCredential.issue(
        issuerDid: issuer.did,
        subjectDid: 'did:omnivium:1234',
        credentialType: 'Test',
        claims: {'test': true},
        ttl: 3600000,
        issuerPrivateKey: issuer.keyPair.privateKey,
        issuerPublicKey: issuer.keyPair.publicKey,
      );
      final tampered = VerifiableCredential(
        credentialId: vc.credentialId,
        issuerDid: vc.issuerDid,
        subjectDid: vc.subjectDid,
        credentialType: vc.credentialType,
        claims: {'test': false},
        issuedAt: vc.issuedAt,
        expiresAt: vc.expiresAt,
        proof: vc.proof,
        verificationTag: vc.verificationTag,
      );
      expect(
        VerifiableCredential.verifyCredential(
          tampered,
          issuer.keyPair.publicKey,
        ),
        isFalse,
      );
    });
  });

  group('ConstitutionalPassport — Machine Sovereign Identity', () {
    test('issue creates valid passport', () {
      final holder = SovereignIdentity.generate(
        nodeId: 'node-A',
        federationId: 'fed-1',
      );
      final authority = SovereignIdentity.generate(nodeId: 'authority');
      final passport = ConstitutionalPassport.issue(
        holder: holder,
        reputationScore: 85.0,
        federationId: 'fed-1',
        issuerPrivateKey: authority.keyPair.privateKey,
        issuerPublicKey: authority.keyPair.publicKey,
      );
      expect(passport.passportId, startsWith('passport:'));
      expect(passport.holder.did, holder.did);
      expect(passport.isValid, isTrue);
      expect(passport.identityCredential.credentialType, 'ConstitutionalIdentity');
      expect(passport.reputationCredential.credentialType, 'ReputationScore');
      expect(passport.federationCredential.credentialType, 'FederationMembership');
    });

    test('verifyPassport returns true with correct authority public key', () {
      final holder = SovereignIdentity.generate(nodeId: 'node-A');
      final authority = SovereignIdentity.generate(nodeId: 'authority');
      final passport = ConstitutionalPassport.issue(
        holder: holder,
        reputationScore: 90.0,
        federationId: 'fed-1',
        issuerPrivateKey: authority.keyPair.privateKey,
        issuerPublicKey: authority.keyPair.publicKey,
      );
      expect(
        ConstitutionalPassport.verifyPassport(passport, authority.keyPair.publicKey),
        isTrue,
      );
    });

    test('verifyPassport returns false for wrong authority public key', () {
      final holder = SovereignIdentity.generate(nodeId: 'node-A');
      final authority = SovereignIdentity.generate(nodeId: 'authority');
      final other = SovereignIdentity.generate(nodeId: 'other');
      final passport = ConstitutionalPassport.issue(
        holder: holder,
        reputationScore: 90.0,
        federationId: 'fed-1',
        issuerPrivateKey: authority.keyPair.privateKey,
        issuerPublicKey: authority.keyPair.publicKey,
      );
      expect(
        ConstitutionalPassport.verifyPassport(passport, other.keyPair.publicKey),
        isFalse,
      );
    });
  });

  group('SovereignSignature — Ed25519 Signature Verification', () {
    test('self-signature is valid for identity', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(SovereignIdentity.verify(id), isTrue);
    });

    test('tampered createdAt fails verification', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final tampered = SovereignIdentity(
        did: id.did,
        nodeId: id.nodeId,
        keyPair: id.keyPair,
        civilizationEpoch: id.civilizationEpoch,
        trustLevel: id.trustLevel,
        constitutionalAncestry: id.constitutionalAncestry,
        createdAt: id.createdAt + 1,
        selfSignature: id.selfSignature,
      );
      expect(SovereignIdentity.verify(tampered), isFalse);
    });

    test('verifySignature works with public key', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final sig = id.selfSignature;
      final sigData = '${id.did}|${id.publicKey}|${id.createdAt}';
      expect(
        SovereignIdentity.verifySignature(sigData, sig, id.publicKey),
        isTrue,
      );
    });

    test('verifySignature fails with wrong public key', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      final other = SovereignIdentity.generate(nodeId: 'node-B');
      final sig = id.selfSignature;
      final sigData = '${id.did}|${id.publicKey}|${id.createdAt}';
      expect(
        SovereignIdentity.verifySignature(sigData, sig, other.publicKey),
        isFalse,
      );
    });
  });

  group('SovereignIdentity — Cross-Node Identity', () {
    test('two nodes have distinct DIDs and keys', () {
      final nodeA = SovereignIdentity.generate(nodeId: 'node-A');
      final nodeB = SovereignIdentity.generate(nodeId: 'node-B');
      expect(nodeA.did, isNot(equals(nodeB.did)));
      expect(nodeA.publicKey, isNot(equals(nodeB.publicKey)));
    });

    test('node with federation has federationId', () {
      final id = SovereignIdentity.generate(
        nodeId: 'node-A',
        federationId: 'fed-1',
      );
      expect(id.federationId, 'fed-1');
    });

    test('constitutional ancestry starts with genesis', () {
      final id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(id.constitutionalAncestry, ['genesis']);
    });

    test('epoch progression tracks civilization evolution', () {
      var id = SovereignIdentity.generate(nodeId: 'node-A');
      expect(id.civilizationEpoch, 0);
      id = id.bumpEpoch();
      expect(id.civilizationEpoch, 1);
      id = id.bumpEpoch();
      expect(id.civilizationEpoch, 2);
    });

    test('generate without nodeId creates random nodeId', () {
      final id = SovereignIdentity.generate();
      expect(id.nodeId, isNotEmpty);
      expect(id.did, startsWith('did:omnivium:'));
    });
  });
}
