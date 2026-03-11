import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/location_provider.dart';
import '../services/api_client.dart';

// Seattle fallback coords
const _defaultLat = 47.6062;
const _defaultLng = -122.3321;

// Current weather at the given lat/lng
final _currentWeatherProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, (double, double)>((ref, coords) async {
  final dio = buildApiClient();
  final resp = await dio.get(
    '/weather',
    queryParameters: {'lat': coords.$1, 'lng': coords.$2},
  );
  return resp.data as Map<String, dynamic>;
});

// 12-hour forecast at the given lat/lng
final _hourlyWeatherProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, (double, double)>((ref, coords) async {
  final dio = buildApiClient();
  final resp = await dio.get(
    '/weather/hourly',
    queryParameters: {'lat': coords.$1, 'lng': coords.$2},
  );
  return resp.data as Map<String, dynamic>;
});

class WeatherChip extends ConsumerWidget {
  const WeatherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);
    final position = locationAsync.valueOrNull;
    final coords = position != null
        ? (position.latitude, position.longitude)
        : (_defaultLat, _defaultLng);

    final weatherAsync = ref.watch(_currentWeatherProvider(coords));

    return weatherAsync.when(
      data: (w) {
        final temp = (w['temp'] as num?)?.round() ?? '--';
        final emoji = _weatherEmoji(w['description'] as String? ?? '');
        return Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(24),
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showHourlySheet(context, ref, coords),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xE6122340),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    '$temp°F',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showHourlySheet(
      BuildContext context, WidgetRef ref, (double, double) coords) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: _HourlySheet(coords: coords),
      ),
    );
  }

  static String _weatherEmoji(String forecast) {
    final f = forecast.toLowerCase();
    if (f.contains('thunder')) return '⛈️';
    if (f.contains('snow') || f.contains('blizzard')) return '🌨️';
    if (f.contains('rain') || f.contains('shower') || f.contains('drizzle')) return '🌧️';
    if (f.contains('fog') || f.contains('haze') || f.contains('mist')) return '🌫️';
    if (f.contains('wind')) return '💨';
    if (f.contains('partly cloudy') || f.contains('partly sunny')) return '⛅';
    if (f.contains('mostly cloudy') || f.contains('overcast')) return '☁️';
    if (f.contains('cloudy')) return '🌥️';
    if (f.contains('sunny') || f.contains('clear')) return '☀️';
    return '🌤️';
  }
}

class _HourlySheet extends ConsumerWidget {
  const _HourlySheet({required this.coords});
  final (double, double) coords;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourlyAsync = ref.watch(_hourlyWeatherProvider(coords));

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          hourlyAsync.when(
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Expanded(
              child: Center(
                child: Text('Could not load forecast',
                    style: TextStyle(color: Colors.white54)),
              ),
            ),
            data: (data) {
              final city = data['cityName'] as String? ?? 'Your Location';
              final periods = (data['periods'] as List<dynamic>)
                  .cast<Map<String, dynamic>>();

              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          const Text('📍', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '$city — Hourly Forecast',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: periods.length,
                        itemBuilder: (_, i) => _HourlyRow(period: periods[i]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HourlyRow extends StatelessWidget {
  const _HourlyRow({required this.period});
  final Map<String, dynamic> period;

  @override
  Widget build(BuildContext context) {
    final startTime = period['startTime'] as String? ?? '';
    final temp = (period['temperature'] as num?)?.round() ?? '--';
    final wind = period['windSpeed'] as String? ?? '';
    final windDir = period['windDirection'] as String? ?? '';
    final forecast = period['shortForecast'] as String? ?? '';
    final emoji = WeatherChip._weatherEmoji(forecast);
    final timeLabel = _formatHour(startTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 56,
            child: Text(
              timeLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          // Emoji
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          // Temp
          SizedBox(
            width: 48,
            child: Text(
              '$temp°F',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          // Wind
          Expanded(
            child: Text(
              '$wind $windDir',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          // Forecast
          Flexible(
            flex: 2,
            child: Text(
              forecast,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF7FDBFF), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour;
      final suffix = h >= 12 ? 'PM' : 'AM';
      final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$hour $suffix';
    } catch (_) {
      return iso;
    }
  }
}
