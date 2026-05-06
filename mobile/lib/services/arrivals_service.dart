import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

/// One arrival prediction at a specific stop, for a specific trip.
/// Mirrors the shape returned by GET /api/v1/transit/arrivals?stopId=X.
class StopArrival {
  final String stopId;
  final String stopName;
  final double stopLat;
  final double stopLng;
  final String routeId;
  final String routeShortName;
  final String headsign;
  final String tripId;
  final DateTime scheduledArrival;
  final DateTime? estimatedArrival;
  final int delaySeconds;
  final String status; // ON_TIME, DELAYED, EARLY, etc.

  const StopArrival({
    required this.stopId,
    required this.stopName,
    required this.stopLat,
    required this.stopLng,
    required this.routeId,
    required this.routeShortName,
    required this.headsign,
    required this.tripId,
    required this.scheduledArrival,
    required this.estimatedArrival,
    required this.delaySeconds,
    required this.status,
  });

  /// Friendly label like "2:34 PM" in the user's local timezone.
  String get arrivalTimeLabel {
    final t = (estimatedArrival ?? scheduledArrival).toLocal();
    final hour = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final minute = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  /// "in 4 min" / "in 1 min" / "now" for the next-arrival display.
  String get etaLabel {
    final t = (estimatedArrival ?? scheduledArrival);
    final mins = t.difference(DateTime.now().toUtc()).inMinutes;
    if (mins <= 0) return 'now';
    if (mins == 1) return 'in 1 min';
    return 'in $mins min';
  }

  /// Whether this arrival is coming up soon (within 60 min) and not in the past.
  bool get isUpcoming {
    final t = (estimatedArrival ?? scheduledArrival);
    final diff = t.difference(DateTime.now().toUtc());
    return diff.inMinutes >= -1 && diff.inMinutes <= 60;
  }
}

/// Fetches arrivals for a stop. Returns raw list — caller filters by route.
final stopArrivalsProvider = FutureProvider.autoDispose
    .family<List<StopArrival>, StopArrivalsKey>((ref, key) async {
  final dio = buildApiClient();
  final resp = await dio.get('/transit/arrivals',
      queryParameters: {'stopId': key.stopId});
  final raw = (resp.data['arrivals'] as List<dynamic>? ?? []);
  return raw
      .whereType<Map<String, dynamic>>()
      .map((j) => StopArrival(
            stopId: key.stopId,
            stopName: key.stopName,
            stopLat: key.stopLat,
            stopLng: key.stopLng,
            routeId: (j['routeId'] as String?) ?? '',
            routeShortName: (j['routeShortName'] as String?) ?? '',
            headsign: (j['headsign'] as String?) ?? '',
            tripId: (j['tripId'] as String?) ?? '',
            scheduledArrival: DateTime.tryParse(
                    (j['scheduledArrival'] as String?) ?? '')
                ?.toUtc() ??
                DateTime.now().toUtc(),
            estimatedArrival: DateTime.tryParse(
                    (j['estimatedArrival'] as String?) ?? '')
                ?.toUtc(),
            delaySeconds: (j['delaySeconds'] as num? ?? 0).toInt(),
            status: (j['status'] as String?) ?? 'UNKNOWN',
          ))
      .toList();
});

class StopArrivalsKey {
  final String stopId;
  final String stopName;
  final double stopLat;
  final double stopLng;
  const StopArrivalsKey({
    required this.stopId,
    required this.stopName,
    required this.stopLat,
    required this.stopLng,
  });
  @override
  bool operator ==(Object o) =>
      o is StopArrivalsKey && o.stopId == stopId;
  @override
  int get hashCode => stopId.hashCode;
}
