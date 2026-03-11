import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

final arrivalsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, stopId) async {
  final dio = buildApiClient();
  final resp = await dio.get('/transit/arrivals', queryParameters: {'stopId': stopId});
  return resp.data['arrivals'] as List<dynamic>;
});

class ArrivalBoard extends ConsumerWidget {
  final String stopId;
  const ArrivalBoard({super.key, required this.stopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arrivalsAsync = ref.watch(arrivalsProvider(stopId));
    return arrivalsAsync.when(
      data: (arrivals) => arrivals.isEmpty
          ? const Text('No upcoming arrivals')
          : ListView.builder(
              shrinkWrap: true,
              itemCount: arrivals.length,
              itemBuilder: (_, i) {
                final a = arrivals[i] as Map<String, dynamic>;
                return ListTile(
                  leading: Text(
                    a['routeShortName'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text(a['headsign'] as String? ?? ''),
                  trailing: Text(a['scheduledArrival'] as String? ?? ''),
                );
              },
            ),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
