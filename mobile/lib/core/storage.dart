import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище JWT-токена (MVP: shared_preferences).
/// Для прод-релиза стоит перейти на flutter_secure_storage.
class TokenStorage {
  static const _key = 'yolguard_access_token';

  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
