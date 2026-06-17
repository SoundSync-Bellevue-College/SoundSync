import 'dart:math';
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
/// Uses real data from existing endpoints (/reliability/summary,
/// /transit/vehicles) wrapped in friendly natural-language responses.
/// Multiple wording variations per scenario reduce the "scripted" feel.
class TripAssistantService {
  TripAssistantService._();
  static final TripAssistantService instance = TripAssistantService._();

  final Dio _dio = buildApiClient();
  final Random _rng = Random();

  /// Whether to use the real backend (true) or the local stub (false).
  /// Flip to true when the /chat endpoint is deployed.
  static const bool _useRealBackend = false;

  Future<ChatMessage> ask(String userQuery) async {
    if (_useRealBackend) {
      throw UnimplementedError('Real backend not wired yet');
    }
    return _stubAnswer(userQuery);
  }

  Future<ChatMessage> _stubAnswer(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return _emptyPrompt();

    // 1. Pleasantries — thank you / okay / bye
    if (_containsAny(q, ['thank', 'thanks', 'thx', 'appreciate'])) {
      return _pickSay([
        "Anytime — let me know if you want to check another route.",
        "Happy to help. Safe travels!",
        "You got it. Ping me if you need anything else.",
      ]);
    }
    if (_containsAny(q, ['bye', 'goodbye', 'see you', 'cya', 'later'])) {
      return _pickSay([
        "Safe trip out there.",
        "Catch you later — hope your bus is on time.",
        "Take care!",
      ]);
    }
    if (_isShortAck(q)) {
      return _pickSay([
        "Got it. Anything else?",
        "Cool. Want me to check a route?",
        "Sure — let me know if there's anything else.",
      ]);
    }

    // 2. Greetings
    if (_isGreeting(q)) return _greet();

    // 3. Capability / help
    if (_containsAny(q, [
      'what can you do', 'help', 'how do you work', 'what do you do',
      'what can you', 'how can you'
    ])) {
      return _capabilities();
    }

    // 4. Route-specific question
    final routeMatch = _extractRouteName(q);
    if (routeMatch != null) return _answerAboutRoute(routeMatch);

    // 5. General delays / network status
    if (_containsAny(q, [
      'delay', 'late', 'on time', 'reliable', 'how are buses',
      'how is the network', 'traffic', 'rush'
    ])) {
      return _answerNetworkStatus();
    }

    // 6. Nearby buses
    if (_containsAny(q, [
      'near me', 'nearby', 'close to me', 'what bus', 'which bus',
      'around me', 'closest'
    ])) {
      return _answerNearbyBuses();
    }

    return _genericFallback();
  }

  // ── Greeting / capability composers ───────────────────────────────────────

  ChatMessage _emptyPrompt() {
    return _pickSay([
      "What route would you like to check?",
      "Ask me about a route, delays in your area, or buses near you.",
      "Type a route number (like 271 or B Line) and I'll pull up its reliability.",
    ]);
  }

  ChatMessage _greet() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? "Morning"
        : hour < 17
            ? "Hi"
            : hour < 21
                ? "Evening"
                : "Hey";
    return _pickSay([
      "$greeting! Ask me about any bus route and I'll tell you how it's running today.",
      "$greeting. Curious how a specific route is doing? Just send the number.",
      "$greeting! I can check route reliability, live buses, and whether things are running on time.",
    ]);
  }

  ChatMessage _capabilities() {
    return _say(
      "I can tell you how a specific route is running today (try \"how is the 271?\"), "
      "give you a network-wide reliability snapshot (\"how are buses today?\"), "
      "or summarize what's live near you (\"any buses nearby?\"). "
      "I work off real-time transit data.",
    );
  }

  ChatMessage _genericFallback() {
    return _pickSay([
      "I didn't quite catch that. Try asking about a route — like \"how is route 550?\" — or general delays.",
      "I'm not sure how to answer that one. I'm best at route reliability and live bus questions.",
      "Hmm — I don't have a good answer for that. Try a route number, or ask how the network's running.",
    ]);
  }

  // ── Route answer ──────────────────────────────────────────────────────────

  Future<ChatMessage> _answerAboutRoute(String routeName) async {
    await RoutesLookup.instance.load();

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
              ? " I do have data on: ${scoredShortNames.join(', ')}."
              : "";
          return _say(
            "Route $routeName is in the system but doesn't have enough scored observations yet.$suggestion",
            sources: ['GTFS routes file'],
          );
        }
        return _genericRouteFallback(routeName);
      }

      final r = matches.first;
      if (r.sampleCount == 0) {
        return _say(
          "I see Route $routeName in the system but haven't logged enough arrivals yet to score it.",
          sources: ['Reliability summary'],
        );
      }

      // Build a delay phrase
      final delayPart = r.hasValidDelay
          ? (r.avgDelaySeconds.abs() < 60
              ? "Buses are running about ${r.avgDelaySeconds.round().abs()} "
                "second${r.avgDelaySeconds.round().abs() == 1 ? '' : 's'} "
                "${r.avgDelaySeconds >= 0 ? 'late' : 'early'} on average."
              : "Buses are running about ${(r.avgDelaySeconds / 60).abs().toStringAsFixed(1)} "
                "minutes ${r.avgDelaySeconds >= 0 ? 'late' : 'early'} on average.")
          : "I don't have a reliable delay average for it right now.";

      // Headline varies by score, with multiple wordings per band
      final headline = _pickOne(_headlinesForScore(r.score, routeName));

      return _say(
        "$headline The on-time rate is ${r.onTimeRate.toStringAsFixed(0)}% across "
        "${r.sampleCount} recent arrivals. $delayPart",
        sources: ['Reliability summary'],
      );
    } catch (e) {
      return routeExistsInGtfs
          ? _routeExistsButCannotReachML(routeName)
          : _genericRouteFallback(routeName);
    }
  }

  List<String> _headlinesForScore(double score, String routeName) {
    if (score >= 85) {
      return [
        "Route $routeName is having a great day.",
        "Route $routeName is running smoothly.",
        "$routeName looks excellent right now.",
      ];
    }
    if (score >= 70) {
      return [
        "Route $routeName is doing pretty well today.",
        "$routeName is in solid shape.",
        "Route $routeName looks decent.",
      ];
    }
    if (score >= 50) {
      return [
        "Route $routeName is having a mixed day.",
        "$routeName is running a bit uneven.",
        "Route $routeName is okay but not great.",
      ];
    }
    return [
      "Heads up — Route $routeName is struggling today.",
      "Route $routeName is having a rough one.",
      "$routeName isn't running well right now.",
    ];
  }

  ChatMessage _routeExistsButCannotReachML(String routeName) {
    return _say(
      "Route $routeName is in the system but I can't reach the reliability service to pull live stats.",
    );
  }

  // ── Network status ────────────────────────────────────────────────────────

  Future<ChatMessage> _answerNetworkStatus() async {
    try {
      final resp = await _dio.get('/reliability/summary');
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] != true) {
        return _say("I can't reach the reliability service at the moment.");
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
      final pctNum = double.parse(pct);

      // Time-of-day context
      final hour = DateTime.now().hour;
      final timeNote = (hour >= 6 && hour < 10)
          ? " It's morning rush, so some delays are typical."
          : (hour >= 15 && hour < 19)
              ? " It's the evening commute window, so traffic affects on-time numbers."
              : (hour >= 22 || hour < 5)
                  ? " It's late-night service, so frequency is lower than usual."
                  : "";

      final mood = pctNum >= 80
          ? "The network is running well overall."
          : pctNum >= 65
              ? "There are some delays out there."
              : "The network is having a rough stretch.";

      final troubledNote = troubled > 0
          ? "$troubled route${troubled == 1 ? ' is' : 's are'} running notably late."
          : "Nothing major to flag.";

      return _say(
        "$mood Across ${routes.length} tracked routes, the on-time rate is $pct%. "
        "$troubledNote$timeNote",
        sources: ['Reliability summary'],
      );
    } catch (e) {
      return _say("I can't reach the reliability service at the moment.");
    }
  }

  // ── Nearby buses ──────────────────────────────────────────────────────────

  Future<ChatMessage> _answerNearbyBuses() async {
    try {
      final resp = await _dio.get('/transit/vehicles');
      final all = (resp.data['vehicles'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
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
      return _pickSay([
        "$count buses are live in the feed across the network. The home screen has the ones closest to you.",
        "Right now $count buses are reporting live positions. Check the home map for the closest ones.",
        "Looks like $count buses are active. Closest-to-you list is on the home screen.",
      ], sources: ['Live vehicles']);
    } catch (e) {
      return _say("I can't reach the live vehicle feed right now.");
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isGreeting(String q) {
    final greetings = ['hi', 'hello', 'hey', 'yo', 'sup', 'howdy', 'good morning', 'good afternoon', 'good evening'];
    for (final g in greetings) {
      if (q == g || q.startsWith('$g ') || q.startsWith('$g,') || q.startsWith('$g!') || q.startsWith('$g.')) {
        return true;
      }
    }
    return false;
  }

  bool _isShortAck(String q) {
    const acks = {'ok', 'okay', 'k', 'cool', 'got it', 'sure', 'alright', 'sounds good', 'nice'};
    return acks.contains(q);
  }

  String? _extractRouteName(String q) {
    final lineMatch = RegExp(r'\b([a-z])\s*line\b').firstMatch(q);
    if (lineMatch != null) return '${lineMatch.group(1)!.toUpperCase()} Line';
    final numMatch = RegExp(r'\b(\d{1,3})\b').firstMatch(q);
    if (numMatch != null) return numMatch.group(1);
    return null;
  }

  bool _containsAny(String s, List<String> needles) =>
      needles.any((n) => s.contains(n));

  T _pickOne<T>(List<T> options) => options[_rng.nextInt(options.length)];

  ChatMessage _pickSay(List<String> options, {List<String> sources = const []}) {
    return _say(_pickOne(options), sources: sources);
  }

  ChatMessage _say(String text, {List<String> sources = const []}) {
    return ChatMessage(
      role: ChatRole.assistant,
      text: text,
      timestamp: DateTime.now(),
      dataSources: sources,
    );
  }

  ChatMessage _genericRouteFallback(String routeName) {
    return _pickSay([
      "I don't have data for Route $routeName right now. Try another route, or check the home screen for what's running near you.",
      "Route $routeName isn't showing up in my data — it may not be in the feed I'm pulling from.",
      "I'm not finding Route $routeName. Double-check the number? Or try a different route.",
    ]);
  }
}
