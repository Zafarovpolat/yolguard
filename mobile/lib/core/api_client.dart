import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'storage.dart';

/// Ошибка API с человекочитаемым сообщением (детально из FastAPI `detail`).
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

/// Тонкий HTTP-клиент к бэкенду: подставляет Bearer-токен, разбирает JSON,
/// нормализует ошибки FastAPI (поле `detail`).
class ApiClient {
  ApiClient({TokenStorage? storage}) : _storage = storage ?? TokenStorage();

  final TokenStorage _storage;
  final String _base = AppConfig.baseUrl;

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _storage.read();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('$_base$path');

  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: await _headers());
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await http.post(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res = await http.put(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final res = await http.patch(
      _uri(path),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: await _headers());
    return _decode(res);
  }

  /// Загрузка файла (multipart) — доказательства.
  Future<dynamic> uploadFile(
    String path, {
    required File file,
    required Map<String, String> fields,
  }) async {
    final token = await _storage.read();
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields);
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    final text = utf8.decode(res.bodyBytes);
    final dynamic data = text.isEmpty ? null : jsonDecode(text);
    if (ok) return data;

    // FastAPI отдаёт ошибку в поле `detail` (строка или список валидации).
    String message = 'Ошибка ${res.statusCode}';
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      message = detail is String ? detail : detail.toString();
    }
    throw ApiException(res.statusCode, message);
  }
}
