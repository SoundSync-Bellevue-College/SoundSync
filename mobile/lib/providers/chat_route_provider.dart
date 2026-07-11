import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingChatRoute {
  final String originName;
  final double originLat;
  final double originLng;
  final String destName;
  final double destLat;
  final double destLng;

  const PendingChatRoute({
    required this.originName,
    required this.originLat,
    required this.originLng,
    required this.destName,
    required this.destLat,
    required this.destLng,
  });
}

final pendingChatRouteProvider =
    StateProvider<PendingChatRoute?>((ref) => null);

final activeTabProvider = StateProvider<int>((ref) => 0);
