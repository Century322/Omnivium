import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/session.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage _storage;

  AuthLocalDataSource(this._storage);

  Future<void> saveSession(Session session) async {
    await _storage.write(
      key: 'auth_session',
      value: jsonEncode(session.toJson()));
  }

  Future<Session?> getSession() async {
    final data = await _storage.read(key: 'auth_session');
    if (data == null) return null;
    return Session.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: 'auth_session');
  }

  Future<void> saveUser(User user) async {
    await _storage.write(
      key: 'auth_user',
      value: jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final data = await _storage.read(key: 'auth_user');
    if (data == null) return null;
    return User.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  Future<void> clearUser() async {
    await _storage.delete(key: 'auth_user');
  }
}
