import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/routes_lookup.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _myReportsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = buildApiClient();
  final resp = await dio.get('/users/me/vehicle-reports');
  final list = (resp.data['reports'] as List<dynamic>?) ?? [];
  return list.cast<Map<String, dynamic>>();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    final initials = auth.displayName.isNotEmpty
        ? auth.displayName
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/'),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white54, size: 20),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'My Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Avatar + name (always visible) ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFF0F4C81),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF7FDBFF),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(auth.displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(auth.email,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),

              // ── Tab bar ───────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF122340),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: const Color(0xFF7FDBFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: const Color(0xFF0D1B2A),
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'My Reports'),
                  ],
                ),
              ),

              // ── Tab content ───────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  children: [
                    _ProfileTab(auth: auth),
                    const _ReportsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends ConsumerWidget {
  final AuthState auth;
  const _ProfileTab({required this.auth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tempUnit = auth.user?['tempUnit'] as String? ?? 'F';
    final distUnit = auth.user?['distanceUnit'] as String? ?? 'mi';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── Preferences ─────────────────────────────────────────────
        const _SectionHeader(title: 'Preferences'),
        const SizedBox(height: 10),
        _PrefsCard(children: [
          _PrefRow(
            icon: Icons.thermostat_outlined,
            label: 'Temperature',
            child: _SegmentToggle(
              options: const ['°F', '°C'],
              selected: tempUnit == 'F' ? '°F' : '°C',
              onChanged: (v) => ref
                  .read(authProvider.notifier)
                  .updateSettings(tempUnit: v == '°F' ? 'F' : 'C'),
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          _PrefRow(
            icon: Icons.straighten_outlined,
            label: 'Distance',
            child: _SegmentToggle(
              options: const ['mi', 'km'],
              selected: distUnit,
              onChanged: (v) => ref
                  .read(authProvider.notifier)
                  .updateSettings(distanceUnit: v),
            ),
          ),
        ]),
        const SizedBox(height: 24),

        // ── Account actions ──────────────────────────────────────────
        const _SectionHeader(title: 'Account'),
        const SizedBox(height: 10),
        _PrefsCard(children: [
          _ActionRow(
            icon: Icons.logout,
            label: 'Sign Out',
            color: Colors.white70,
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
          ),
          const Divider(height: 1, color: Colors.white10),
          _ActionRow(
            icon: Icons.delete_outline,
            label: 'Delete Account',
            color: Colors.redAccent,
            onTap: () => _confirmDelete(context, ref),
          ),
        ]),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF122340),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete account?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your account will be deactivated. This cannot be undone.',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(authProvider.notifier).deleteAccount();
                if (context.mounted) context.go('/');
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Failed to delete account. Try again.')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Reports Tab ──────────────────────────────────────────────────────────────

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(_myReportsProvider);

    return reportsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF7FDBFF))),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white24, size: 40),
            const SizedBox(height: 12),
            const Text('Could not load reports',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.invalidate(_myReportsProvider),
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFF7FDBFF))),
            ),
          ],
        ),
      ),
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_outlined, color: Colors.white24, size: 40),
                SizedBox(height: 12),
                Text('No reports yet',
                    style: TextStyle(color: Colors.white54, fontSize: 15)),
                SizedBox(height: 6),
                Text('Tap a bus on the map and use the Report button.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _ReportCard(
            report: reports[i],
            onDelete: () async {
              final type = reports[i]['type'] as String;
              final id = reports[i]['id'] as String;
              try {
                final dio = buildApiClient();
                await dio.delete('/users/me/vehicle-reports/$type/$id');
                ref.invalidate(_myReportsProvider);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Could not delete report.')),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}

// ─── Report Card ──────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onDelete;
  const _ReportCard({required this.report, required this.onDelete});

  static const _meta = {
    'cleanliness': (emoji: '🧹', label: 'Cleanliness', lo: 'Very dirty', hi: 'Very clean'),
    'crowding':    (emoji: '👥', label: 'Crowding',    lo: 'Empty',      hi: 'Packed'),
    'delay':       (emoji: '⏱',  label: 'Delay',       lo: 'On time',    hi: 'Very late'),
  };

  static const _levelLabels = {
    'cleanliness': ['Very dirty', 'Dirty', 'Okay', 'Clean', 'Very clean'],
    'crowding':    ['Empty', 'Light', 'Moderate', 'Busy', 'Packed'],
    'delay':       ['On time', 'Slight', 'Moderate', 'Late', 'Very late'],
  };

  @override
  Widget build(BuildContext context) {
    final type      = report['type'] as String? ?? '';
    final vehicleId = report['vehicleId'] as String? ?? '—';
    final routeId   = report['routeId'] as String? ?? '—';
    final level     = (report['level'] as num?)?.toInt() ?? 0;
    final createdAt = report['createdAt'] as String? ?? '';
    final meta      = _meta[type];
    final levelLabel =
        (level >= 1 && level <= 5) ? (_levelLabels[type]?[level - 1] ?? '') : '';
    final timeLabel = _formatTime(createdAt);

    return Dismissible(
      key: Key(report['id'] as String? ?? type + vehicleId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async => await _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF122340),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon circle
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF0F4C81),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(meta?.emoji ?? '📋',
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type label + level badge
                  Row(
                    children: [
                      Text(
                        meta?.label ?? type,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      _LevelBadge(level: level, label: levelLabel),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Route + vehicle
                  Row(
                    children: [
                      const Icon(Icons.directions_bus_outlined,
                          color: Colors.white38, size: 13),
                      const SizedBox(width: 4),
                      Text('Route ${RoutesLookup.instance.shortName(routeId)}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 10),
                      const Icon(Icons.tag, color: Colors.white38, size: 13),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          vehicleId,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Timestamp
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.white24, size: 12),
                      const SizedBox(width: 4),
                      Text(timeLabel,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            GestureDetector(
              onTap: () async {
                if (await _confirmDelete(context)) onDelete();
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.delete_outline,
                    color: Colors.white24, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF122340),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete report?',
            style: TextStyle(color: Colors.white)),
        content: const Text('This report will be permanently removed.',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final String label;
  const _LevelBadge({required this.level, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = level <= 2
        ? const Color(0xFF4CAF50)
        : level == 3
            ? const Color(0xFFFFC107)
            : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                i < level ? Icons.circle : Icons.circle_outlined,
                size: 7,
                color: i < level ? color : color.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      );
}

class _PrefsCard extends StatelessWidget {
  final List<Widget> children;
  const _PrefsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF122340),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(children: children),
      );
}

class _PrefRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _PrefRow(
      {required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 15)),
            const Spacer(),
            child,
          ],
        ),
      );
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionRow(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Icon(Icons.chevron_right,
                  color: color.withOpacity(0.4), size: 20),
            ],
          ),
        ),
      );
}

class _SegmentToggle extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _SegmentToggle(
      {required this.options,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final active = opt == selected;
            return GestureDetector(
              onTap: active ? null : () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF7FDBFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF0D1B2A)
                        : Colors.white54,
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}
