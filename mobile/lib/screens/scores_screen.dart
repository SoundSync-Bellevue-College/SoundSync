import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/routes_lookup.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ReliabilityEntry {
  final String routeId;
  final double score;
  final double onTimeRate;
  final double avgDelaySeconds;
  final int sampleCount;

  const ReliabilityEntry({
    required this.routeId,
    required this.score,
    required this.onTimeRate,
    required this.avgDelaySeconds,
    required this.sampleCount,
  });

  factory ReliabilityEntry.fromJson(Map<String, dynamic> j) => ReliabilityEntry(
        routeId: j['route_id'] as String? ?? '',
        score: (j['score'] as num? ?? 0).toDouble(),
        onTimeRate: (j['on_time_rate'] as num? ?? 0).toDouble(),
        avgDelaySeconds: (j['avg_delay_seconds'] as num? ?? 0).toDouble(),
        sampleCount: (j['sample_count'] as num? ?? 0).toInt(),
      );
}

class CrowdsourceEntry {
  final String routeId;
  final double avgCleanliness;
  final double avgCrowding;
  final double avgDelay;
  final int totalReports;

  const CrowdsourceEntry({
    required this.routeId,
    required this.avgCleanliness,
    required this.avgCrowding,
    required this.avgDelay,
    required this.totalReports,
  });

  factory CrowdsourceEntry.fromJson(Map<String, dynamic> j) => CrowdsourceEntry(
        routeId: j['route_id'] as String? ?? '',
        avgCleanliness: (j['avg_cleanliness'] as num? ?? 0).toDouble(),
        avgCrowding: (j['avg_crowding'] as num? ?? 0).toDouble(),
        avgDelay: (j['avg_delay'] as num? ?? 0).toDouble(),
        totalReports: (j['total_reports'] as num? ?? 0).toInt(),
      );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final _reliabilityProvider =
    FutureProvider.autoDispose<List<ReliabilityEntry>>((ref) async {
  final dio = buildApiClient();
  final resp = await dio.get('/reliability/summary');
  final list = (resp.data['data']?['routes'] as List<dynamic>?) ?? [];
  return list.map((e) => ReliabilityEntry.fromJson(e as Map<String, dynamic>)).toList();
});

final _crowdsourceProvider =
    FutureProvider.autoDispose<List<CrowdsourceEntry>>((ref) async {
  final dio = buildApiClient();
  final resp = await dio.get('/crowdsource/summary');
  final list = (resp.data['data']?['routes'] as List<dynamic>?) ?? [];
  return list
      .map((e) => CrowdsourceEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class ScoresScreen extends ConsumerStatefulWidget {
  const ScoresScreen({super.key});

  @override
  ConsumerState<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends ConsumerState<ScoresScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _routeLabel(String routeId) {
    if (routeId.isEmpty) return routeId;
    final stripped = routeId.contains('_')
        ? routeId.substring(routeId.indexOf('_') + 1)
        : routeId;
    final name = RoutesLookup.instance.shortName(stripped);
    return name.isNotEmpty ? name : RoutesLookup.instance.shortName(routeId);
  }

  bool _matches(String routeId) {
    if (_query.isEmpty) return true;
    return _routeLabel(routeId).toLowerCase().contains(_query) ||
        routeId.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Route Scores',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Reliability & crowd-sourced ratings',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  // Search
                  SizedBox(
                    width: 140,
                    height: 36,
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search route…',
                        hintStyle:
                            const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white38, size: 16),
                        filled: true,
                        fillColor: const Color(0xFF122340),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.white12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF7FDBFF), width: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.white12, width: 1)),
              ),
              child: TabBar(
                controller: _tab,
                indicatorColor: const Color(0xFF7FDBFF),
                indicatorWeight: 2,
                labelColor: const Color(0xFF7FDBFF),
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Reliability'),
                  Tab(text: 'Crowd Source'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _ReliabilityTab(
                      query: _query, routeLabel: _routeLabel, matches: _matches),
                  _CrowdsourceTab(
                      query: _query, routeLabel: _routeLabel, matches: _matches),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reliability Tab ──────────────────────────────────────────────────────────

class _ReliabilityTab extends ConsumerWidget {
  final String query;
  final String Function(String) routeLabel;
  final bool Function(String) matches;

  const _ReliabilityTab(
      {required this.query,
      required this.routeLabel,
      required this.matches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_reliabilityProvider);
    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7FDBFF))),
      error: (e, _) => _ErrorState(
          message: 'Could not load scores',
          onRetry: () => ref.invalidate(_reliabilityProvider)),
      data: (routes) {
        if (routes.isEmpty) {
          return const _EmptyState(
              message: 'No reliability data yet.',
              sub: 'Data is collected as the transit poller records arrivals.');
        }
        final filtered = routes.where((r) => matches(r.routeId)).toList();
        final avg = routes.isEmpty
            ? '—'
            : (routes.fold(0.0, (s, r) => s + r.score) / routes.length)
                .toStringAsFixed(1);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Summary cards
            Row(
              children: [
                _SummaryCard(value: '${routes.length}', label: 'Routes'),
                const SizedBox(width: 10),
                _SummaryCard(
                    value: avg,
                    label: 'Avg score',
                    color: _scoreColor(double.tryParse(avg) ?? 0)),
                const SizedBox(width: 10),
                _SummaryCard(
                    value: routeLabel(routes.first.routeId),
                    label: 'Best route',
                    color: Colors.greenAccent),
                const SizedBox(width: 10),
                _SummaryCard(
                    value: routeLabel(routes.last.routeId),
                    label: 'Lowest',
                    color: Colors.redAccent),
              ],
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No routes match "$query"',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13)),
                ),
              )
            else
              for (var i = 0; i < filtered.length; i++)
                _ReliabilityRow(
                    rank: i + 1,
                    entry: filtered[i],
                    label: routeLabel(filtered[i].routeId)),
          ],
        );
      },
    );
  }
}

class _ReliabilityRow extends StatelessWidget {
  final int rank;
  final ReliabilityEntry entry;
  final String label;

  const _ReliabilityRow(
      {required this.rank, required this.entry, required this.label});

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(entry.score);
    final delayColor = entry.avgDelaySeconds > 60
        ? Colors.redAccent
        : entry.avgDelaySeconds < -30
            ? Colors.amberAccent
            : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF122340),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text('$rank',
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          // Route badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          // Score bar + score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.score.toStringAsFixed(1),
                        style: TextStyle(
                            color: scoreColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${entry.onTimeRate.toStringAsFixed(1)}% on-time',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.score / 100,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Delay
          Text(_formatDelay(entry.avgDelaySeconds),
              style: TextStyle(color: delayColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Crowd Source Tab ─────────────────────────────────────────────────────────

class _CrowdsourceTab extends ConsumerWidget {
  final String query;
  final String Function(String) routeLabel;
  final bool Function(String) matches;

  const _CrowdsourceTab(
      {required this.query,
      required this.routeLabel,
      required this.matches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_crowdsourceProvider);
    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7FDBFF))),
      error: (e, _) => _ErrorState(
          message: 'Could not load crowd data',
          onRetry: () => ref.invalidate(_crowdsourceProvider)),
      data: (routes) {
        if (routes.isEmpty) {
          return const _EmptyState(
              message: 'No crowd-sourced reports yet.',
              sub: 'Submit ratings via the map when you board a vehicle.');
        }
        final filtered = routes.where((r) => matches(r.routeId)).toList();
        final totalReports = routes.fold(0, (s, r) => s + r.totalReports);
        final validClean = routes.where((r) => r.avgCleanliness > 0).toList();
        final avgClean = validClean.isEmpty
            ? '—'
            : (validClean.fold(0.0, (s, r) => s + r.avgCleanliness) /
                    validClean.length)
                .toStringAsFixed(1);
        final validCrowd =
            routes.where((r) => r.avgCrowding > 0).toList();
        final avgCrowd = validCrowd.isEmpty
            ? '—'
            : (validCrowd.fold(0.0, (s, r) => s + r.avgCrowding) /
                    validCrowd.length)
                .toStringAsFixed(1);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                _SummaryCard(value: '${routes.length}', label: 'Routes rated'),
                const SizedBox(width: 10),
                _SummaryCard(
                    value: '$totalReports', label: 'Total reports'),
                const SizedBox(width: 10),
                _SummaryCard(
                    value: avgClean,
                    label: 'Avg clean',
                    color: _starColor(double.tryParse(avgClean) ?? 0)),
                const SizedBox(width: 10),
                _SummaryCard(
                    value: avgCrowd,
                    label: 'Avg crowd',
                    color: _crowdColor(double.tryParse(avgCrowd) ?? 0)),
              ],
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No routes match "$query"',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13)),
                ),
              )
            else
              for (var i = 0; i < filtered.length; i++)
                _CrowdsourceRow(
                    rank: i + 1,
                    entry: filtered[i],
                    label: routeLabel(filtered[i].routeId)),
          ],
        );
      },
    );
  }
}

class _CrowdsourceRow extends StatelessWidget {
  final int rank;
  final CrowdsourceEntry entry;
  final String label;

  const _CrowdsourceRow(
      {required this.rank, required this.entry, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF122340),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$rank',
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CsChip(
                    emoji: '🧹',
                    value: entry.avgCleanliness,
                    color: _starColor(entry.avgCleanliness)),
                _CsChip(
                    emoji: '👥',
                    value: entry.avgCrowding,
                    color: _crowdColor(entry.avgCrowding)),
                _CsChip(
                    emoji: '⏱',
                    value: entry.avgDelay,
                    color: _delayLvlColor(entry.avgDelay)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${entry.totalReports}',
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CsChip extends StatelessWidget {
  final String emoji;
  final double value;
  final Color color;

  const _CsChip(
      {required this.emoji, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    if (value <= 0) {
      return const Text('—', style: TextStyle(color: Colors.white24, fontSize: 12));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(value.toStringAsFixed(1),
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _SummaryCard(
      {required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF122340),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    letterSpacing: 0.5),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String sub;

  const _EmptyState({required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart_outlined,
                color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(sub,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white24, size: 40),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(color: Color(0xFF7FDBFF))),
          ),
        ],
      ),
    );
  }
}

// ─── Color helpers ────────────────────────────────────────────────────────────

Color _scoreColor(double score) {
  if (score >= 75) return Colors.greenAccent;
  if (score >= 50) return Colors.amberAccent;
  return Colors.redAccent;
}

Color _starColor(double val) {
  if (val >= 4) return Colors.greenAccent;
  if (val >= 3) return Colors.amberAccent;
  return Colors.redAccent;
}

Color _crowdColor(double val) {
  if (val <= 2) return Colors.greenAccent;
  if (val <= 3.5) return Colors.amberAccent;
  return Colors.redAccent;
}

Color _delayLvlColor(double val) {
  if (val <= 2) return Colors.greenAccent;
  if (val <= 3.5) return Colors.amberAccent;
  return Colors.redAccent;
}

String _formatDelay(double sec) {
  if (sec.abs() < 60) return '${sec.round()}s';
  final m = (sec / 60).toStringAsFixed(1);
  return sec >= 0 ? '+${m}m' : '${m}m';
}
