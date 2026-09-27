import '../core/api_client.dart';
import '../models.dart';

/// Аутентификация: регистрация/логин по телефону, текущий пользователь.
class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  /// Возвращает (токен, пользователь).
  Future<(String, AppUser)> register({
    required String phone,
    required String password,
    String? fullName,
  }) async {
    final data = await _api.post('/api/auth/register', body: {
      'phone': phone,
      'password': password,
      if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
    }) as Map<String, dynamic>;
    return (
      data['access_token'] as String,
      AppUser.fromJson(data['user'] as Map<String, dynamic>)
    );
  }

  Future<(String, AppUser)> login(
      {required String phone, required String password}) async {
    final data = await _api.post('/api/auth/login', body: {
      'phone': phone,
      'password': password,
    }) as Map<String, dynamic>;
    return (
      data['access_token'] as String,
      AppUser.fromJson(data['user'] as Map<String, dynamic>)
    );
  }

  Future<AppUser> me() async {
    final data = await _api.get('/api/auth/me') as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }
}
