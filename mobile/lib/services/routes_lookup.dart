import 'package:flutter/services.dart';

/// Maps route_id → route_short_name from the bundled Sound Transit GTFS routes.csv.
class RoutesLookup {
  RoutesLookup._();

  static final RoutesLookup instance = RoutesLookup._();

  // route_id → route_short_name
  final Map<String, String> _map = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/routes.csv');
    final lines = raw.split('\n');
    if (lines.isEmpty) return;

    // Parse header to find column indices
    final headers = _parseCsvLine(lines[0]);
    final idIdx = headers.indexOf('route_id');
    final shortIdx = headers.indexOf('route_short_name');
    if (idIdx == -1 || shortIdx == -1) return;

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final cols = _parseCsvLine(line);
      if (cols.length <= shortIdx) continue;
      final id = cols[idIdx].trim();
      final short = cols[shortIdx].trim();
      if (id.isNotEmpty && short.isNotEmpty) _map[id] = short;
    }
    _loaded = true;
  }

  /// Returns the short name for [routeId], falling back to [routeId] itself.
  String shortName(String routeId) => _map[routeId] ?? routeId;

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }
}
