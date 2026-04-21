import 'package:flutter/services.dart';

/// Maps route_id → route short name + description from the bundled GTFS routes.csv.
class RoutesLookup {
  RoutesLookup._();

  static final RoutesLookup instance = RoutesLookup._();

  // route_id → route_short_name
  final Map<String, String> _shortNameMap = {};
  // route_id → route_desc (e.g. "Kinnear - Downtown Seattle")
  final Map<String, String> _descriptionMap = {};
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
    final descIdx = headers.indexOf('route_desc');
    if (idIdx == -1 || shortIdx == -1) return;

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final cols = _parseCsvLine(line);
      if (cols.length <= shortIdx) continue;
      final id = cols[idIdx].trim();
      final short = cols[shortIdx].trim();
      if (id.isNotEmpty && short.isNotEmpty) _shortNameMap[id] = short;
      if (descIdx != -1 && cols.length > descIdx) {
        final desc = cols[descIdx].trim();
        if (id.isNotEmpty && desc.isNotEmpty) _descriptionMap[id] = desc;
      }
    }
    _loaded = true;
  }

  /// Returns the short name for [routeId], falling back to [routeId] itself.
  String shortName(String routeId) => _shortNameMap[routeId] ?? routeId;

  /// Returns a human description like "Kinnear - Downtown Seattle", or empty string.
  String description(String routeId) => _descriptionMap[routeId] ?? '';

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
