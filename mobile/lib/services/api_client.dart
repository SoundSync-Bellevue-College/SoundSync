import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Injected at build time via --dart-define-from-file=dart_defines.env
// Physical device & iOS simulator: use Mac's LAN IP (see dart_defines.env)
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.0.173:8080/api/v1',
);
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
