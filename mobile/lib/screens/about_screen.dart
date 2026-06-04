import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class _TeamMember {
  final String name;
  final String pronouns;
  final String role;
  final String photoUrl;
  final String quote;
  final String linkedin;
  final String github;

  const _TeamMember({
    required this.name,
    required this.pronouns,
    required this.role,
    required this.photoUrl,
    required this.quote,
    required this.linkedin,
    required this.github,
  });

  factory _TeamMember.fromJson(Map<String, dynamic> j) => _TeamMember(
        name: j['name'] as String? ?? '',
        pronouns: j['pronouns'] as String? ?? '',
        role: j['role'] as String? ?? '',
        photoUrl: j['photo_url'] as String? ?? '',
        quote: j['quote'] as String? ?? '',
        linkedin: j['linkedin'] as String? ?? '',
        github: j['github'] as String? ?? '',
      );
}

// ─── Provider ────────────────────────────────────────────────────────────────

final _teamProvider = FutureProvider.autoDispose<List<_TeamMember>>((ref) async {
  final dio = buildApiClient();
  final res = await dio.get('/team');
  final data = res.data as Map<String, dynamic>;
  final list = data['data'] as List<dynamic>;
  return list.map((e) => _TeamMember.fromJson(e as Map<String, dynamic>)).toList();
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const _mission = [
    (
      icon: '🚌',
      title: 'Real-Time Awareness',
      body:
          'Live vehicle positions, arrival predictions, and delay tracking across King County Metro and Sound Transit routes.',
    ),
    (
      icon: '📊',
      title: 'Reliability Insights',
      body:
          'Historical on-time data and time-of-day breakdowns so riders know when their bus actually shows up.',
    ),
    (
      icon: '🤝',
      title: 'Community Reporting',
      body:
          'Crowdsourced cleanliness, crowding, and delay reports that keep fellow riders informed in real time.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(_teamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7FDBFF).withOpacity(0.1),
                  border: Border.all(
                      color: const Color(0xFF7FDBFF).withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Bellevue College · Senior Capstone Project',
                  style: TextStyle(
                    color: Color(0xFF7FDBFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Improving Public Transit\nin King County',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'SoundSyncAI is a student-built platform created by four Bellevue College students passionate about making public transportation more accessible, transparent, and data-driven for everyone in the King County area.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.65),
              ),
              const SizedBox(height: 32),

              // Mission cards
              for (final m in _mission) ...[
                _MissionCard(icon: m.icon, title: m.title, body: m.body),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 32),

              // Team section
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Meet the Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              teamAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(
                    color: Color(0xFF7FDBFF),
                    strokeWidth: 2,
                  ),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white24, size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load team data',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(_teamProvider),
                        child: const Text('Retry',
                            style: TextStyle(color: Color(0xFF7FDBFF))),
                      ),
                    ],
                  ),
                ),
                data: (members) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.52,
                  children: [
                    for (final m in members)
                      _MemberCard(
                        name: m.name,
                        pronouns: m.pronouns,
                        role: m.role,
                        photoUrl: m.photoUrl,
                        quote: m.quote,
                        linkedin: m.linkedin,
                        github: m.github,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              const Text(
                'Built with ❤️ at Bellevue College · King County, WA',
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mission Card ─────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String body;

  const _MissionCard(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF122340),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Member Card ──────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final String name;
  final String pronouns;
  final String role;
  final String photoUrl;
  final String quote;
  final String linkedin;
  final String github;

  const _MemberCard({
    required this.name,
    required this.pronouns,
    required this.role,
    required this.photoUrl,
    required this.quote,
    required this.linkedin,
    required this.github,
  });

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF122340),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          AspectRatio(
            aspectRatio: 1,
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => const _PhotoFallback(),
                  )
                : const _PhotoFallback(),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(pronouns,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: const TextStyle(
                      color: Color(0xFF7FDBFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      '"$quote"',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (linkedin.isNotEmpty)
                        _SocialBtn(label: 'in', onTap: () => _launch(linkedin)),
                      if (github.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _SocialBtn(label: 'gh', onTap: () => _launch(github)),
                      ],
                    ],
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

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFF0F4C81),
        child: Center(
          child: Icon(Icons.person, color: Colors.white38, size: 40),
        ),
      );
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SocialBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
