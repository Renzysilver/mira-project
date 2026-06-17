import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

class SecureStorage {
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  Future<void> saveAuthToken(String token) async => await _storage.write(key: _authTokenKey, value: token);
  Future<String?> getAuthToken() async => await _storage.read(key: _authTokenKey);
  Future<void> deleteAuthToken() async => await _storage.delete(key: _authTokenKey);
  Future<void> saveUserId(String id) async => await _storage.write(key: _userIdKey, value: id);
  Future<String?> getUserId() async => await _storage.read(key: _userIdKey);
  Future<void> saveUserEmail(String email) async => await _storage.write(key: _userEmailKey, value: email);
  Future<String?> getUserEmail() async => await _storage.read(key: _userEmailKey);
  Future<void> clearAll() async => await _storage.deleteAll();
}
