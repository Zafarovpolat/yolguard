import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/storage.dart';
import '../models.dart';
import '../services/auth_service.dart';
import '../services/case_service.dart';
import '../services/evidence_service.dart';
import '../services/vehicle_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Глобальное состояние приложения: сессия + доступ к сервисам.
class AppState extends ChangeNotifier {
  AppState() {
    final api = ApiClient(storage: _storage);
    auth = AuthService(api);
    vehicles = VehicleService(api);
    cases = CaseService(api);
    evidence = EvidenceService(api);
  }

  final TokenStorage _storage = TokenStorage();

  late final AuthService auth;
  late final VehicleService vehicles;
  late final CaseService cases;
  late final EvidenceService evidence;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  /// Проверка сохранённого токена при старте.
  Future<void> bootstrap() async {
    final token = await _storage.read();
    if (token == null) {
      _set(AuthStatus.unauthenticated, null);
      return;
    }
    try {
      user = await auth.me();
      _set(AuthStatus.authenticated, user);
    } catch (_) {
      await _storage.clear();
      _set(AuthStatus.unauthenticated, null);
    }
  }

  Future<void> login(String phone, String password) async {
    final (token, u) = await auth.login(phone: phone, password: password);
    await _storage.save(token);
    _set(AuthStatus.authenticated, u);
  }

  Future<void> register(String phone, String password, String? fullName) async {
    final (token, u) = await auth.register(
        phone: phone, password: password, fullName: fullName);
    await _storage.save(token);
    _set(AuthStatus.authenticated, u);
  }

  Future<void> logout() async {
    await _storage.clear();
    _set(AuthStatus.unauthenticated, null);
  }

  void _set(AuthStatus s, AppUser? u) {
    status = s;
    user = u;
    notifyListeners();
  }
}
