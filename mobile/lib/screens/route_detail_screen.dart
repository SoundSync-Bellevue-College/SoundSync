import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Design Tokens (matches home_screen.dart) ─────────────────────────────────
const _kPrimary    = Color(0xFF1A56DB);
const _kAccent     = Color(0xFF16A34A);
const _kSurface    = Colors.white;
const _kBg         = Color(0xFFF8F9FB);
const _kText       = Color(0xFF111827);
const _kSubtext    = Color(0xFF6B7280);
const _kBorder     = Color(0xFFE5E7EB);
const _kUrgentText = Color(0xFFD97706);

class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  const RouteDetailScreen({super.key, required this.routeId});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Mock data — will be replaced with live API data
  final String _routeShortName = '271';
  final String _origin         = 'Bellevue College';
  final String _destination    = 'U District';
  final int _confidence        = 94;
  final int _arrivingInMinutes = 4;
  final String _expectedTime   = '3:24 PM';
  final String _scheduledTime  = '3:26 PM';

  final List<_StopData> _upcomingStops = [
    _StopData(name: 'Bellevue College',     time: '3:24 PM', isNext: true,  weather: '48°F'),
    _StopData(name: 'Eastgate P&R',         time: '3:31 PM', isNext: false, weather: '48°F'),
    _StopData(name: 'Mercer Island P&R',    time: '3:38 PM', isNext: false, weather: null),
    _StopData(name: 'Rainier Ave & S Dearborn', time: '3:44 PM', isNext: false, weather: null),
    _StopData(name: 'U District Station',   time: '3:52 PM', isNext: false, weather: null),
  ];

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  Color get _confidenceColor {
    if (_confidence >= 90) return _kAccent;
    if (_confidence >= 75) return _kUrgentText;
    return Colors.red;
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

  // ── AI Prediction Card ─────────────────────────────────────────────────────
  Widget _buildAIPredictionCard() {
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
          // Header row
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              const Text('AI Prediction',
                  style: TextStyle(color: _kSubtext, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(color: _kAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('$_confidence% Confident',
                        style: TextStyle(color: _confidenceColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Arriving in X min — big
          Text(
            'Arriving in $_arrivingInMinutes min',
            style: TextStyle(
              color: _confidenceColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Expected at $_expectedTime — ${_scheduledTime == _expectedTime ? "on time" : "2 min earlier than scheduled"}',
            style: const TextStyle(color: _kSubtext, fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Factor chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FactorChip(emoji: '🚦', label: 'Light traffic'),
              _FactorChip(emoji: '🌧', label: 'Rain +1m'),
              _FactorChip(emoji: '📊', label: '97% historical'),
            ],
          ),
        ],
      ),
    );
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

          // Approaching text
          Row(
            children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: _kAccent, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                'Bus approaching — ${(_arrivingInMinutes * (1 - _busPosition)).toStringAsFixed(1)} miles away',
                style: const TextStyle(color: _kSubtext, fontSize: 12),
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

  // ── Upcoming Stops ─────────────────────────────────────────────────────────
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
          ..._upcomingStops.asMap().entries.map((entry) {
            final i = entry.key;
            final stop = entry.value;
            return _buildStopRow(stop, isLast: i == _upcomingStops.length - 1);
          }),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: _kSubtext, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
