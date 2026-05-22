import 'package:flutter_test/flutter_test.dart';
import 'package:omnivium/core/runtime/sandbox/sovereign_identity.dart';
import 'package:omnivium/core/runtime/stability/security.dart';

void main() {
  group('SovereignKeyPair �?Cryptographic Key Generation', () {
    test('generate produces key pair with correct format', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.publicKey.length, 64);
      expect(id.publicKey, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('different nodeIds produce different keys', () {
      final idA = SovereignIdentity.generate('node-A');
      final idB = SovereignIdentity.generate('node-B');
      expect(idA.publicKey, isNot(equals(idB.publicKey)));
      expect(idA.did, isNot(equals(idB.did)));
    });

    test('publicKey is 64 hex characters', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.publicKey.length, 64);
      expect(id.publicKey, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('signingKey is 64 hex characters', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.keyPair.signingKey.length, 64);
    });

    test('verificationKey is 64 hex characters', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.keyPair.verificationKey.length, 64);
    });

    test('keyPair toJson includes all fields', () {
      final id = SovereignIdentity.generate('node-A');
      final json = id.keyPair.toJson();
      expect(json['algorithm'], 'hmacSha256');
      expect(json.containsKey('publicKey'), isTrue);
      expect(json.containsKey('signingKey'), isTrue);
      expect(json.containsKey('verificationKey'), isTrue);
    });

    test('signingKey and verificationKey are different', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.keyPair.signingKey, isNot(equals(id.keyPair.verificationKey)));
    });
  });

  group('SovereignIdentity �?DID Generation', () {
    test('DID follows did:omnivium format', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.did, startsWith('did:omnivium:'));
    });

    test('DID differs for different nodeIds', () {
      final idA = SovereignIdentity.generate('node-A');
      final idB = SovereignIdentity.generate('node-B');
      expect(idA.did, isNot(equals(idB.did)));
    });

    test('DID is 32 hex chars after prefix', () {
      final id = SovereignIdentity.generate('node-A');
      final hash = id.did.replaceFirst('did:omnivium:', '');
      expect(hash.length, 32);
    });
  });

  group('SovereignIdentity �?Self-Signature Verification', () {
    test('verify returns true for valid identity', () {
      final id = SovereignIdentity.generate('node-A');
      expect(SovereignIdentity.verify(id), isTrue);
    });

    test('verify returns false for tampered publicKey', () {
      final id = SovereignIdentity.generate('node-A');
      final tampered = SovereignIdentity(
        did: id.did,
        nodeId: id.nodeId,
        keyPair: SovereignKeyPair(
          publicKey: 'a' * 64,
          signingKey: id.keyPair.signingKey,
          verificationKey: id.keyPair.verificationKey,
          algorithm: id.keyPair.algorithm,
          createdAt: id.keyPair.createdAt,
        ),
        civilizationEpoch: id.civilizationEpoch,
        trustLevel: id.trustLevel,
        constitutionalAncestry: id.constitutionalAncestry,
        createdAt: id.createdAt,
        selfSignature: id.selfSignature,
      );
      expect(SovereignIdentity.verify(tampered), isFalse);
    });

    test('verify returns false for tampered DID', () {
      final id = SovereignIdentity.generate('node-A');
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

  group('SovereignIdentity �?Identity Mutations', () {
    test('bumpEpoch increments epoch', () {
      final id = SovereignIdentity.generate('node-A');
      final bumped = id.bumpEpoch();
      expect(bumped.civilizationEpoch, id.civilizationEpoch + 1);
      expect(bumped.did, id.did);
      expect(bumped.publicKey, id.publicKey);
    });

    test('joinFederation sets federationId', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.federationId, isNull);
      final joined = id.joinFederation('fed-1');
      expect(joined.federationId, 'fed-1');
      expect(joined.did, id.did);
    });

    test('updateTrust changes trust level', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.trustLevel, TrustLevel.verified);
      final updated = id.updateTrust(TrustLevel.system);
      expect(updated.trustLevel, TrustLevel.system);
    });

    test('addCredential adds verifiable credential', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.credentials, isEmpty);
      final vc = VerifiableCredential.issue(
        issuerDid: 'did:omnivium:authority',
        subjectDid: id.did,
        credentialType: 'TestCredential',
        claims: {'test': true},
        ttl: 3600000,
        issuerSigningKey: 'test_signing_key',
        issuerPublicKey: 'test_public_key',
        issuerVerificationKey: 'test_verification_key',
      );
      final withCred = id.addCredential(vc);
      expect(withCred.credentials.length, 1);
      expect(withCred.credentials.first.credentialType, 'TestCredential');
    });
  });

  group('SovereignIdentity �?toJson', () {
    test('toJson includes all fields', () {
      final id = SovereignIdentity.generate('node-A', federationId: 'fed-1');
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

  group('VerifiableCredential �?Credential Issuance and Verification', () {
    test('issue creates valid credential', () {
      final vc = VerifiableCredential.issue(
        issuerDid: 'did:omnivium:authority',
        subjectDid: 'did:omnivium:1234',
        credentialType: 'ConstitutionalIdentity',
        claims: {'nodeId': 'node-A'},
        ttl: 3600000,
        issuerSigningKey: 'signing_key',
        issuerPublicKey: 'test_public_key',
        issuerVerificationKey: 'verification_key',
      );
      expect(vc.credentialId, startsWith('vc:'));
      expect(vc.issuerDid, 'did:omnivium:authority');
      expect(vc.subjectDid, 'did:omnivium:1234');
      expect(vc.credentialType, 'ConstitutionalIdentity');
      expect(vc.isValid, isTrue);
      expect(vc.verificationTag, isNotEmpty);
    });

    test('verifyCredential returns true with correct verification key', () {
      final signingKey = 'signing_key';
      final publicKey = 'test_public_key';
      final verificationKey = 'verification_key';
      final vc = VerifiableCredential.issue(
        issuerDid: 'did:omnivium:authority',
        subjectDid: 'did:omnivium:1234',
        credentialType: 'Test',
        claims: {'test': true},
        ttl: 3600000,
        issuerSigningKey: signingKey,
        issuerPublicKey: publicKey,
        issuerVerificationKey: verificationKey,
      );
      expect(VerifiableCredential.verifyCredential(vc, publicKey), isTrue);
    });

    test('verifyCredential returns false for wrong verification key', () {
      final vc = VerifiableCredential.issue(
        issuerDid: 'did:omnivium:authority',
        subjectDid: 'did:omnivium:1234',
        credentialType: 'Test',
        claims: {'test': true},
        ttl: 3600000,
        issuerSigningKey: 'correct_signing',
        issuerPublicKey: 'test_public_key',
        issuerVerificationKey: 'correct_verification',
      );
      expect(
        VerifiableCredential.verifyCredential(vc, 'wrong_verification'),
        isFalse,
      );
    });

    test(
      'verifyCredentialWithSigningKey returns true for correct signing key',
      () {
        final signingKey = 'signing_key';
        final vc = VerifiableCredential.issue(
          issuerDid: 'did:omnivium:authority',
          subjectDid: 'did:omnivium:1234',
          credentialType: 'Test',
          claims: {'test': true},
          ttl: 3600000,
          issuerSigningKey: signingKey,
          issuerPublicKey: 'test_public_key',
          issuerVerificationKey: 'verification_key',
        );
        expect(
          VerifiableCredential.verifyCredentialWithSigningKey(vc, signingKey),
          isTrue,
        );
      },
    );

    test('verifyCredential returns false for tampered claims', () {
      final signingKey = 'signing_key';
      final publicKey = 'test_public_key';
      final verificationKey = 'verification_key';
      final vc = VerifiableCredential.issue(
        issuerDid: 'did:omnivium:authority',
        subjectDid: 'did:omnivium:1234',
        credentialType: 'Test',
        claims: {'test': true},
        ttl: 3600000,
        issuerSigningKey: signingKey,
        issuerPublicKey: publicKey,
        issuerVerificationKey: verificationKey,
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
        VerifiableCredential.verifyCredential(tampered, verificationKey),
        isFalse,
      );
    });

    test('credential toJson includes proof and verificationTag', () {
      final vc = VerifiableCredential.issue(
        issuerDid: 'did:omnivium:authority',
        subjectDid: 'did:omnivium:1234',
        credentialType: 'Test',
        claims: {},
        ttl: 3600000,
        issuerSigningKey: 'key',
        issuerPublicKey: 'test_public_key',
        issuerVerificationKey: 'vkey',
      );
      final json = vc.toJson();
      expect(json.containsKey('proof'), isTrue);
      expect(json.containsKey('verificationTag'), isTrue);
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('issuer'), isTrue);
    });
  });

  group('ConstitutionalPassport �?Machine Sovereign Identity', () {
    test('issue creates valid passport', () {
      final holder = SovereignIdentity.generate(
        'node-A',
        federationId: 'fed-1',
      );
      final passport = ConstitutionalPassport.issue(
        holder: holder,
        reputationScore: 85.0,
        federationId: 'fed-1',
        issuerSigningKey: 'auth_signing_key',
        issuerPublicKey: 'test_public_key',
        issuerVerificationKey: 'auth_verification_key',
      );
      expect(passport.passportId, startsWith('passport:'));
      expect(passport.holder.did, holder.did);
      expect(passport.isValid, isTrue);
      expect(
        passport.identityCredential.credentialType,
        'ConstitutionalIdentity',
      );
      expect(passport.reputationCredential.credentialType, 'ReputationScore');
      expect(
        passport.federationCredential.credentialType,
        'FederationMembership',
      );
      expect(passport.verificationTag, isNotEmpty);
    });

    test('verifyPassport returns true with correct verification key', () {
      final holder = SovereignIdentity.generate('node-A');
      final publicKey = 'test_public_key';
      final passport = ConstitutionalPassport.issue(
        holder: holder,
        reputationScore: 90.0,
        federationId: 'fed-1',
        issuerSigningKey: 'auth_signing_key',
        issuerPublicKey: publicKey,
        issuerVerificationKey: 'auth_verification_key',
      );
      expect(
        ConstitutionalPassport.verifyPassport(passport, publicKey),
        isTrue,
      );
    });

    test('verifyPassport returns false for wrong verification key', () {
      final holder = SovereignIdentity.generate('node-A');
      final passport = ConstitutionalPassport.issue(
        holder: holder,
        reputationScore: 90.0,
        federationId: 'fed-1',
        issuerSigningKey: 'auth_signing_key',
        issuerPublicKey: 'test_public_key',
        issuerVerificationKey: 'correct_key',
      );
      expect(
        ConstitutionalPassport.verifyPassport(passport, 'wrong_key'),
        isFalse,
      );
    });

    test('passport includes reputation score in credential claims', () {
      final holder = SovereignIdentity.generate('node-A');
      final passport = ConstitutionalPassport.issue(
        holder: holder,
        reputationScore: 92.5,
        federationId: 'fed-1',
        issuerSigningKey: 'key',
        issuerPublicKey: 'test_public_key',
        issuerVerificationKey: 'vkey',
      );
      expect(passport.reputationCredential.claims['score'], 92.5);
    });

    test('passport includes federation membership in credential claims', () {
      final holder = SovereignIdentity.generate('node-A');
      final passport = ConstitutionalPassport.issue(
        holder: holder,
        reputationScore: 85.0,
        federationId: 'fed-1',
        issuerSigningKey: 'key',
        issuerPublicKey: 'test_public_key',
        issuerVerificationKey: 'vkey',
      );
      expect(passport.federationCredential.claims['federationId'], 'fed-1');
    });

    test('passport toJson includes all credentials and verificationTag', () {
      final holder = SovereignIdentity.generate('node-A');
      final passport = ConstitutionalPassport.issue(
        holder: holder,
        reputationScore: 85.0,
        federationId: 'fed-1',
        issuerSigningKey: 'key',
        issuerPublicKey: 'test_public_key',
        issuerVerificationKey: 'vkey',
      );
      final json = passport.toJson();
      expect(json.containsKey('passportId'), isTrue);
      expect(json.containsKey('holder'), isTrue);
      expect(json.containsKey('identityCredential'), isTrue);
      expect(json.containsKey('reputationCredential'), isTrue);
      expect(json.containsKey('federationCredential'), isTrue);
      expect(json.containsKey('proof'), isTrue);
      expect(json.containsKey('verificationTag'), isTrue);
    });
  });

  group('SovereignSignature �?Signature Verification', () {
    test('self-signature is valid for identity', () {
      final id = SovereignIdentity.generate('node-A');
      expect(SovereignIdentity.verify(id), isTrue);
    });

    test('tampered identity fails verification', () {
      final id = SovereignIdentity.generate('node-A');
      final tampered = SovereignIdentity(
        did: id.did,
        nodeId: id.nodeId,
        keyPair: SovereignKeyPair(
          publicKey: id.publicKey,
          signingKey: id.keyPair.signingKey,
          verificationKey: id.keyPair.verificationKey,
          algorithm: id.keyPair.algorithm,
          createdAt: id.keyPair.createdAt,
        ),
        civilizationEpoch: id.civilizationEpoch,
        trustLevel: id.trustLevel,
        constitutionalAncestry: id.constitutionalAncestry,
        createdAt: id.createdAt + 1,
        selfSignature: id.selfSignature,
      );
      expect(SovereignIdentity.verify(tampered), isFalse);
    });

    test('verifySignature works with verification key', () {
      final id = SovereignIdentity.generate('node-A');
      final sig = id.selfSignature;
      final sigData = '${id.did}|${id.publicKey}|${id.createdAt}';
      expect(
        SovereignIdentity.verifySignature(sigData, sig, id.verificationKey),
        isTrue,
      );
    });

    test('verifySignature fails with wrong verification key', () {
      final id = SovereignIdentity.generate('node-A');
      final sig = id.selfSignature;
      final sigData = '${id.did}|${id.publicKey}|${id.createdAt}';
      expect(
        SovereignIdentity.verifySignature(sigData, sig, 'wrong_key'),
        isFalse,
      );
    });
  });

  group('SovereignIdentity �?Cross-Node Identity', () {
    test('two nodes have distinct DIDs and keys', () {
      final nodeA = SovereignIdentity.generate('node-A');
      final nodeB = SovereignIdentity.generate('node-B');
      expect(nodeA.did, isNot(equals(nodeB.did)));
      expect(nodeA.publicKey, isNot(equals(nodeB.publicKey)));
      expect(nodeA.verificationKey, isNot(equals(nodeB.verificationKey)));
    });

    test('node with federation has federationId in DID', () {
      final id = SovereignIdentity.generate('node-A', federationId: 'fed-1');
      expect(id.federationId, 'fed-1');
    });

    test('constitutional ancestry starts with genesis', () {
      final id = SovereignIdentity.generate('node-A');
      expect(id.constitutionalAncestry, ['genesis']);
    });

    test('epoch progression tracks civilization evolution', () {
      var id = SovereignIdentity.generate('node-A');
      expect(id.civilizationEpoch, 0);
      id = id.bumpEpoch();
      expect(id.civilizationEpoch, 1);
      id = id.bumpEpoch();
      expect(id.civilizationEpoch, 2);
    });
  });
}
