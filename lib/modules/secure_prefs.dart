import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SecurePrefs {
  invoicePlatformAccount,
  invoicePlatformPassword;

  static final FlutterSecureStorage _instance = const FlutterSecureStorage();

  Future<void> write(String value) => _instance.write(key: name, value: value);

  Future<String?> read() => _instance.read(key: name);

  Future<void> delete() => _instance.delete(key: name);

  static Future<void> deleteAll() => _instance.deleteAll();
}