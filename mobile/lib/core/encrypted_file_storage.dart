import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';
import 'secure_storage_service.dart';
import 'app_logger.dart';

class EncryptedFileStorage {
  static final EncryptedFileStorage _instance = EncryptedFileStorage._();
  static EncryptedFileStorage get instance => _instance;
  EncryptedFileStorage._();

  static const _masterKeyStorageKey = 'omnivium_file_encryption_key';

  Key? _masterKey;

  Future<void> init() async {
    final storage = SecureStorageService.instance;
    var keyBase64 = await storage.read(_masterKeyStorageKey);
    if (keyBase64 == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      keyBase64 = base64Encode(keyBytes);
      await storage.write(_masterKeyStorageKey, keyBase64);
    }
    _masterKey = Key.fromBase64(keyBase64);
  }

  Future<String> encryptFile(String sourcePath, {String? destPath}) async {
    if (_masterKey == null) await init();

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists())
      throw Exception('Source file not found: $sourcePath');

    final bytes = await sourceFile.readAsBytes();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_masterKey!, mode: AESMode.ctr));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final output = BytesBuilder();
    output.add(iv.bytes);
    output.add(encrypted.bytes);

    final targetPath = destPath ?? _getEncryptedPath(sourcePath);
    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(output.takeBytes());

    return targetPath;
  }

  Future<Uint8List> decryptFile(String encryptedPath) async {
    if (_masterKey == null) await init();

    final file = File(encryptedPath);
    if (!await file.exists())
      throw Exception('Encrypted file not found: $encryptedPath');

    final raw = await file.readAsBytes();
    if (raw.length < 17) throw Exception('Invalid encrypted file: too short');

    final ivBytes = raw.sublist(0, 16);
    final data = raw.sublist(16);
    final iv = IV(ivBytes);
    final encrypter = Encrypter(AES(_masterKey!, mode: AESMode.ctr));
    final decrypted = encrypter.decryptBytes(
      Encrypted(Uint8List.fromList(data)),
      iv: iv,
    );
    return Uint8List.fromList(decrypted);
  }

  Future<Stream<List<int>>> decryptFileStream(
    String encryptedPath, {
    int chunkSize = 65536,
  }) async {
    if (_masterKey == null) await init();

    final file = File(encryptedPath);
    if (!await file.exists())
      throw Exception('Encrypted file not found: $encryptedPath');

    final raw = await file.readAsBytes();
    if (raw.length < 17) throw Exception('Invalid encrypted file: too short');

    final ivBytes = raw.sublist(0, 16);
    final data = raw.sublist(16);
    final iv = IV(ivBytes);
    final encrypter = Encrypter(AES(_masterKey!, mode: AESMode.ctr));
    final decrypted = encrypter.decryptBytes(
      Encrypted(Uint8List.fromList(data)),
      iv: iv,
    );

    return Stream.fromIterable([Uint8List.fromList(decrypted)]);
  }

  Future<String> encryptString(String plaintext) async {
    if (_masterKey == null) await init();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_masterKey!, mode: AESMode.ctr));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final output = BytesBuilder();
    output.add(iv.bytes);
    output.add(encrypted.bytes);
    return base64Encode(output.takeBytes());
  }

  Future<String> decryptString(String ciphertext) async {
    if (_masterKey == null) await init();
    final raw = base64Decode(ciphertext);
    if (raw.length < 17) throw Exception('Invalid encrypted data');
    final ivBytes = raw.sublist(0, 16);
    final data = raw.sublist(16);
    final iv = IV(ivBytes);
    final encrypter = Encrypter(AES(_masterKey!, mode: AESMode.ctr));
    return encrypter.decrypt64(base64Encode(data), iv: iv);
  }

  Future<bool> isFileEncrypted(String path) async {
    if (!path.endsWith('.enc')) return false;
    return await File(path).exists();
  }

  Future<void> deleteEncryptedFile(String originalPath) async {
    final encPath = _getEncryptedPath(originalPath);
    final file = File(encPath);
    if (await file.exists()) await file.delete();
  }

  String _getEncryptedPath(String originalPath) {
    return '$originalPath.enc';
  }

  Future<void> migrateExistingFiles() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final mediaDir = Directory('${dir.path}/media');
      if (!await mediaDir.exists()) return;

      await for (final entity in mediaDir.list(recursive: true)) {
        if (entity is File && !entity.path.endsWith('.enc')) {
          final encPath = _getEncryptedPath(entity.path);
          if (!await File(encPath).exists()) {
            await encryptFile(entity.path, destPath: encPath);
            await entity.delete();
            AppLogger.instance.info('Migrated: ${entity.path} -> $encPath');
          }
        }
      }
    } catch (e) {
      AppLogger.instance.info('File migration failed: $e');
    }
  }
}
