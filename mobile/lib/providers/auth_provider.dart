import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_client.dart';

class AuthState {
  final String? token;
  final Map<String, dynamic>? user;

  const AuthState({this.token, this.user});
  bool get isLoggedIn => token != null && user != null;
  String get displayName => user?['displayName'] as String? ?? '';
  String get email => user?['email'] as String? ?? '';
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final _dio = buildApiClient();
  static const _storage = FlutterSecureStorage();

  /// Restore session from secure storage on app launch.
  Future<void> restore() async {
    final token = await _storage.read(key: 'soundsync_token');
    if (token == null) return;
    try {
      final resp = await _dio.get('/users/me');
      state = AuthState(
        token: token,
        user: resp.data as Map<String, dynamic>,
      );
    } catch (_) {
      // Token expired or invalid — clear it silently
      await clearToken();
    }
  }

  Future<void> login(String email, String password) async {
    final resp = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = resp.data['token'] as String;
    await saveToken(token);
    state = AuthState(
      token: token,
      user: resp.data['user'] as Map<String, dynamic>,
    );
  }

  Future<void> register(
      String email, String password, String displayName) async {
    final resp = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    final token = resp.data['token'] as String;
    await saveToken(token);
    state = AuthState(
      token: token,
      user: resp.data['user'] as Map<String, dynamic>,
    );
  }

  Future<void> updateSettings({String? tempUnit, String? distanceUnit}) async {
    final body = <String, dynamic>{};
    if (tempUnit != null) body['tempUnit'] = tempUnit;
    if (distanceUnit != null) body['distanceUnit'] = distanceUnit;
    if (body.isEmpty) return;

    await _dio.patch('/users/me/settings', data: body);

    // Reflect the change locally without a round-trip
    if (state.user != null) {
      final updated = Map<String, dynamic>.from(state.user!);
      body.forEach((k, v) => updated[k] = v);
      state = AuthState(token: state.token, user: updated);
    }
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/users/me');
    await clearToken();
    state = const AuthState();
  }

  Future<void> logout() async {
    await clearToken();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);

/// Resolves once the stored session has been restored (or determined absent).
final authRestoreProvider = FutureProvider<void>((ref) async {
  await ref.read(authProvider.notifier).restore();
});
