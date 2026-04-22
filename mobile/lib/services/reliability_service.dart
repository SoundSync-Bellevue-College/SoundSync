import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class TimeBinMetrics {
  final String bin;
  final int sampleCount;
  final double onTimeRate;
  final double avgDelaySeconds;
  final double score;

  const TimeBinMetrics({
    required this.bin,
    required this.sampleCount,
    required this.onTimeRate,
    required this.avgDelaySeconds,
    required this.score,
  });

  factory TimeBinMetrics.fromJson(Map<String, dynamic> j) => TimeBinMetrics(
        bin: j['bin'] as String,
        sampleCount: (j['sample_count'] as num).toInt(),
        onTimeRate: (j['on_time_rate'] as num).toDouble(),
        avgDelaySeconds: (j['avg_delay_seconds'] as num).toDouble(),
        score: (j['score'] as num).toDouble(),
      );
}

class RouteMetrics {
  final String stopId;
  final String routeId;
  final int sampleCount;
  final double onTimeRate;
  final double avgDelaySeconds;
  final double avgDelayMinutes;
  final double delayVariance;
  final double score;
  final List<TimeBinMetrics> timeOfDay;

  const RouteMetrics({
    required this.stopId,
    required this.routeId,
    required this.sampleCount,
    required this.onTimeRate,
    required this.avgDelaySeconds,
    required this.avgDelayMinutes,
    required this.delayVariance,
    required this.score,
    required this.timeOfDay,
  });

  factory RouteMetrics.fromJson(Map<String, dynamic> j) => RouteMetrics(
        stopId: j['stop_id'] as String? ?? '',
        routeId: j['route_id'] as String? ?? '',
        sampleCount: (j['sample_count'] as num? ?? 0).toInt(),
        onTimeRate: (j['on_time_rate'] as num? ?? 0).toDouble(),
        avgDelaySeconds: (j['avg_delay_seconds'] as num? ?? 0).toDouble(),
        avgDelayMinutes: (j['avg_delay_minutes'] as num? ?? 0).toDouble(),
        delayVariance: (j['delay_variance'] as num? ?? 0).toDouble(),
        score: (j['score'] as num? ?? 0).toDouble(),
        timeOfDay: (j['time_of_day'] as List<dynamic>? ?? [])
            .map((e) => TimeBinMetrics.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StopReliability {
  final String stopId;
  final List<RouteMetrics> routes;

  const StopReliability({required this.stopId, required this.routes});

  factory StopReliability.fromJson(Map<String, dynamic> j) => StopReliability(
        stopId: j['stop_id'] as String? ?? '',
        routes: (j['routes'] as List<dynamic>? ?? [])
            .map((e) => RouteMetrics.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PredictionResult {
  final String stopId;
  final String routeId;
  final String timeBin;
  final double predictedDelaySec;
  final double predictedDelayMin;
  final double onTimeRate;
  final int sampleCount;

  const PredictionResult({
    required this.stopId,
    required this.routeId,
    required this.timeBin,
    required this.predictedDelaySec,
    required this.predictedDelayMin,
    required this.onTimeRate,
    required this.sampleCount,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) => PredictionResult(
        stopId: j['stop_id'] as String? ?? '',
        routeId: j['route_id'] as String? ?? '',
        timeBin: j['time_bin'] as String? ?? '',
        predictedDelaySec: (j['predicted_delay_seconds'] as num? ?? 0).toDouble(),
        predictedDelayMin: (j['predicted_delay_minutes'] as num? ?? 0).toDouble(),
        onTimeRate: (j['on_time_rate'] as num? ?? 0).toDouble(),
        sampleCount: (j['sample_count'] as num? ?? 0).toInt(),
      );
}

/// Route-level reliability summary (no stop context) returned by
/// `/reliability/summary`. Covers aggregate on-time rate + average delay
/// across all observations for that route.
///
/// Some backend values can be wildly out-of-range (e.g. negative delays of
/// days/weeks due to GTFS time-parsing edge cases). Consumers should sanity-
/// check via [hasValidDelay] before showing delay numbers to users.
class RouteReliabilitySummary {
  final String routeId;
  final double score;
  final double onTimeRate;
  final double avgDelaySeconds;
  final int sampleCount;

  const RouteReliabilitySummary({
    required this.routeId,
    required this.score,
    required this.onTimeRate,
    required this.avgDelaySeconds,
    required this.sampleCount,
  });

  factory RouteReliabilitySummary.fromJson(Map<String, dynamic> j) =>
      RouteReliabilitySummary(
        routeId: j['route_id'] as String? ?? '',
        score: (j['score'] as num? ?? 0).toDouble(),
        onTimeRate: (j['on_time_rate'] as num? ?? 0).toDouble(),
        avgDelaySeconds: (j['avg_delay_seconds'] as num? ?? 0).toDouble(),
        sampleCount: (j['sample_count'] as num? ?? 0).toInt(),
      );

  /// True if avg_delay_seconds looks plausible (within ±30 min window).
  /// The backend occasionally emits nonsense values like -273328 seconds.
  bool get hasValidDelay =>
      avgDelaySeconds.abs() < 30 * 60 && sampleCount > 0;

  /// Friendly label describing how this route is running today.
  /// Returns 'excellent' / 'good' / 'fair' / 'poor'.
  String get statusLabel {
    if (score >= 85) return 'excellent';
    if (score >= 70) return 'good';
    if (score >= 50) return 'fair';
    return 'poor';
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Fetch reliability data for all routes at a stop.
final stopReliabilityProvider =
    FutureProvider.family.autoDispose<StopReliability, String>((ref, stopId) async {
  final dio = buildApiClient();
  final resp = await dio.get('/reliability/$stopId');
  final data = resp.data as Map<String, dynamic>;
  if (data['success'] != true) {
    throw Exception(data['error'] ?? 'Failed to fetch reliability');
  }
  return StopReliability.fromJson(data['data'] as Map<String, dynamic>);
});

/// Fetch detailed metrics for a specific route at a stop.
/// Key is "$stopId|$routeId".
final routeReliabilityProvider =
    FutureProvider.family.autoDispose<RouteMetrics, String>((ref, key) async {
  final parts = key.split('|');
  final stopId = parts[0];
  final routeId = parts[1];
  final dio = buildApiClient();
  final resp = await dio.get('/reliability/$stopId/$routeId');
  final data = resp.data as Map<String, dynamic>;
  if (data['success'] != true) {
    throw Exception(data['error'] ?? 'Failed to fetch route reliability');
  }
  return RouteMetrics.fromJson(data['data'] as Map<String, dynamic>);
});

/// Fetch predicted delay for the current time-of-day.
/// Key is "$stopId|$routeId".
final predictionProvider =
    FutureProvider.family.autoDispose<PredictionResult, String>((ref, key) async {
  final parts = key.split('|');
  final stopId = parts[0];
  final routeId = parts[1];
  final dio = buildApiClient();
  final resp = await dio.get('/prediction/$stopId/$routeId');
  final data = resp.data as Map<String, dynamic>;
  if (data['success'] != true) {
    throw Exception(data['error'] ?? 'Failed to fetch prediction');
  }
  return PredictionResult.fromJson(data['data'] as Map<String, dynamic>);
});

/// Fetch reliability summary across all tracked routes. Auto-refreshes every
/// 60s while a widget listens — this is the primary data source for the
/// home-screen anomaly banner and per-route reliability badges.
final reliabilitySummaryProvider =
    StreamProvider.autoDispose<List<RouteReliabilitySummary>>((ref) async* {
  final dio = buildApiClient();
  while (true) {
    try {
      final resp = await dio.get('/reliability/summary');
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final routes = (data['data']?['routes'] as List<dynamic>? ?? [])
            .map((e) => RouteReliabilitySummary.fromJson(e as Map<String, dynamic>))
            .toList();
        yield routes;
      }
    } catch (_) {
      // silently skip — keep previous data on screen
    }
    await Future.delayed(const Duration(seconds: 60));
  }
});
