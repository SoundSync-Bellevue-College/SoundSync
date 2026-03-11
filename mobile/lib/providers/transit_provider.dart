import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

// Polls the backend every 10 seconds for live vehicle positions.
final vehiclesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
  final dio = buildApiClient();
  while (true) {
    try {
      final resp = await dio.get('/transit/vehicles');
      final list = resp.data['vehicles'] as List<dynamic>;
      yield list.cast<Map<String, dynamic>>();
    } catch (_) {
      // silently skip failed fetches — keep previous data on screen
    }
    await Future.delayed(const Duration(seconds: 10));
  }
});
