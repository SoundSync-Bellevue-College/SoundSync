import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../providers/transit_provider.dart';
import '../providers/location_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_route_provider.dart';
import '../services/api_client.dart';
import '../services/geocoding_service.dart';
import '../services/route_planning_service.dart';
import '../services/routes_lookup.dart';
import '../widgets/transit_route_sheet.dart';
import '../widgets/weather_chip.dart';
import '../widgets/vehicle_marker.dart';

// ─── Favorites provider ───────────────────────────────────────────────────────

class _FavoritePlace {
  final String id;
  final String label;
  final String destName;
  final double destLat;
  final double destLng;

  const _FavoritePlace({
    required this.id,
    required this.label,
    required this.destName,
    required this.destLat,
    required this.destLng,
  });
}

final _favoritesProvider = FutureProvider.autoDispose<List<_FavoritePlace>>((ref) async {
  final dio = buildApiClient();
  final res = await dio.get('/users/me/favorites');
  final list = (res.data['favorites'] as List<dynamic>?) ?? [];
  return list.map((e) {
    final dest = e['destination'] as Map<String, dynamic>;
    return _FavoritePlace(
      id: (e['_id'] as String?) ?? '',
      label: (e['label'] as String?) ?? '',
      destName: (dest['name'] as String?) ?? '',
      destLat: (dest['lat'] as num).toDouble(),
      destLng: (dest['lng'] as num).toDouble(),
    );
  }).toList();
});

/// Returns a color for a transit polyline based on vehicle type.
Color _transitColor(String? vehicleType) {
  switch (vehicleType) {
    case 'BUS':
      return const Color(0xFFFF9800); // orange
    case 'SUBWAY':
    case 'HEAVY_RAIL':
      return const Color(0xFF4CAF50); // green
    case 'COMMUTER_TRAIN':
    case 'RAIL':
      return const Color(0xFF2196F3); // blue
    case 'TRAM':
    case 'LIGHT_RAIL':
      return const Color(0xFF00BCD4); // teal
    case 'FERRY':
      return const Color(0xFF3F51B5); // indigo
    default:
      return const Color(0xFF7FDBFF); // cyan fallback
  }
}

/// Decodes a Google Maps encoded polyline string into a list of [LatLng].
List<LatLng> _decodePolyline(String encoded) {
  final result = <LatLng>[];
  int index = 0;
  int lat = 0, lng = 0;
  while (index < encoded.length) {
    int b, shift = 0, result0 = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result0 |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
    lat += dlat;

    shift = 0;
    result0 = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result0 |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
    lng += dlng;

    result.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return result;
}

const _seattle = LatLng(47.6062, -122.3321);

enum _BusMode { showAll, hideAll, routeOnly, custom }

const _mapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#0d1b2a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0d1b2a"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#1f3a5f"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0d1b2a"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#0a2e1a"},{"visibility":"on"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a3a5c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#6c9ab5"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1e4976"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#0f5ca8"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#0a3d6e"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#102a42"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#1a3a5c"}]},
  {"featureType":"transit.line","elementType":"geometry.fill","stylers":[{"color":"#1e5799"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#0f3d6e"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#00c8ff"}]},
  {"featureType":"transit.station.bus","elementType":"labels.icon","stylers":[{"visibility":"on"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#040d17"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#1e5f8a"}]}
]''';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Marker> _stopMarkers = {};
  BitmapDescriptor? _stopIcon;
  final Map<String, BitmapDescriptor> _iconCache = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<PlaceSuggestion> _suggestions = [];
  bool _loadingSuggestions = false;
  Map<String, dynamic>? _tappedVehicle; // {vehicleId, shortName, routeId}
  Marker? _destinationMarker;
  Timer? _debounce;
  String? _destName;
  double? _destLat;
  double? _destLng;
  TransitRoute? _activeRoute;

  // Origin (custom / searchable)
  final TextEditingController _originCtrl = TextEditingController();
  final FocusNode _originFocus = FocusNode();
  List<PlaceSuggestion> _originSuggestions = [];
  bool _loadingOriginSuggestions = false;
  Timer? _originDebounce;
  double? _originLat;
  double? _originLng;
  bool _originFieldActive = false;
  bool _searchOverlayVisible = false;
  Set<String> _activeRouteShortNames = {};
  List<Map<String, dynamic>> _lastVehicles = [];
  MapType _mapType = MapType.normal;
  _BusMode _busMode = _BusMode.showAll;
  String _customRoute = '';

  @override
  void initState() {
    super.initState();
    RoutesLookup.instance.load();
    _originFocus.addListener(() {
      if (mounted) setState(() => _originFieldActive = _originFocus.hasFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(pendingChatRouteProvider, (_, route) {
        if (route == null || !mounted) return;
        _originCtrl.text = route.originName;
        _originLat = route.originLat;
        _originLng = route.originLng;
        _showRouteSheet(route.destName, route.destLat, route.destLng);
        ref.read(pendingChatRouteProvider.notifier).state = null;
      });
    });
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _originDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _originCtrl.dispose();
    _originFocus.dispose();
    super.dispose();
  }

  void _onOriginChanged(String value) {
    _originDebounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _originSuggestions = [];
        _loadingOriginSuggestions = false;
        _originLat = null;
        _originLng = null;
      });
      return;
    }
    setState(() => _loadingOriginSuggestions = true);
    _originDebounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await GeocodingService.autocomplete(value);
      if (mounted) {
        setState(() {
          _originSuggestions = results;
          _loadingOriginSuggestions = false;
        });
      }
    });
  }

  Future<void> _selectOriginSuggestion(PlaceSuggestion s) async {
    _originCtrl.text = s.mainText;
    _originFocus.unfocus();
    setState(() {
      _originSuggestions = [];
      _loadingOriginSuggestions = true;
      _searchOverlayVisible = false;
    });
    final result = await GeocodingService.placeDetails(s.placeId);
    if (!mounted) return;
    setState(() {
      _loadingOriginSuggestions = false;
      if (result != null) {
        _originLat = result.lat;
        _originLng = result.lng;
      }
    });

    // If a destination is already set, refresh the route with the new origin
    if (result != null && _destLat != null && _destLng != null && _destName != null) {
      _showRouteSheet(_destName!, _destLat!, _destLng!);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];

        _loadingSuggestions = false;
      });
      return;
    }
    setState(() => _loadingSuggestions = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await GeocodingService.autocomplete(value);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _loadingSuggestions = false;
        });
      }
    });
  }

  void _selectFavorite(_FavoritePlace fav) {
    _searchCtrl.text = fav.label;
    _searchFocus.unfocus();
    setState(() {
      _suggestions = [];
      _searchOverlayVisible = false;
      _destName = fav.destName.isNotEmpty ? fav.destName : fav.label;
      _destLat = fav.destLat;
      _destLng = fav.destLng;
    });
    final dest = LatLng(fav.destLat, fav.destLng);
    setState(() => _destinationMarker = Marker(
          markerId: const MarkerId('__destination__'),
          position: dest,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: _destName),
          onTap: () => _showRouteSheet(_destName!, _destLat!, _destLng!),
        ));
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(dest, 14));
    _showRouteSheet(_destName!, fav.destLat, fav.destLng);
  }

  Future<void> _selectSuggestion(PlaceSuggestion s) async {
    _searchCtrl.text = s.mainText;
    _searchFocus.unfocus();
    setState(() {
      _suggestions = [];
      _loadingSuggestions = true;
      _searchOverlayVisible = false;
    });

    final result = await GeocodingService.placeDetails(s.placeId);
    setState(() => _loadingSuggestions = false);
    if (result == null) return;

    final dest = LatLng(result.lat, result.lng);

    // Save for pin-tap reuse
    _destName = s.mainText;
    _destLat = result.lat;
    _destLng = result.lng;

    setState(() => _destinationMarker = Marker(
          markerId: const MarkerId('__destination__'),
          position: dest,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: result.formattedAddress),
          onTap: () => _showRouteSheet(_destName!, _destLat!, _destLng!),
        ));
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(dest, 14));

    // Plan transit routes and show bottom sheet
    _showRouteSheet(s.mainText, result.lat, result.lng);
  }

  Future<void> _showRouteSheet(
      String destName, double destLat, double destLng) async {
    final position = ref.read(locationProvider).valueOrNull;
    final originLat = _originLat ?? position?.latitude ?? 47.6062;
    final originLng = _originLng ?? position?.longitude ?? -122.3321;

    // Show loading sheet immediately
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoadingRouteSheet(destName: destName),
    );

    try {
      final routes = await RoutePlanningService.plan(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => TransitRouteSheet(
          destinationName: destName,
          routes: routes,
          onRouteSelected: _onRouteSelected,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load transit routes')),
      );
    }
  }

  Future<void> _onRouteSelected(TransitRoute route) async {
    final shortNames = route.mergedSteps
        .where((s) => s.travelMode == 'TRANSIT' && s.lineShortName != null)
        .map((s) => s.lineShortName!)
        .toSet();

    // Build stop icon once
    _stopIcon ??= await buildStopIcon();

    final newPolylines = <Polyline>{};
    final newStopMarkers = <Marker>{};
    final steps = route.mergedSteps;

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final points = step.stepPolylines.expand(_decodePolyline).toList();

      if (step.travelMode == 'WALKING') {
        if (points.isNotEmpty) {
          newPolylines.add(Polyline(
            polylineId: PolylineId('walk_$i'),
            points: points,
            color: Colors.white60,
            width: 4,
            patterns: [PatternItem.dash(14), PatternItem.gap(8)],
          ));
        }
      } else {
        if (points.isNotEmpty) {
          newPolylines.add(Polyline(
            polylineId: PolylineId('transit_$i'),
            points: points,
            color: _transitColor(step.vehicleType),
            width: 5,
          ));
        }

        // Departure stop marker
        if (step.departureLat != null && step.departureLng != null) {
          newStopMarkers.add(Marker(
            markerId: MarkerId('dep_$i'),
            position: LatLng(step.departureLat!, step.departureLng!),
            icon: _stopIcon!,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: step.departureStop ?? 'Stop',
              snippet: '${step.lineShortName ?? step.lineName ?? ''}'
                  '${step.stepDepartureTime != null ? ' · Departs ${step.stepDepartureTime}' : ''}',
            ),
          ));
        }

        // Arrival stop marker
        if (step.arrivalLat != null && step.arrivalLng != null) {
          newStopMarkers.add(Marker(
            markerId: MarkerId('arr_$i'),
            position: LatLng(step.arrivalLat!, step.arrivalLng!),
            icon: _stopIcon!,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: step.arrivalStop ?? 'Stop',
              snippet: '${step.lineShortName ?? step.lineName ?? ''}'
                  '${step.stepArrivalTime != null ? ' · Arrives ${step.stepArrivalTime}' : ''}',
            ),
          ));
        }
      }
    }

    // Fit map to all drawn points
    final allPoints = newPolylines.expand((p) => p.points).toList();
    if (allPoints.length > 1) {
      double minLat = allPoints.first.latitude,
          maxLat = allPoints.first.latitude,
          minLng = allPoints.first.longitude,
          maxLng = allPoints.first.longitude;
      for (final p in allPoints) {
        minLat = math.min(minLat, p.latitude);
        maxLat = math.max(maxLat, p.latitude);
        minLng = math.min(minLng, p.longitude);
        maxLng = math.max(maxLng, p.longitude);
      }
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          80,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _activeRoute = route;
      _activeRouteShortNames = shortNames;
      if (_busMode == _BusMode.routeOnly) _busMode = _BusMode.showAll;
      _polylines..clear()..addAll(newPolylines);
      _stopMarkers..clear()..addAll(newStopMarkers);
    });
  }

  void _cancelNavigation() {
    setState(() {
      _activeRoute = null;
      _polylines.clear();
      _stopMarkers.clear();
      if (_busMode == _BusMode.routeOnly) _busMode = _BusMode.showAll;
      _activeRouteShortNames = {};
    });
  }

  void _openSearch() {
    setState(() => _searchOverlayVisible = true);
    Future.microtask(() => _searchFocus.requestFocus());
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    setState(() {
      _searchOverlayVisible = false;
      _suggestions = [];
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _originCtrl.clear();
    _debounce?.cancel();
    _originDebounce?.cancel();
    setState(() {
      _suggestions = [];
      _loadingSuggestions = false;
      _originSuggestions = [];
      _loadingOriginSuggestions = false;
      _originLat = null;
      _originLng = null;
      _destinationMarker = null;
      _destName = null;
      _destLat = null;
      _destLng = null;
      _activeRoute = null;
      _polylines.clear();
      _stopMarkers.clear();
      if (_busMode == _BusMode.routeOnly) _busMode = _BusMode.showAll;
      _activeRouteShortNames = {};
      _searchOverlayVisible = false;
    });
  }

  Future<void> _updateMarkers(List<Map<String, dynamic>> vehicles) async {
    _lastVehicles = vehicles;
    final newMarkers = <Marker>{};
    if (_busMode != _BusMode.hideAll) {
      for (final v in vehicles) {
        final vehicleId = v['vehicleId'] as String;
        final routeId = (v['routeId'] as String?) ?? '?';
        final shortName = RoutesLookup.instance.shortName(routeId);
        final lat = (v['lat'] as num).toDouble();
        final lng = (v['lng'] as num).toDouble();

        if (_busMode == _BusMode.routeOnly &&
            _activeRouteShortNames.isNotEmpty &&
            !_activeRouteShortNames.contains(shortName)) {
          continue;
        }
        if (_busMode == _BusMode.custom &&
            _customRoute.isNotEmpty &&
            shortName.toLowerCase() != _customRoute.toLowerCase()) {
          continue;
        }

        _iconCache[vehicleId] ??= await buildRouteMarker(shortName, vehicleId);

        final capturedVehicle = {
          'vehicleId': vehicleId,
          'shortName': shortName,
          'routeId': routeId,
        };
        newMarkers.add(Marker(
          markerId: MarkerId(vehicleId),
          position: LatLng(lat, lng),
          icon: _iconCache[vehicleId]!,
          onTap: () => setState(() => _tappedVehicle = capturedVehicle),
        ));
      }
    }
    if (_destinationMarker != null) newMarkers.add(_destinationMarker!);
    newMarkers.addAll(_stopMarkers);
    if (mounted) setState(() => _markers..clear()..addAll(newMarkers));
  }

  void _showMapTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1B2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Map Type',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            for (final option in [
              (type: MapType.normal, label: 'Default', icon: Icons.map_outlined),
              (type: MapType.satellite, label: 'Satellite', icon: Icons.satellite_alt_outlined),
              (type: MapType.terrain, label: 'Terrain', icon: Icons.terrain_outlined),
              (type: MapType.hybrid, label: 'Hybrid', icon: Icons.layers_outlined),
            ])
              InkWell(
                onTap: () {
                  setState(() => _mapType = option.type);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Icon(option.icon,
                          color: _mapType == option.type
                              ? const Color(0xFF7FDBFF)
                              : Colors.white54,
                          size: 22),
                      const SizedBox(width: 16),
                      Text(option.label,
                          style: TextStyle(
                            color: _mapType == option.type
                                ? const Color(0xFF7FDBFF)
                                : Colors.white70,
                            fontSize: 15,
                            fontWeight: _mapType == option.type
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )),
                      const Spacer(),
                      if (_mapType == option.type)
                        const Icon(Icons.check_circle,
                            color: Color(0xFF7FDBFF), size: 18),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBusPicker() {
    final customCtrl = TextEditingController(text: _customRoute);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          void select(_BusMode mode) {
            setState(() => _busMode = mode);
            setSheetState(() {});
            _updateMarkers(_lastVehicles);
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0D1B2A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text('Bus Display',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Show all
                  _BusRadioTile(
                    label: 'Show all buses',
                    subtitle: 'Display all live bus locations on the map',
                    selected: _busMode == _BusMode.showAll,
                    onTap: () => select(_BusMode.showAll),
                  ),

                  // Hide all
                  _BusRadioTile(
                    label: 'Hide all buses',
                    subtitle: 'Remove all bus markers from the map',
                    selected: _busMode == _BusMode.hideAll,
                    onTap: () => select(_BusMode.hideAll),
                  ),

                  // Route only — only when navigating
                  if (_activeRoute != null)
                    _BusRadioTile(
                      label: 'Show route buses only',
                      subtitle: 'Only show buses on your active route',
                      selected: _busMode == _BusMode.routeOnly,
                      onTap: () => select(_BusMode.routeOnly),
                    ),

                  // Custom route
                  _BusRadioTile(
                    label: 'Track specific route',
                    subtitle: 'Only show buses for a route number you choose',
                    selected: _busMode == _BusMode.custom,
                    onTap: () => select(_BusMode.custom),
                  ),

                  // Custom route input — shown when custom is selected
                  if (_busMode == _BusMode.custom) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customCtrl,
                            autofocus: true,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'e.g. 372, 550, E Line',
                              hintStyle: const TextStyle(
                                  color: Colors.white38, fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFF122340),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF7FDBFF), width: 1.5),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() => _customRoute = v.trim());
                              setSheetState(() {});
                              _updateMarkers(_lastVehicles);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Filters live to buses matching this route name',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _goToMyLocation() {
    final position = ref.read(locationProvider).valueOrNull;
    if (position == null || _mapController == null) return;
    _mapController!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final locationAsync = ref.watch(locationProvider);
    final hasLocation = locationAsync.valueOrNull != null;
    final topPad = MediaQuery.of(context).padding.top;

    vehiclesAsync.whenData(_updateMarkers);

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Full-screen map
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _seattle, zoom: 12),
            markers: _markers,
            polylines: _polylines,
            mapType: _mapType,
            myLocationEnabled: hasLocation,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              c.setMapStyle(_mapStyle);
            },
            onTap: (_) {
              if (_searchOverlayVisible) {
                _closeSearch();
              }
              setState(() => _tappedVehicle = null);
            },
          ),

          // Weather chip — below search bar, top-left
          Positioned(
            top: topPad + 12 + 56 + 10,
            left: 16,
            child: _tappedVehicle != null || _searchOverlayVisible || _activeRoute != null
                ? const SizedBox.shrink()
                : const WeatherChip(),
          ),

          // Vehicle info card — shown when a bus marker is tapped
          if (_tappedVehicle != null && !_searchOverlayVisible)
            Positioned(
              top: topPad + 12 + 56 + 10,
              left: 16,
              right: 16,
              child: _VehicleInfoCard(
                vehicle: _tappedVehicle!,
                onDismiss: () => setState(() => _tappedVehicle = null),
                onReport: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _VehicleReportSheet(
                      vehicle: _tappedVehicle!,
                      isLoggedIn: ref.read(authProvider).isLoggedIn,
                      onLoginTap: () {
                        Navigator.of(context).pop();
                        context.push('/login');
                      },
                    ),
                  );
                },
              ),
            ),

          // Active navigation panel — draggable sheet
          if (_activeRoute != null)
            Positioned.fill(
              child: DraggableScrollableSheet(
                initialChildSize: 0.22,
                minChildSize: 0.18,
                maxChildSize: 0.78,
                snap: true,
                snapSizes: const [0.22, 0.78],
                builder: (context, scrollController) => _ActiveRoutePanel(
                  route: _activeRoute!,
                  destName: _destName ?? 'Destination',
                  scrollController: scrollController,
                  onCancel: _cancelNavigation,
                ),
              ),
            ),

          // Top search card (Google Maps style — idle state)
          if (!_searchOverlayVisible && _activeRoute == null)
            Positioned(
              top: topPad + 12,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: _openSearch,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black54,
                          blurRadius: 16,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: Color(0xFF7FDBFF), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _destName != null
                              ? _destName!
                              : 'Search destination...',
                          style: TextStyle(
                            color: _destName != null
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_destName != null)
                        GestureDetector(
                          onTap: _clearSearch,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.close,
                                color: Colors.white38, size: 18),
                          ),
                        )
                      else
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF122340),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.directions_transit,
                              color: Color(0xFF7FDBFF), size: 16),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Full-screen search overlay (Google Maps style)
          if (_searchOverlayVisible)
            Positioned.fill(
              child: Material(
                color: const Color(0xFF0D1B2A),
                child: Column(
                  children: [
                    // Input section
                    Container(
                      color: const Color(0xFF0D1B2A),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Back button
                              IconButton(
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: _closeSearch,
                              ),
                              // Input fields with connecting line
                              Expanded(
                                child: Column(
                                  children: [
                                    // Origin row
                                    Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: _originFieldActive
                                            ? const Color(0xFF1A3A5C)
                                            : const Color(0xFF122340),
                                        borderRadius: BorderRadius.circular(10),
                                        border: _originFieldActive
                                            ? Border.all(
                                                color: const Color(0xFF7FDBFF)
                                                    .withOpacity(0.5))
                                            : null,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF7FDBFF),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextField(
                                              controller: _originCtrl,
                                              focusNode: _originFocus,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14),
                                              decoration: const InputDecoration(
                                                hintText: 'Your location',
                                                hintStyle: TextStyle(
                                                    color: Colors.white54),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                              ),
                                              onChanged: _onOriginChanged,
                                              textInputAction:
                                                  TextInputAction.search,
                                              onSubmitted: (_) {
                                                if (_originSuggestions
                                                    .isNotEmpty) {
                                                  _selectOriginSuggestion(
                                                      _originSuggestions.first);
                                                }
                                              },
                                            ),
                                          ),
                                          if (_loadingOriginSuggestions)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white38),
                                            )
                                          else if (_originCtrl.text.isNotEmpty)
                                            GestureDetector(
                                              onTap: () {
                                                _originCtrl.clear();
                                                setState(() {
                                                  _originSuggestions = [];
                                                  _originLat = null;
                                                  _originLng = null;
                                                });
                                              },
                                              child: const Icon(Icons.close,
                                                  color: Colors.white38,
                                                  size: 18),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Connector line
                                    Row(
                                      children: [
                                        const SizedBox(width: 18),
                                        Container(
                                            width: 1.5,
                                            height: 10,
                                            color: Colors.white24),
                                      ],
                                    ),
                                    // Destination field
                                    Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A3A5C),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFF7FDBFF)
                                                .withOpacity(0.5)),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFF7FDBFF),
                                                  width: 2),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextField(
                                              controller: _searchCtrl,
                                              focusNode: _searchFocus,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14),
                                              decoration: const InputDecoration(
                                                hintText: 'Search destination',
                                                hintStyle: TextStyle(
                                                    color: Colors.white38),
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                              ),
                                              onChanged: _onSearchChanged,
                                              textInputAction:
                                                  TextInputAction.search,
                                              onSubmitted: (_) {
                                                if (_suggestions.isNotEmpty) {
                                                  _selectSuggestion(
                                                      _suggestions.first);
                                                }
                                              },
                                            ),
                                          ),
                                          if (_loadingSuggestions)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white38),
                                            )
                                          else if (_searchCtrl.text.isNotEmpty)
                                            GestureDetector(
                                              onTap: () {
                                                _searchCtrl.clear();
                                                setState(() {
                                                  _suggestions = [];
                                          
                                                });
                                              },
                                              child: const Icon(Icons.close,
                                                  color: Colors.white38,
                                                  size: 18),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    // Suggestions list
                    Expanded(
                      child: Builder(builder: (context) {
                        final activeSuggestions = _originFieldActive
                            ? _originSuggestions
                            : _suggestions;
                        final isLoading = _originFieldActive
                            ? _loadingOriginSuggestions
                            : _loadingSuggestions;
                        final isLoggedIn = ref.watch(authProvider).isLoggedIn;
                        final showFavorites = activeSuggestions.isEmpty &&
                            !isLoading &&
                            !_originFieldActive &&
                            isLoggedIn;

                        if (showFavorites) {
                          final favAsync = ref.watch(_favoritesProvider);
                          return favAsync.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: CircularProgressIndicator(
                                    color: Color(0xFF7FDBFF), strokeWidth: 2),
                              ),
                            ),
                            error: (_, __) => const Padding(
                              padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
                              child: Text('Start typing to search',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 14)),
                            ),
                            data: (favs) => favs.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
                                    child: Text('Start typing to search',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 14)),
                                  )
                                : ListView(
                                    padding: EdgeInsets.zero,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                                        child: Text(
                                          'Saved Places',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      for (final fav in favs)
                                        InkWell(
                                          onTap: () => _selectFavorite(fav),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF122340),
                                                    borderRadius:
                                                        BorderRadius.circular(18),
                                                  ),
                                                  child: const Icon(
                                                      Icons.star,
                                                      color: Color(0xFF7FDBFF),
                                                      size: 18),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        fav.label,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                      if (fav.destName.isNotEmpty)
                                                        Text(
                                                          fav.destName,
                                                          style: const TextStyle(
                                                              color: Colors.white38,
                                                              fontSize: 12),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      const Divider(
                                          height: 1, color: Colors.white10),
                                      const Padding(
                                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                                        child: Text(
                                          'Or start typing to search',
                                          style: TextStyle(
                                              color: Colors.white38, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        }

                        return activeSuggestions.isEmpty && !isLoading
                          ? const Padding(
                              padding: EdgeInsets.fromLTRB(24, 28, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.history,
                                          color: Colors.white24, size: 18),
                                      SizedBox(width: 10),
                                      Text(
                                        'Start typing to search',
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: activeSuggestions.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Colors.white10,
                                indent: 64,
                              ),
                              itemBuilder: (_, i) {
                                final s = activeSuggestions[i];
                                return InkWell(
                                  onTap: () => _originFieldActive
                                      ? _selectOriginSuggestion(s)
                                      : _selectSuggestion(s),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF122340),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          child: const Icon(Icons.place,
                                              color: Color(0xFF7FDBFF),
                                              size: 18),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.mainText,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w500),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (s.secondaryText.isNotEmpty)
                                                Text(
                                                  s.secondaryText,
                                                  style: const TextStyle(
                                                      color: Colors.white38,
                                                      fontSize: 12),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.north_west,
                                            color: Colors.white24, size: 16),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                      }),
                    ),
                  ],
                ),
              ),
            ),

          // Map controls — stacked bottom-right, slide up with route panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _activeRoute != null ? 180 : 32,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Map type picker
                _MapControlButton(
                  icon: Icons.layers_outlined,
                  tooltip: 'Map type',
                  onPressed: _showMapTypePicker,
                ),
                const SizedBox(height: 8),
                // Bus options popup
                _MapControlButton(
                  icon: _busMode == _BusMode.hideAll
                      ? Icons.directions_bus_filled
                      : Icons.directions_bus,
                  tooltip: 'Bus options',
                  active: _busMode != _BusMode.showAll,
                  onPressed: _showBusPicker,
                ),
                const SizedBox(height: 8),
                // My location
                _MapControlButton(
                  icon: hasLocation
                      ? Icons.my_location
                      : Icons.location_searching,
                  tooltip: 'My location',
                  onPressed: _goToMyLocation,
                ),
              ],
            ),
          ),

          if (vehiclesAsync.hasError)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                color: const Color(0xE6122340),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Error: ${vehiclesAsync.error}',
                      style: const TextStyle(color: Colors.white70)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Active Navigation Panel ──────────────────────────────────────────────────

class _ActiveRoutePanel extends StatelessWidget {
  final TransitRoute route;
  final String destName;
  final ScrollController scrollController;
  final VoidCallback onCancel;

  const _ActiveRoutePanel({
    required this.route,
    required this.destName,
    required this.scrollController,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final merged = route.mergedSteps;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12)],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // Drag handle
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Color(0xFF7FDBFF), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To $destName',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${route.totalDuration}  ·  ${route.departureTime} → ${route.arrivalTime}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Pills summary
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: _buildMiniPills(merged)),
                  ),
                ),
                const SizedBox(width: 8),
                // Cancel button
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Swipe hint
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_up, color: Colors.white24, size: 16),
                SizedBox(width: 4),
                Text('Swipe up for step-by-step directions',
                    style: TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Step-by-step directions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              children: [
                for (final s in merged)
                  s.travelMode == 'TRANSIT'
                      ? _NavTransitRow(step: s)
                      : _NavWalkRow(step: s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMiniPills(List<RouteStep> steps) {
    final widgets = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      if (i > 0) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Icon(Icons.arrow_forward, color: Colors.white24, size: 10),
        ));
      }
      final s = steps[i];
      if (s.travelMode == 'TRANSIT') {
        final label = s.lineShortName ?? s.lineName ?? '?';
        widgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _transitColor(s.vehicleType),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ));
      } else {
        widgets.add(const Text('🚶', style: TextStyle(fontSize: 11)));
      }
    }
    return widgets;
  }
}

class _NavTransitRow extends StatelessWidget {
  final RouteStep step;
  const _NavTransitRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: _transitColor(step.vehicleType), shape: BoxShape.circle),
            child: Center(
              child: Text(_vehicleEmoji(step.vehicleType),
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _transitColor(step.vehicleType),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        step.lineShortName ?? step.lineName ?? '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        step.headsign != null
                            ? 'toward ${step.headsign}'
                            : '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${step.departureStop} → ${step.arrivalStop}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                Text(
                  '${step.stepDepartureTime} → ${step.stepArrivalTime}'
                  '${step.numStops != null ? ' · ${step.numStops} stops' : ''}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavWalkRow extends StatelessWidget {
  final RouteStep step;
  const _NavWalkRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
                color: Colors.white10, shape: BoxShape.circle),
            child: const Center(
                child: Text('🚶', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Text('Walk ${step.distance}  ·  ${step.duration}',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

String _vehicleEmoji(String? type) {
  switch (type) {
    case 'SUBWAY':
    case 'HEAVY_RAIL':
      return '🚇';
    case 'COMMUTER_TRAIN':
    case 'RAIL':
      return '🚆';
    case 'TRAM':
    case 'LIGHT_RAIL':
      return '🚊';
    case 'FERRY':
      return '⛴️';
    default:
      return '🚌';
  }
}

// ─── Bus Radio Tile ───────────────────────────────────────────────────────────

class _BusRadioTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _BusRadioTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: const Color(0xFF7FDBFF),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: selected ? const Color(0xFF7FDBFF) : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Map Control Button ───────────────────────────────────────────────────────

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;
  const _MapControlButton(
      {required this.icon, required this.tooltip, this.onPressed, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? const Color(0xFF7FDBFF).withOpacity(0.2) : const Color(0xE6122340),
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon,
                color: active ? const Color(0xFF7FDBFF) : Colors.white,
                size: 20),
          ),
        ),
      ),
    );
  }
}

// ─── Vehicle Info Card ────────────────────────────────────────────────────────

class _VehicleInfoCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onDismiss;
  final VoidCallback onReport;
  const _VehicleInfoCard(
      {required this.vehicle,
      required this.onDismiss,
      required this.onReport});

  @override
  Widget build(BuildContext context) {
    final shortName = vehicle['shortName'] as String;
    final vehicleId = vehicle['vehicleId'] as String;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xF2122340),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Route badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F4C81),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🚌', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    shortName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Vehicle ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Bus',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(
                    'Vehicle $vehicleId',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Report button
            GestureDetector(
              onTap: onReport,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFF6B6B).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_outlined,
                        color: Color(0xFFFF6B6B), size: 14),
                    SizedBox(width: 5),
                    Text('Report',
                        style: TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Dismiss
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: Colors.white24, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vehicle Report Sheet ─────────────────────────────────────────────────────

class _VehicleReportSheet extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final bool isLoggedIn;
  final VoidCallback onLoginTap;
  const _VehicleReportSheet(
      {required this.vehicle,
      required this.isLoggedIn,
      required this.onLoginTap});

  @override
  State<_VehicleReportSheet> createState() => _VehicleReportSheetState();
}

class _VehicleReportSheetState extends State<_VehicleReportSheet> {
  int _cleanliness = 0; // 0 = not rated
  int _crowding = 0;
  int _delay = 0;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  bool get _hasAnyRating =>
      _cleanliness > 0 || _crowding > 0 || _delay > 0;

  Future<void> _submit() async {
    if (!_hasAnyRating) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final vehicleId = widget.vehicle['vehicleId'] as String;
    final routeId = widget.vehicle['routeId'] as String? ?? '';

    try {
      final dio = buildApiClient();
      final futures = <Future>[];

      if (_cleanliness > 0) {
        futures.add(dio.post(
          '/transit/vehicles/$vehicleId/report/cleanliness',
          data: {'routeId': routeId, 'level': _cleanliness},
        ));
      }
      if (_crowding > 0) {
        futures.add(dio.post(
          '/transit/vehicles/$vehicleId/report/crowding',
          data: {'routeId': routeId, 'level': _crowding},
        ));
      }
      if (_delay > 0) {
        futures.add(dio.post(
          '/transit/vehicles/$vehicleId/report/delay',
          data: {'routeId': routeId, 'level': _delay},
        ));
      }

      await Future.wait(futures);
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Failed to submit. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortName = widget.vehicle['shortName'] as String;
    final vehicleId = widget.vehicle['vehicleId'] as String;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C81),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🚌', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 5),
                      Text(shortName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Report this bus',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text('Vehicle $vehicleId',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          if (!widget.isLoggedIn) ...[
            // Not logged in — prompt to sign in
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline,
                      color: Colors.white24, size: 40),
                  const SizedBox(height: 12),
                  const Text('Sign in to submit reports',
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: widget.onLoginTap,
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          ] else if (_submitted) ...[
            // Success
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Color(0xFF7FDBFF), size: 48),
                  SizedBox(height: 12),
                  Text('Report submitted!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Thank you for helping improve transit.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ] else ...[
            // Rating sections
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  _RatingRow(
                    emoji: '🧹',
                    label: 'Cleanliness',
                    sublabels: const [
                      'Very dirty',
                      'Dirty',
                      'Okay',
                      'Clean',
                      'Very clean'
                    ],
                    value: _cleanliness,
                    onChanged: (v) => setState(() => _cleanliness = v),
                  ),
                  const SizedBox(height: 20),
                  _RatingRow(
                    emoji: '👥',
                    label: 'Crowding',
                    sublabels: const [
                      'Empty',
                      'Light',
                      'Moderate',
                      'Busy',
                      'Packed'
                    ],
                    value: _crowding,
                    onChanged: (v) => setState(() => _crowding = v),
                  ),
                  const SizedBox(height: 20),
                  _RatingRow(
                    emoji: '⏱',
                    label: 'Delay',
                    sublabels: const [
                      '1+ min',
                      '3+ min',
                      '5+ min',
                      '10+ min',
                      '20+ min',
                    ],
                    buttonLabels: const [
                      '1+ min',
                      '3+ min',
                      '5+ min',
                      '10+ min',
                      '20+ min',
                    ],
                    value: _delay,
                    onChanged: (v) => setState(() => _delay = v),
                  ),
                  const SizedBox(height: 8),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          (_hasAnyRating && !_submitting) ? _submit : null,
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: Colors.white10,
                        disabledForegroundColor: Colors.white24,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0D1B2A)),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String emoji;
  final String label;
  final List<String> sublabels;
  final List<String>? buttonLabels;
  final int value; // 0 = unset, 1–5 = selected
  final ValueChanged<int> onChanged;

  const _RatingRow({
    required this.emoji,
    required this.label,
    required this.sublabels,
    this.buttonLabels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (value > 0)
              Text(
                sublabels[value - 1],
                style: const TextStyle(
                    color: Color(0xFF7FDBFF), fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Rating buttons 1–5
        Row(
          children: List.generate(5, (i) {
            final level = i + 1;
            final selected = value == level;
            final filled = value >= level && value > 0;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onChanged(selected ? 0 : level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 40,
                    decoration: BoxDecoration(
                      color: filled
                          ? const Color(0xFF0F4C81)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF7FDBFF)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        buttonLabels != null ? buttonLabels![i] : '$level',
                        style: TextStyle(
                          color: filled ? Colors.white : Colors.white38,
                          fontWeight: filled
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: buttonLabels != null ? 12 : 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        // Scale hint — only shown for numeric ratings
        if (buttonLabels == null)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 = Low', style: TextStyle(color: Colors.white24, fontSize: 10)),
                Text('5 = High', style: TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Loading Sheet ────────────────────────────────────────────────────────────

class _LoadingRouteSheet extends StatelessWidget {
  final String destName;
  const _LoadingRouteSheet({required this.destName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const CircularProgressIndicator(color: Color(0xFF7FDBFF)),
          const SizedBox(height: 16),
          Text(
            'Finding routes to $destName...',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
