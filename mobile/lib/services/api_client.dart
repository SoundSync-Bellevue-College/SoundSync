import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Use PC's LAN IP for real device; use 10.0.2.2 for emulator
const _baseUrl = 'http://localhost:8080/api/v1';
const _storage = FlutterSecureStorage();

Dio buildApiClient() {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // Attach JWT token from secure storage on every request
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'soundsync_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      handler.next(error);
    },
  ));

  return dio;
}

/// Persist or clear the JWT token in secure storage.
Future<void> saveToken(String token) =>
    _storage.write(key: 'soundsync_token', value: token);

Future<void> clearToken() => _storage.delete(key: 'soundsync_token');
