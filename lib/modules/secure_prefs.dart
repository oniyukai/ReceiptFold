import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum SecurePrefs {
  invoicePlatformAccount,
  invoicePlatformPassword,
  webDAVAccount;

  static const FlutterSecureStorage _instance = FlutterSecureStorage();

  static Future<void> deleteAll() => _instance.deleteAll();

  Future<void> write(String value) => _instance.write(key: name, value: value);

  Future<String?> read() => _instance.read(key: name);

  Future<void> delete() => _instance.delete(key: name);
}
