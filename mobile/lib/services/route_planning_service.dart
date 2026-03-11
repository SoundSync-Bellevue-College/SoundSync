import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';

const _directionsKey = googleMapsMobileKey;

final _dio = Dio(BaseOptions(
  baseUrl: 'https://maps.googleapis.com/maps/api',
  connectTimeout: const Duration(seconds: 12),
  receiveTimeout: const Duration(seconds: 12),
));

class RouteStep {
  final String travelMode;
  final String duration;
  final String distance;
  final int durationSeconds;
  final int distanceMeters;
  // Start location — used for walk weather fetch
  final double? startLat;
  final double? startLng;
  // Encoded polylines for this step (list so merged walks can accumulate multiple)
  final List<String> stepPolylines;
  // Transit-only
  final String? lineShortName;
  final String? lineName;
  final String? vehicleType;
  final String? departureStop;
  final String? arrivalStop;
  final double? departureLat;
  final double? departureLng;
  final double? arrivalLat;
  final double? arrivalLng;
  final String? headsign;
  final int? numStops;
  final String? stepDepartureTime;
  final String? stepArrivalTime;
  final String? agencyName;

  const RouteStep({
    required this.travelMode,
    required this.duration,
    required this.distance,
    this.durationSeconds = 0,
    this.distanceMeters = 0,
    this.startLat,
    this.startLng,
    this.stepPolylines = const [],
    this.lineShortName,
    this.lineName,
    this.vehicleType,
    this.departureStop,
    this.arrivalStop,
    this.departureLat,
    this.departureLng,
    this.arrivalLat,
    this.arrivalLng,
    this.headsign,
    this.numStops,
    this.stepDepartureTime,
    this.stepArrivalTime,
    this.agencyName,
  });

  /// Returns a merged walk step combining this + [other].
  RouteStep mergeWalk(RouteStep other) {
    final totalSecs = durationSeconds + other.durationSeconds;
    final totalMtrs = distanceMeters + other.distanceMeters;
    final mins = (totalSecs / 60).round();
    final miles = totalMtrs / 1609.34;
    final distText = miles < 0.1
        ? '${totalMtrs} m'
        : '${miles.toStringAsFixed(1)} mi';
    return RouteStep(
      travelMode: 'WALKING',
      duration: '$mins min',
      distance: distText,
      durationSeconds: totalSecs,
      distanceMeters: totalMtrs,
      startLat: startLat,
      startLng: startLng,
      stepPolylines: [...stepPolylines, ...other.stepPolylines],
    );
  }
}

class TransitRoute {
  final String totalDuration;
  final String departureTime;
  final String arrivalTime;
  final List<RouteStep> steps;
  final String? encodedPolyline;

  const TransitRoute({
    required this.totalDuration,
    required this.departureTime,
    required this.arrivalTime,
    required this.steps,
    this.encodedPolyline,
  });

  /// Returns steps with consecutive walk steps merged into one.
  List<RouteStep> get mergedSteps {
    final result = <RouteStep>[];
    RouteStep? pendingWalk;
    for (final step in steps) {
      if (step.travelMode == 'WALKING') {
        pendingWalk =
            pendingWalk == null ? step : pendingWalk.mergeWalk(step);
      } else {
        if (pendingWalk != null) {
          result.add(pendingWalk);
          pendingWalk = null;
        }
        result.add(step);
      }
    }
    if (pendingWalk != null) result.add(pendingWalk);
    return result;
  }
}

class RoutePlanningService {
  static Future<List<TransitRoute>> plan({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final resp = await _dio.get('/directions/json', queryParameters: {
        'origin': '$originLat,$originLng',
        'destination': '$destLat,$destLng',
        'mode': 'transit',
        'alternatives': 'true',
        'transit_mode': 'bus|subway|train|tram|rail',
        'key': _directionsKey,
      });

      final status = resp.data['status'] as String?;
      debugPrint('[Directions] status=$status');
      if (status != 'OK') {
        debugPrint('[Directions] error=${resp.data['error_message']}');
        return [];
      }

      final routes = resp.data['routes'] as List<dynamic>? ?? [];
      return routes.map(_parseRoute).toList();
    } catch (e) {
      debugPrint('[Directions] exception: $e');
      return [];
    }
  }

  static TransitRoute _parseRoute(dynamic r) {
    final route = r as Map<String, dynamic>;
    final leg = (route['legs'] as List).first as Map<String, dynamic>;

    final steps = (leg['steps'] as List<dynamic>? ?? [])
        .expand<RouteStep>((s) {
          final step = s as Map<String, dynamic>;
          final subSteps = step['steps'] as List<dynamic>?;
          if (subSteps != null && subSteps.isNotEmpty) {
            return subSteps.map((ss) => _parseStep(ss as Map<String, dynamic>));
          }
          return [_parseStep(step)];
        })
        .toList();

    final polyline = route['overview_polyline']?['points'] as String?;

    return TransitRoute(
      totalDuration: _text(leg['duration']) ?? '',
      departureTime: _text(leg['departure_time']) ?? '',
      arrivalTime: _text(leg['arrival_time']) ?? '',
      steps: steps,
      encodedPolyline: polyline,
    );
  }

  static RouteStep _parseStep(Map<String, dynamic> step) {
    final mode = step['travel_mode'] as String? ?? 'WALKING';
    final dur = _text(step['duration']) ?? '';
    final dist = _text(step['distance']) ?? '';
    final durSecs = (step['duration'] as Map?)?['value'] as int? ?? 0;
    final distMtrs = (step['distance'] as Map?)?['value'] as int? ?? 0;
    final startLoc = step['start_location'] as Map<String, dynamic>?;
    final startLat = (startLoc?['lat'] as num?)?.toDouble();
    final startLng = (startLoc?['lng'] as num?)?.toDouble();

    final stepPoly = (step['polyline'] as Map?)?['points'] as String?;
    final polylines = stepPoly != null ? [stepPoly] : <String>[];

    if (mode == 'TRANSIT') {
      final td = step['transit_details'] as Map<String, dynamic>? ?? {};
      final line = td['line'] as Map<String, dynamic>? ?? {};
      final vehicle = line['vehicle'] as Map<String, dynamic>? ?? {};
      final agencies = line['agencies'] as List<dynamic>?;
      final depStop = td['departure_stop'] as Map?;
      final arrStop = td['arrival_stop'] as Map?;
      final depLoc = depStop?['location'] as Map?;
      final arrLoc = arrStop?['location'] as Map?;
      return RouteStep(
        travelMode: 'TRANSIT',
        duration: dur,
        distance: dist,
        durationSeconds: durSecs,
        distanceMeters: distMtrs,
        startLat: startLat,
        startLng: startLng,
        stepPolylines: polylines,
        lineShortName: line['short_name'] as String?,
        lineName: line['name'] as String?,
        vehicleType: vehicle['type'] as String?,
        departureStop: depStop?['name'] as String?,
        arrivalStop: arrStop?['name'] as String?,
        departureLat: (depLoc?['lat'] as num?)?.toDouble(),
        departureLng: (depLoc?['lng'] as num?)?.toDouble(),
        arrivalLat: (arrLoc?['lat'] as num?)?.toDouble(),
        arrivalLng: (arrLoc?['lng'] as num?)?.toDouble(),
        headsign: td['headsign'] as String?,
        numStops: (td['num_stops'] as num?)?.toInt(),
        stepDepartureTime: _text(td['departure_time']),
        stepArrivalTime: _text(td['arrival_time']),
        agencyName: agencies != null && agencies.isNotEmpty
            ? ((agencies.first as Map)['name']) as String?
            : null,
      );
    }

    return RouteStep(
      travelMode: mode,
      duration: dur,
      distance: dist,
      durationSeconds: durSecs,
      distanceMeters: distMtrs,
      startLat: startLat,
      startLng: startLng,
      stepPolylines: polylines,
    );
  }

  static String? _text(dynamic obj) {
    if (obj == null) return null;
    if (obj is Map) return obj['text'] as String?;
    return obj.toString();
  }
}
