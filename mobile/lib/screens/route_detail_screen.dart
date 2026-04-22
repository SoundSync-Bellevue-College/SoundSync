import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/routes_lookup.dart';
import '../services/api_client.dart';
import '../services/reliability_service.dart';

// ─── Design Tokens (matches home_screen.dart) ─────────────────────────────────
const _kPrimary    = Color(0xFF1A56DB);
const _kAccent     = Color(0xFF16A34A);
const _kSurface    = Colors.white;
const _kBg         = Color(0xFFF8F9FB);
const _kText       = Color(0xFF111827);
const _kSubtext    = Color(0xFF6B7280);
const _kBorder     = Color(0xFFE5E7EB);
const _kUrgentText = Color(0xFFD97706);

class RouteDetailScreen extends ConsumerStatefulWidget {
  final String routeId;
  const RouteDetailScreen({super.key, required this.routeId});

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Real data from the route that was tapped. The routeId looks like
  // "1_100001" — we pass it through RoutesLookup to get the short name
  // (e.g. "271", "C Line", "H Line").
  String get _routeShortName {
    final decoded = Uri.decodeComponent(widget.routeId);
    final short = RoutesLookup.instance.shortName(decoded);
    return short.isNotEmpty ? short : decoded;
  }

  // ─── Live data from backend ────────────────────────────────────────────────
  // The route's origin/destination is looked up from the bundled GTFS routes.csv.
  String get _origin {
    final desc = RoutesLookup.instance.description(_rawRouteId);
    if (desc.contains(' - ')) return desc.split(' - ').first.trim();
    return 'Origin';
  }
  String get _destination {
    final desc = RoutesLookup.instance.description(_rawRouteId);
    if (desc.contains(' - ')) return desc.split(' - ').last.trim();
    return 'Destination';
  }

  // routeId as it came in from the Home screen (already URL-decoded).
  String get _rawRouteId => Uri.decodeComponent(widget.routeId);

  // Live vehicles on this route (refreshed every 10s).
  List<Map<String, dynamic>> _liveVehicles = [];
  bool _loadingVehicles = true;
  String? _vehiclesError;
  Timer? _refreshTimer;

  // Bus position on timeline (0.0 = Now, 1.0 = 4m)
  double _busPosition = 0.18;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: _kPrimary,
      statusBarIconBrightness: Brightness.light,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slowly animate bus position for demo
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _busPosition = (_busPosition + 0.01).clamp(0.0, 1.0);
        });
      }
    });

    // Fetch live vehicle data for this route now + every 10s.
    _fetchLiveVehicles();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _fetchLiveVehicles();
    });
  }

  Future<void> _fetchLiveVehicles() async {
    try {
      final dio = buildApiClient();
      final resp = await dio.get('/transit/vehicles');
      final all = (resp.data['vehicles'] as List<dynamic>?) ?? [];
      // The backend's routeId in /vehicles comes back without the agency prefix
      // (e.g. "100252") while we may get called with an agency-prefixed id
      // ("1_100252"). Compare on the numeric tail to match either shape.
      final targetTail = _rawRouteId.split('_').last;
      final matching = all
          .whereType<Map<String, dynamic>>()
          .where((v) => (v['routeId']?.toString() ?? '').split('_').last == targetTail)
          .toList();

      // Dedupe by vehicleId, keeping the snapshot with the latest timestamp.
      // The backend currently returns historical snapshots, not just live
      // positions, so without this we'd massively overcount active buses.
      final Map<String, Map<String, dynamic>> newestByVehicle = {};
      for (final v in matching) {
        final id = (v['vehicleId'] as String?) ?? '';
        if (id.isEmpty) continue;
        final existing = newestByVehicle[id];
        if (existing == null) {
          newestByVehicle[id] = v;
        } else {
          final tNew = DateTime.tryParse((v['timestamp'] as String?) ?? '');
          final tOld = DateTime.tryParse((existing['timestamp'] as String?) ?? '');
          if (tNew != null && (tOld == null || tNew.isAfter(tOld))) {
            newestByVehicle[id] = v;
          }
        }
      }

      // Filter to only "recent" snapshots (within the last 10 minutes) so
      // stale historical data doesn't inflate the live count.
      final now = DateTime.now().toUtc();
      final recent = newestByVehicle.values.where((v) {
        final t = DateTime.tryParse((v['timestamp'] as String?) ?? '');
        if (t == null) return false;
        return now.difference(t.toUtc()).inMinutes < 10;
      }).toList();

      if (!mounted) return;
      setState(() {
        _liveVehicles    = recent;
        _loadingVehicles = false;
        _vehiclesError   = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingVehicles = false;
        _vehiclesError = 'Could not load live data';
      });
    }
  }

  // Headline shown on the AI Prediction card. Real ETAs require a stopId
  // (which we don't have without a /transit/routes/{id}/stops endpoint), so
  // for now we show live vehicle count + occupancy, which *is* real data.
  String get _headlineText {
    if (_loadingVehicles) return 'Loading live data…';
    if (_vehiclesError != null) return _vehiclesError!;
    if (_liveVehicles.isEmpty) return 'No buses on this route right now';
    final n = _liveVehicles.length;
    return n == 1 ? '1 bus in service' : '$n buses in service';
  }

  String get _subHeadlineText {
    if (_liveVehicles.isEmpty) return '';
    final first = _liveVehicles.first;
    final occ = (first['occupancyStatus'] as String?) ?? '';
    final speed = (first['speed'] as num?)?.toDouble() ?? 0;
    final readableOcc = switch (occ) {
      'EMPTY'             => 'Empty',
      'MANY_SEATS_AVAILABLE' => 'Plenty of seats',
      'FEW_SEATS_AVAILABLE'  => 'A few seats',
      'STANDING_ROOM_ONLY'   => 'Standing room only',
      'CRUSHED_STANDING_ROOM_ONLY' => 'Very crowded',
      'FULL'              => 'Full',
      'NOT_ACCEPTING_PASSENGERS' => 'Not picking up',
      'STOPPED_AT'        => 'At a stop',
      'IN_TRANSIT_TO'     => 'In transit',
      _                   => 'Live',
    };
    if (speed > 0) {
      return '$readableOcc · Moving ${speed.toStringAsFixed(0)} mph';
    }
    return readableOcc;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _refreshTimer?.cancel();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAIPredictionCard(),
                  const SizedBox(height: 16),
                  _buildReliabilityCard(),
                  const SizedBox(height: 16),
                  _buildLiveBusPreview(),
                  const SizedBox(height: 16),
                  _buildUpcomingStops(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Blue Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: _kPrimary,
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          // Route badge + name
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _routeShortName,
                      style: const TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Route $_routeShortName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$_origin → $_destination',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Live Status Card ───────────────────────────────────────────────────────
  // Shows real data from the /transit/vehicles feed. When a stops/arrivals
  // endpoint is available, this becomes a full ETA prediction card.
  Widget _buildAIPredictionCard() {
    final hasLive = _liveVehicles.isNotEmpty;
    final isError = _vehiclesError != null;
    final Color cardBg = isError
        ? const Color(0xFFFEF2F2)
        : hasLive
            ? const Color(0xFFE8F7EC)
            : const Color(0xFFF3F4F6);
    final Color borderColor = isError
        ? Colors.red.withOpacity(0.2)
        : hasLive
            ? _kAccent.withOpacity(0.18)
            : _kBorder;
    final Color headlineColor = isError
        ? Colors.red.shade700
        : hasLive
            ? const Color(0xFF065F46)
            : _kText;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Text(hasLive ? '🛰️' : '🚌', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                hasLive ? 'Live Tracking' : 'Service Status',
                style: TextStyle(color: headlineColor, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (hasLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('LIVE',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Headline text — live vehicle count or loading/error state
          Text(
            _headlineText,
            style: TextStyle(
              color: headlineColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (_subHeadlineText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _subHeadlineText,
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 14),

          // Real info chips — data we actually have
          if (hasLive) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FactorChip(
                  emoji: '🚌',
                  label: 'Vehicle ${_liveVehicles.first['vehicleId'] ?? '—'}',
                ),
                if ((_liveVehicles.first['tripId'] as String?)?.isNotEmpty ?? false)
                  _FactorChip(
                    emoji: '🧭',
                    label: 'Trip ${_liveVehicles.first['tripId']}',
                  ),
                _FactorChip(
                  emoji: '📡',
                  label: _liveVehicles.length > 1
                      ? '${_liveVehicles.length} buses tracked'
                      : 'Updated every 10s',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── AI Reliability Card ───────────────────────────────────────────────────
  // Pulls from the ML service via /reliability/summary, then filters for the
  // specific route being viewed. Shows the reliability score, on-time rate,
  // average delay, and sample count — all real ML-computed numbers.
  Widget _buildReliabilityCard() {
    final summaryAsync = ref.watch(reliabilitySummaryProvider);

    return summaryAsync.when(
      loading: () => _buildReliabilityShell(
        isLoading: true,
        child: const SizedBox(
          height: 80,
          child: Center(
            child: SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
            ),
          ),
        ),
      ),
      error: (_, __) => _buildReliabilityShell(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'ML reliability service unavailable right now',
            style: TextStyle(color: _kSubtext, fontSize: 13),
          ),
        ),
      ),
      data: (summary) {
        // Match on the numeric tail so ids like "1_100252" and "100252" both find.
        final targetTail = _rawRouteId.split('_').last;
        final match = summary.where(
          (r) => r.routeId.split('_').last == targetTail,
        ).toList();

        if (match.isEmpty || match.first.sampleCount == 0) {
          return _buildReliabilityShell(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Not enough data yet to score this route — the ML model needs more observations.',
                style: TextStyle(color: _kSubtext, fontSize: 13),
              ),
            ),
          );
        }

        final r = match.first;
        final Color scoreColor = r.score >= 70
            ? _kAccent
            : r.score >= 50
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);

        // Format average delay — only if value is believable (<30 min).
        String delayStr;
        if (!r.hasValidDelay) {
          delayStr = '—';
        } else if (r.avgDelaySeconds.abs() < 60) {
          delayStr = '${r.avgDelaySeconds.toStringAsFixed(0)}s';
        } else {
          delayStr = '${(r.avgDelaySeconds / 60).toStringAsFixed(1)}m';
        }
        final delayIsLate = r.avgDelaySeconds > 0;

        return _buildReliabilityShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score ring + headline
              Row(
                children: [
                  _ScoreRing(score: r.score, color: scoreColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.statusLabel[0].toUpperCase() + r.statusLabel.substring(1),
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Based on ${_formatCount(r.sampleCount)} observations',
                          style: const TextStyle(
                            color: _kSubtext,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stat row
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'On-time rate',
                      value: '${r.onTimeRate.toStringAsFixed(0)}%',
                      color: _kAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatBox(
                      label: r.hasValidDelay
                          ? (delayIsLate ? 'Avg delay' : 'Avg early')
                          : 'Avg delay',
                      value: delayStr,
                      color: delayIsLate ? _kUrgentText : _kAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReliabilityShell({required Widget child, bool isLoading = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'AI Reliability',
                style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  // ── Live Bus Preview ───────────────────────────────────────────────────────
  Widget _buildLiveBusPreview() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_bus_rounded, color: _kPrimary, size: 20),
              SizedBox(width: 8),
              Text('Live Bus Preview',
                  style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline
          LayoutBuilder(builder: (context, constraints) {
            return SizedBox(
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track background
                  Positioned(
                    left: 0, right: 0,
                    top: 18,
                    child: Container(height: 4, decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(2),
                    )),
                  ),
                  // Progress fill
                  Positioned(
                    left: 0,
                    top: 18,
                    child: Container(
                      width: constraints.maxWidth * _busPosition,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Time ticks: Now, 1m, 3m, 4m
                  ..._buildTimelineTicks(constraints.maxWidth),

                  // Animated bus icon
                  AnimatedPositioned(
                    duration: const Duration(seconds: 2),
                    curve: Curves.linear,
                    left: (constraints.maxWidth * _busPosition) - 18,
                    top: 0,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _kPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)],
                        ),
                        child: const Center(child: Text('🚌', style: TextStyle(fontSize: 18))),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Approaching text — shows speed of the first live vehicle
          Row(
            children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: _kAccent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _liveVehicles.isNotEmpty
                      ? 'Live position — updated ${_relativeTime(_liveVehicles.first['timestamp'])}'
                      : 'Waiting for live data…',
                  style: const TextStyle(color: _kSubtext, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineTicks(double width) {
    final ticks = [
      (0.0, 'Now'),
      (0.33, '1m'),
      (0.66, '3m'),
      (1.0, '4m'),
    ];
    return ticks.map((t) {
      final isActive = _busPosition >= t.$1;
      return Positioned(
        left: width * t.$1 - 12,
        top: 10,
        child: Column(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: isActive ? _kPrimary : _kBorder,
                shape: BoxShape.circle,
                border: Border.all(color: isActive ? _kPrimary : _kBorder, width: 2),
              ),
            ),
            const SizedBox(height: 6),
            Text(t.$2,
                style: TextStyle(
                    color: isActive ? _kPrimary : _kSubtext,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.normal)),
          ],
        ),
      );
    }).toList();
  }

  // Converts an ISO 8601 timestamp into a short relative-time string.
  // Example: "2026-04-20T21:15:52Z" → "12s ago" or "2m ago".
  String _relativeTime(dynamic rawTimestamp) {
    if (rawTimestamp is! String) return 'just now';
    final parsed = DateTime.tryParse(rawTimestamp);
    if (parsed == null) return 'just now';
    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  // ── Upcoming Stops ─────────────────────────────────────────────────────────
  // Honest placeholder: the backend doesn't yet expose the stop sequence for a
  // route or real-time arrivals, so we show a banner instead of pretending.
  // When Wayne adds /transit/routes/{id}/stops + fixes /transit/arrivals,
  // swap this out for a real list.
  Widget _buildUpcomingStops() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.place_rounded, color: _kPrimary, size: 20),
              SizedBox(width: 8),
              Text('Upcoming Stops',
                  style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🛠', style: TextStyle(fontSize: 18)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live stop schedule coming soon',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Route stop sequence + arrival times are on our roadmap. Meanwhile, the map above shows this route\'s live bus positions.',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopRow(_StopData stop, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: stop.isNext ? _kPrimary : _kSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: stop.isNext ? _kPrimary : _kBorder,
                      width: 2,
                    ),
                  ),
                  child: stop.isNext
                      ? const Center(child: Icon(Icons.circle, size: 6, color: Colors.white))
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _kBorder,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Stop info
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.name,
                          style: TextStyle(
                            color: stop.isNext ? _kText : _kSubtext,
                            fontSize: 14,
                            fontWeight: stop.isNext ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (stop.isNext)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kPrimary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Next stop',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        if (stop.weather != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text('🌧 ${stop.weather}',
                                style: const TextStyle(color: _kSubtext, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    stop.time,
                    style: TextStyle(
                      color: stop.isNext ? _kPrimary : _kSubtext,
                      fontSize: 13,
                      fontWeight: stop.isNext ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Classes ───────────────────────────────────────────────────────

class _StopData {
  final String name;
  final String time;
  final bool isNext;
  final String? weather;
  const _StopData({required this.name, required this.time, required this.isNext, this.weather});
}

class _FactorChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _FactorChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD1FADF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Helpers for AI Reliability card ────────────────────────────────────────

/// Circular score ring — large coloured arc showing the reliability score out of 100.
class _ScoreRing extends StatelessWidget {
  final double score;
  final Color color;
  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72, height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 72, height: 72,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 7,
              color: color.withOpacity(0.15),
            ),
          ),
          // Actual score ring
          SizedBox(
            width: 72, height: 72,
            child: CircularProgressIndicator(
              value: (score.clamp(0, 100)) / 100,
              strokeWidth: 7,
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score number in the middle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '/100',
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small stat tile — label on top, value big below. Used for on-time rate / avg delay.
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kSubtext,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
