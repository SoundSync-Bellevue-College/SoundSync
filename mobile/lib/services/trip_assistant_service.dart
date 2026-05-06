import 'package:dio/dio.dart';
import 'api_client.dart';
import 'reliability_service.dart';
import 'routes_lookup.dart';

/// One message in the chat — either from the user or the assistant.
enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final List<String> dataSources; // e.g. "Reliability summary", "Live vehicles"
  ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    this.dataSources = const [],
  });
}

/// TripAssistantService — answers user questions about transit.
///
/// Sprint 2 STUB: until Nolan ships /api/v1/chat (or equivalent), this service
/// answers using real data from existing endpoints (/reliability/summary,
/// /transit/vehicles) wrapped in friendly natural-language responses.
///
/// When Nolan's endpoint lands, replace the body of [ask] with one HTTP call.
class TripAssistantService {
  TripAssistantService._();
  static final TripAssistantService instance = TripAssistantService._();

  final Dio _dio = buildApiClient();

  /// Whether to use the real backend (true) or the local stub (false).
  /// Flip to true when Nolan deploys /api/v1/chat.
  static const bool _useRealBackend = false;

  Future<ChatMessage> ask(String userQuery) async {
    if (_useRealBackend) {
      // FUTURE: when Nolan ships the endpoint, replace this whole branch with:
      //   final resp = await _dio.post('/chat', data: {'query': userQuery});
      //   return ChatMessage(role: ChatRole.assistant,
      //       text: resp.data['answer'], timestamp: DateTime.now(),
      //       dataSources: List<String>.from(resp.data['sources'] ?? []));
      throw UnimplementedError('Real backend not wired yet');
    }
    return _stubAnswer(userQuery);
  }

  /// Stubbed answer logic. Looks at the question, calls real data endpoints
  /// where it can, and composes a natural-language response.
  Future<ChatMessage> _stubAnswer(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      return _say(
        "Ask me about a bus route, delays near you, or whether you'll make it "
        "somewhere on time.",
      );
    }

    // Strategy 1: route-specific question (mentions a route number/name)
    final routeMatch = _extractRouteName(q);
    if (routeMatch != null) {
      return _answerAboutRoute(routeMatch);
    }

    // Strategy 2: general delays / network status
    if (_containsAny(q, ['delay', 'late', 'on time', 'reliable', 'how are buses', 'how is the network'])) {
      return _answerNetworkStatus();
    }

    // Strategy 3: nearby buses
    if (_containsAny(q, ['near me', 'nearby', 'close to me', 'what bus', 'which bus'])) {
      return _answerNearbyBuses();
    }

    // Fallback
    return _say(
      "I'm in beta — my full AI service is being deployed soon. For now, try "
      "asking about a specific route (like \"how is route 128 today?\"), "
      "general delays, or buses near you.",
    );
  }

  // ── Answer composers ──────────────────────────────────────────────────────

  Future<ChatMessage> _answerAboutRoute(String routeName) async {
    // Make sure routes lookup is loaded so we can do reverse lookups.
    await RoutesLookup.instance.load();

    // Step 1: does this route exist at all in the GTFS data?
    final knownRouteIds = RoutesLookup.instance.routeIdsByShortName(routeName);
    final routeExistsInGtfs = knownRouteIds.isNotEmpty;

    try {
      final resp = await _dio.get('/reliability/summary');
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] != true) {
        return routeExistsInGtfs
            ? _routeExistsButCannotReachML(routeName)
            : _genericRouteFallback(routeName);
      }

      final routes = (data['data']?['routes'] as List<dynamic>? ?? [])
          .map((r) => RouteReliabilitySummary.fromJson(r as Map<String, dynamic>))
          .toList();

      final candidateTails = knownRouteIds
          .map((id) => id.split('_').last.toLowerCase())
          .toSet();
      candidateTails.add(routeName.toLowerCase());

      final matches = routes.where((r) {
        final tail = r.routeId.split('_').last.toLowerCase();
        return candidateTails.contains(tail);
      }).toList();

      // Route is in GTFS but ML hasn't scored it yet
      if (matches.isEmpty) {
        if (routeExistsInGtfs) {
          final scoredShortNames = routes
              .where((r) => r.sampleCount > 0)
              .map((r) => RoutesLookup.instance.shortName(r.routeId.split('_').last))
              .where((s) => s.isNotEmpty)
              .toSet()
              .take(4)
              .toList();
          final suggestion = scoredShortNames.isNotEmpty
              ? " Routes I do have data on right now: ${scoredShortNames.join(', ')}."
              : "";
          return _say(
            "Route $routeName is in the system, but the AI reliability service "
            "hasn't scored it yet.$suggestion",
            sources: ['GTFS routes file'],
          );
        }
        return _genericRouteFallback(routeName);
      }

      final r = matches.first;
      if (r.sampleCount == 0) {
        return _say(
          "I see Route $routeName in the system but the AI hasn't logged "
          "enough observations yet to score it.",
          sources: ['Reliability summary'],
        );
      }

      final delayPart = r.hasValidDelay
          ? (r.avgDelaySeconds.abs() < 60
              ? "Buses are running about ${r.avgDelaySeconds.round()} seconds "
                "${r.avgDelaySeconds >= 0 ? 'late' : 'early'} on average."
              : "Buses are running about ${(r.avgDelaySeconds / 60).abs().toStringAsFixed(1)} "
                "minutes ${r.avgDelaySeconds >= 0 ? 'late' : 'early'} on average.")
          : "I don't have a reliable average delay for this route right now.";

      final headline = r.score >= 85
          ? "Route $routeName is running excellently today."
          : r.score >= 70
              ? "Route $routeName is doing pretty well today."
              : r.score >= 50
                  ? "Route $routeName is having a fair day."
                  : "Heads up — Route $routeName is struggling today.";

      return _say(
        "$headline The on-time rate is ${r.onTimeRate.toStringAsFixed(0)}% based "
        "on ${r.sampleCount} arrivals. $delayPart",
        sources: ['Reliability summary'],
      );
    } catch (e) {
      return routeExistsInGtfs
          ? _routeExistsButCannotReachML(routeName)
          : _genericRouteFallback(routeName);
    }
  }

  ChatMessage _routeExistsButCannotReachML(String routeName) {
    return _say(
      "Route $routeName exists in the system but I can't reach the AI "
      "reliability service right now to give you live stats.",
    );
  }

  Future<ChatMessage> _answerNetworkStatus() async {
    try {
      final resp = await _dio.get('/reliability/summary');
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] != true) {
        return _say("I can't reach the reliability service right now.");
      }
      final routes = (data['data']?['routes'] as List<dynamic>? ?? [])
          .map((r) => RouteReliabilitySummary.fromJson(r as Map<String, dynamic>))
          .where((r) => r.sampleCount > 0)
          .toList();
      if (routes.isEmpty) {
        return _say("No reliability data available right now.");
      }
      double weightedOnTime = 0;
      int totalSamples = 0;
      int troubled = 0;
      for (final r in routes) {
        weightedOnTime += r.onTimeRate * r.sampleCount;
        totalSamples += r.sampleCount;
        if (r.score < 50) troubled++;
      }
      final pct = (weightedOnTime / totalSamples).toStringAsFixed(0);
      final mood = double.parse(pct) >= 80
          ? "The network is running well."
          : double.parse(pct) >= 65
              ? "There are some delays out there."
              : "The network is having a rough time.";
      return _say(
        "$mood Across ${routes.length} tracked routes, on-time rate is $pct%. "
        "${troubled > 0 ? "$troubled routes are running notably late." : "Nothing major to report."}",
        sources: ['Reliability summary'],
      );
    } catch (e) {
      return _say("I can't reach the reliability service right now.");
    }
  }

  Future<ChatMessage> _answerNearbyBuses() async {
    try {
      final resp = await _dio.get('/transit/vehicles');
      final all = (resp.data['vehicles'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      // Dedupe — newest snapshot per vehicle
      final Map<String, Map<String, dynamic>> newest = {};
      for (final v in all) {
        final id = (v['vehicleId'] as String?) ?? '';
        if (id.isEmpty) continue;
        final tNew = DateTime.tryParse((v['timestamp'] as String?) ?? '');
        final existing = newest[id];
        if (existing == null) {
          newest[id] = v;
        } else {
          final tOld = DateTime.tryParse((existing['timestamp'] as String?) ?? '');
          if (tNew != null && (tOld == null || tNew.isAfter(tOld))) {
            newest[id] = v;
          }
        }
      }
      final count = newest.length;
      if (count == 0) {
        return _say("I don't see any live buses in the feed right now.");
      }
      return _say(
        "There are $count unique buses live in the feed across the network. "
        "On the home screen you can see the ones closest to you sorted by distance.",
        sources: ['Live vehicles'],
      );
    } catch (e) {
      return _say("I can't reach the live vehicle feed right now.");
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String? _extractRouteName(String q) {
    // Look for "C Line", "H Line", or pure-digit route numbers (1-999)
    final lineMatch = RegExp(r'\b([a-z])\s*line\b').firstMatch(q);
    if (lineMatch != null) return '${lineMatch.group(1)!.toUpperCase()} Line';
    final numMatch = RegExp(r'\b(\d{1,3})\b').firstMatch(q);
    if (numMatch != null) return numMatch.group(1);
    return null;
  }

  bool _containsAny(String s, List<String> needles) =>
      needles.any((n) => s.contains(n));

  ChatMessage _say(String text, {List<String> sources = const []}) {
    return ChatMessage(
      role: ChatRole.assistant,
      text: text,
      timestamp: DateTime.now(),
      dataSources: sources,
    );
  }

  ChatMessage _genericRouteFallback(String routeName) {
    return _say(
      "I don't have data for Route $routeName right now. Try asking about "
      "a different route, or check the home screen for what's running near you.",
    );
  }
}
