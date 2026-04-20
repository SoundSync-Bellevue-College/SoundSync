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
import '../services/api_client.dart';
import '../services/geocoding_service.dart';
import '../services/route_planning_service.dart';
import '../services/routes_lookup.dart';
import '../widgets/transit_route_sheet.dart';
import '../widgets/weather_chip.dart';
import '../widgets/vehicle_marker.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF1A56DB);   // bold blue
const _kAccent     = Color(0xFF16A34A);   // green confidence
const _kUrgent     = Color(0xFFFEF3C7);   // soft yellow card bg
const _kUrgentText = Color(0xFFD97706);   // amber text
const _kSurface    = Colors.white;
const _kBg         = Color(0xFFF8F9FB);
const _kText       = Color(0xFF111827);
const _kSubtext    = Color(0xFF6B7280);
const _kBorder     = Color(0xFFE5E7EB);
const _kShadow     = Color(0x14000000);

// ─── Light Map Style (Apple Maps-like) ───────────────────────────────────────
const _mapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#f0f4f8"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#4a5568"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#c8d6e5"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#edf2f7"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.fill","stylers":[{"color":"#e2e8f0"}]},
  {"featureType":"landscape.natural","elementType":"geometry.fill","stylers":[{"color":"#e8f5e9"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#c6e6c3"},{"visibility":"on"}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"simplified"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#d1d5db"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#fde68a"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#fbbf24"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#374151"}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#bfdbfe"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#dbeafe"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#1A56DB"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#bfdbfe"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#60a5fa"}]}
]''';

// ─── Polyline decoder ────────────────────────────────────────────────────────
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

// Radius (in miles) used to filter nearby vehicles around the user.
const double _kNearbyRadiusMiles = 1.0;
const double _kFollowUserZoom    = 13.8; // shows ~1.5-2 mi wide so nearby buses are visible on screen

// Simple equirectangular distance in miles (plenty accurate for ~1mi scale)
double _distanceMiles(double lat1, double lng1, double lat2, double lng2) {
  const double milesPerDegreeLat = 69.0;
  final double avgLatRad = ((lat1 + lat2) / 2) * math.pi / 180.0;
  final double dLat = (lat2 - lat1) * milesPerDegreeLat;
  final double dLng = (lng2 - lng1) * milesPerDegreeLat * math.cos(avgLatRad);
  return math.sqrt(dLat * dLat + dLng * dLng);
}

// ─── HomeScreen ──────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers     = {};
  final Set<Polyline> _polylines = {};
  final Set<Marker> _stopMarkers = {};
  BitmapDescriptor? _stopIcon;
  final Map<String, BitmapDescriptor> _iconCache = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<PlaceSuggestion> _suggestions    = [];
  bool _loadingSuggestions              = false;
  bool _showSuggestions                 = false;
  Map<String, dynamic>? _tappedVehicle;
  Marker? _destinationMarker;
  Timer? _debounce;
  String? _destName;
  double? _destLat;
  double? _destLng;
  TransitRoute? _activeRoute;
  bool _navStepsExpanded                = false;
  bool _filterToRouteOnly               = false;
  bool _hasCenteredOnUser               = false;
  Set<String> _activeRouteShortNames    = {};
  List<Map<String, dynamic>> _lastVehicles = [];

  @override
  void initState() {
    super.initState();
    RoutesLookup.instance.load();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // dark icons on light bg
    ));
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Search logic (unchanged) ───────────────────────────────────────────────
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() { _suggestions = []; _showSuggestions = false; _loadingSuggestions = false; });
      return;
    }
    setState(() => _loadingSuggestions = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final results = await GeocodingService.autocomplete(value);
      if (mounted) {
        setState(() {
          _suggestions     = results;
          _showSuggestions = results.isNotEmpty;
          _loadingSuggestions = false;
        });
      }
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion s) async {
    _searchCtrl.text = s.mainText;
    _searchFocus.unfocus();
    setState(() { _showSuggestions = false; _suggestions = []; _loadingSuggestions = true; });
    final result = await GeocodingService.placeDetails(s.placeId);
    setState(() => _loadingSuggestions = false);
    if (result == null) return;
    final dest = LatLng(result.lat, result.lng);
    _destName = s.mainText; _destLat = result.lat; _destLng = result.lng;
    setState(() => _destinationMarker = Marker(
      markerId: const MarkerId('__destination__'),
      position: dest,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: result.formattedAddress),
      onTap: () => _showRouteSheet(_destName!, _destLat!, _destLng!),
    ));
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(dest, 14));
    _showRouteSheet(s.mainText, result.lat, result.lng);
  }

  Future<void> _showRouteSheet(String destName, double destLat, double destLng) async {
    final position  = ref.read(locationProvider).valueOrNull;
    final originLat = position?.latitude  ?? 47.6062;
    final originLng = position?.longitude ?? -122.3321;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoadingRouteSheet(destName: destName),
    );
    try {
      final routes = await RoutePlanningService.plan(
        originLat: originLat, originLng: originLng,
        destLat: destLat,     destLng: destLng,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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
        .map((s) => s.lineShortName!).toSet();
    _stopIcon ??= await buildStopIcon();
    final newPolylines    = <Polyline>{};
    final newStopMarkers  = <Marker>{};
    final steps = route.mergedSteps;
    for (var i = 0; i < steps.length; i++) {
      final step   = steps[i];
      final points = step.stepPolylines.expand(_decodePolyline).toList();
      if (step.travelMode == 'WALKING') {
        if (points.isNotEmpty) {
          newPolylines.add(Polyline(
            polylineId: PolylineId('walk_$i'), points: points,
            color: const Color(0xFF94A3B8), width: 3,
            patterns: [PatternItem.dash(12), PatternItem.gap(6)],
          ));
        }
      } else {
        if (points.isNotEmpty) {
          newPolylines.add(Polyline(
            polylineId: PolylineId('transit_$i'), points: points,
            color: _kPrimary, width: 5,
          ));
        }
        if (step.departureLat != null && step.departureLng != null) {
          newStopMarkers.add(Marker(
            markerId: MarkerId('dep_$i'),
            position: LatLng(step.departureLat!, step.departureLng!),
            icon: _stopIcon!, anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: step.departureStop ?? 'Stop',
              snippet: '${step.lineShortName ?? step.lineName ?? ''}'
                  '${step.stepDepartureTime != null ? ' · Departs ${step.stepDepartureTime}' : ''}',
            ),
          ));
        }
        if (step.arrivalLat != null && step.arrivalLng != null) {
          newStopMarkers.add(Marker(
            markerId: MarkerId('arr_$i'),
            position: LatLng(step.arrivalLat!, step.arrivalLng!),
            icon: _stopIcon!, anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: step.arrivalStop ?? 'Stop',
              snippet: '${step.lineShortName ?? step.lineName ?? ''}'
                  '${step.stepArrivalTime != null ? ' · Arrives ${step.stepArrivalTime}' : ''}',
            ),
          ));
        }
      }
    }
    final allPoints = newPolylines.expand((p) => p.points).toList();
    if (allPoints.length > 1) {
      double minLat = allPoints.first.latitude, maxLat = allPoints.first.latitude,
             minLng = allPoints.first.longitude, maxLng = allPoints.first.longitude;
      for (final p in allPoints) {
        minLat = math.min(minLat, p.latitude); maxLat = math.max(maxLat, p.latitude);
        minLng = math.min(minLng, p.longitude); maxLng = math.max(maxLng, p.longitude);
      }
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)), 80,
      ));
    }
    if (!mounted) return;
    setState(() {
      _activeRoute = route; _navStepsExpanded = false;
      _activeRouteShortNames = shortNames; _filterToRouteOnly = false;
      _polylines..clear()..addAll(newPolylines);
      _stopMarkers..clear()..addAll(newStopMarkers);
    });
  }

  void _cancelNavigation() {
    setState(() {
      _activeRoute = null; _polylines.clear(); _stopMarkers.clear();
      _navStepsExpanded = false; _filterToRouteOnly = false;
      _activeRouteShortNames = {};
    });
  }

  void _clearSearch() {
    _searchCtrl.clear(); _debounce?.cancel();
    setState(() {
      _suggestions = []; _showSuggestions = false; _loadingSuggestions = false;
      _destinationMarker = null; _destName = null; _destLat = null; _destLng = null;
      _activeRoute = null; _polylines.clear(); _stopMarkers.clear();
      _navStepsExpanded = false; _filterToRouteOnly = false; _activeRouteShortNames = {};
    });
  }

  Future<void> _updateMarkers(List<Map<String, dynamic>> vehicles) async {
    _lastVehicles = vehicles;
    final newMarkers = <Marker>{};

    // Nearby filter: only show buses within _kNearbyRadiusMiles of the user.
    final userPos = ref.read(locationProvider).valueOrNull;
    final double? userLat = userPos?.latitude;
    final double? userLng = userPos?.longitude;

    for (final v in vehicles) {
      final vehicleId = v['vehicleId'] as String;
      final routeId   = (v['routeId'] as String?) ?? '?';
      final shortName = RoutesLookup.instance.shortName(routeId);
      final lat = (v['lat'] as num).toDouble();
      final lng = (v['lng'] as num).toDouble();

      // Distance filter (only when we have a user position and no active route
      // override). Active route filter still wins.
      if (_filterToRouteOnly && _activeRouteShortNames.isNotEmpty &&
          !_activeRouteShortNames.contains(shortName)) continue;
      if (!_filterToRouteOnly && userLat != null && userLng != null) {
        if (_distanceMiles(userLat, userLng, lat, lng) > _kNearbyRadiusMiles) {
          continue;
        }
      }

      _iconCache[vehicleId] ??= await buildRouteMarker(shortName, vehicleId);
      final capturedVehicle = {'vehicleId': vehicleId, 'shortName': shortName, 'routeId': routeId};
      newMarkers.add(Marker(
        markerId: MarkerId(vehicleId), position: LatLng(lat, lng),
        icon: _iconCache[vehicleId]!,
        onTap: () => setState(() => _tappedVehicle = capturedVehicle),
      ));
    }
    if (_destinationMarker != null) newMarkers.add(_destinationMarker!);
    newMarkers.addAll(_stopMarkers);
    if (mounted) setState(() => _markers..clear()..addAll(newMarkers));
  }

  void _showAccountMenu(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => _AccountMenuSheet(
        auth: auth,
        onLogin:    () { Navigator.of(context).pop(); context.push('/login');    },
        onRegister: () { Navigator.of(context).pop(); context.push('/register'); },
        onAccount:  () { Navigator.of(context).pop(); context.push('/account');  },
        onLogout: () async { Navigator.of(context).pop(); await ref.read(authProvider.notifier).logout(); },
      ),
    );
  }

  void _goToMyLocation() {
    final position = ref.read(locationProvider).valueOrNull;
    if (position == null || _mapController == null) return;
    _mapController!.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: _kFollowUserZoom),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final locationAsync = ref.watch(locationProvider);
    final hasLocation   = locationAsync.valueOrNull != null;
    final topPad        = MediaQuery.of(context).padding.top;

    vehiclesAsync.whenData(_updateMarkers);

    // Follow the user: snap on first location, then keep following as they
    // move (unless a route is active or the user is typing in search).
    locationAsync.whenData((pos) {
      if (pos == null) return;                    // location not yet available
      if (_mapController == null) return;
      if (_activeRoute != null) return;          // don't override active route framing
      if (_searchFocus.hasFocus) return;         // don't yank the map while searching
      final target = LatLng(pos.latitude, pos.longitude);
      if (!_hasCenteredOnUser) {
        _hasCenteredOnUser = true;
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: _kFollowUserZoom),
          ),
        );
        // Re-run the vehicle filter now that we know where the user is.
        _updateMarkers(_lastVehicles);
      } else {
        _mapController!.animateCamera(CameraUpdate.newLatLng(target));
      }
    });

    return Scaffold(
      backgroundColor: _kBg,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Full-screen light map ──────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: _seattle, zoom: _kFollowUserZoom),
            markers: _markers,
            polylines: _polylines,
            mapType: MapType.normal,
            myLocationEnabled: hasLocation,
            myLocationButtonEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              c.setMapStyle(_mapStyle);
              // If we already have the user's location by the time the map is
              // created, snap to it right now (the reactive listener up in
              // build() may have missed the first emission).
              final pos = ref.read(locationProvider).valueOrNull;
              if (pos != null && !_hasCenteredOnUser) {
                _hasCenteredOnUser = true;
                c.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(pos.latitude, pos.longitude),
                      zoom: _kFollowUserZoom,
                    ),
                  ),
                );
                _updateMarkers(_lastVehicles);
              }
            },
            onTap: (_) {
              _searchFocus.unfocus();
              setState(() { _showSuggestions = false; _tappedVehicle = null; });
            },
          ),

          // ── Top search bar ─────────────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: _SearchBar(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    isLoading: _loadingSuggestions,
                    onChanged: _onSearchChanged,
                    onClear: _clearSearch,
                    onSubmit: (_) {
                      if (_suggestions.isNotEmpty) _selectSuggestion(_suggestions.first);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                _ProfileButton(onTap: () => _showAccountMenu(context, ref)),
              ],
            ),
          ),

          // ── Autocomplete dropdown ──────────────────────────────────────────
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: topPad + 12 + 52 + 6,
              left: 16, right: 16,
              child: _SuggestionsDropdown(
                suggestions: _suggestions,
                onSelect: _selectSuggestion,
              ),
            ),

          // ── Weather chip ───────────────────────────────────────────────────
          if (!_showSuggestions && _tappedVehicle == null)
            Positioned(
              top: topPad + 12 + 52 + 12,
              left: 16,
              child: const WeatherChip(),
            ),

          // ── Ask + Nearby FABs (right side, below profile) ──────────────────
          if (!_showSuggestions && _activeRoute == null)
            Positioned(
              top: topPad + 12 + 52 + 12,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _FloatingChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Ask',
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _FloatingChip(
                    emoji: '📍',
                    label: 'Nearby',
                    filled: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

          // ── Map controls (zoom + location) — only when no route active ─────
          if (_activeRoute == null)
            Positioned(
              bottom: 220,
              right: 16,
              child: Column(
                children: [
                  _MapControlButton(icon: Icons.add,    tooltip: 'Zoom in',  onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
                  const SizedBox(height: 8),
                  _MapControlButton(icon: Icons.remove, tooltip: 'Zoom out', onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: hasLocation ? Icons.my_location : Icons.location_searching,
                    tooltip: 'My location', onPressed: _goToMyLocation,
                  ),
                ],
              ),
            ),

          // ── Vehicle info card ──────────────────────────────────────────────
          if (_tappedVehicle != null && !_showSuggestions)
            Positioned(
              top: topPad + 12 + 52 + 10,
              left: 16, right: 16,
              child: _VehicleInfoCard(
                vehicle: _tappedVehicle!,
                onDismiss: () => setState(() => _tappedVehicle = null),
                onReport: () {
                  showModalBottomSheet(
                    context: context, isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _VehicleReportSheet(
                      vehicle: _tappedVehicle!,
                      isLoggedIn: ref.read(authProvider).isLoggedIn,
                      onLoginTap: () { Navigator.of(context).pop(); context.push('/login'); },
                    ),
                  );
                },
              ),
            ),

          // ── Active route panel OR default bottom panel ─────────────────────
          if (_activeRoute != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _ActiveRoutePanel(
                route: _activeRoute!,
                destName: _destName ?? 'Destination',
                expanded: _navStepsExpanded,
                filterActive: _filterToRouteOnly,
                onToggleExpand: () => setState(() => _navStepsExpanded = !_navStepsExpanded),
                onToggleFilter: () { setState(() => _filterToRouteOnly = !_filterToRouteOnly); _updateMarkers(_lastVehicles); },
                onCancel: _cancelNavigation,
              ),
            )
          else
            DraggableScrollableSheet(
              initialChildSize: 0.38, // ~38% of screen visible by default
              minChildSize: 0.12,     // collapsed: ~12% (just the handle + header peek)
              maxChildSize: 0.85,     // nearly full-screen when pulled up
              snap: true,
              snapSizes: const [0.12, 0.38, 0.85],
              builder: (context, scrollCtrl) => _DefaultBottomPanel(
                vehicles: _lastVehicles,
                userLat: locationAsync.valueOrNull?.latitude,
                userLng: locationAsync.valueOrNull?.longitude,
                scrollController: scrollCtrl,
                onVehicleTap: (vehicleId, shortName, routeId) {
                  // Navigate to Route Detail screen for the tapped bus.
                  // routeId is what the API returns (e.g. "1_100001"); the
                  // screen can use it to look up schedule, stops, etc.
                  if (routeId.isNotEmpty) {
                    context.push('/route/${Uri.encodeComponent(routeId)}');
                  }
                },
              ),
            ),

          if (vehiclesAsync.hasError)
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Error: ${vehiclesAsync.error}',
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmit;

  const _SearchBar({
    required this.controller, required this.focusNode,
    required this.isLoading,  required this.onChanged,
    required this.onClear,    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Where to?',
          hintStyle: const TextStyle(color: Color(0xFFADB5C0), fontSize: 15),
          prefixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(13),
                  child: SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
                )
              : const Icon(Icons.search_rounded, color: _kSubtext, size: 22),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _kSubtext, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.mic_none_rounded, color: _kSubtext, size: 22),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmit,
      ),
    );
  }
}

// ─── Suggestions Dropdown ─────────────────────────────────────────────────────
class _SuggestionsDropdown extends StatelessWidget {
  final List<PlaceSuggestion> suggestions;
  final ValueChanged<PlaceSuggestion> onSelect;
  const _SuggestionsDropdown({required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: suggestions.asMap().entries.map((entry) {
              final i = entry.key; final s = entry.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => onSelect(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: _kPrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.place_rounded, color: _kPrimary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.mainText,
                                    style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w600),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (s.secondaryText.isNotEmpty)
                                  Text(s.secondaryText,
                                      style: const TextStyle(color: _kSubtext, fontSize: 12),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < suggestions.length - 1)
                    const Divider(height: 1, color: _kBorder, indent: 62),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Floating Chip (Ask / Nearby) ─────────────────────────────────────────────
class _FloatingChip extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  const _FloatingChip({
    this.icon,
    this.emoji,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = filled ? _kPrimary : _kSurface;
    final fgColor = filled ? Colors.white : _kText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 22))
            else if (icon != null)
              Icon(icon, color: fgColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Default Bottom Panel (no route selected) ─────────────────────────────────
// Shows buses physically near the user, sorted by distance. The list gives
// users a clear "what's around me right now" feel, matching the One Bus Away
// model — no destination guessing, no fake "Leave NOW" prompts.
class _DefaultBottomPanel extends StatelessWidget {
  final List<Map<String, dynamic>> vehicles;
  final double? userLat;
  final double? userLng;
  final ScrollController? scrollController;
  final void Function(String vehicleId, String shortName, String routeId) onVehicleTap;

  const _DefaultBottomPanel({
    required this.vehicles,
    required this.userLat,
    required this.userLng,
    required this.onVehicleTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    // Build a list of nearby vehicles enriched with distance (miles).
    // Dedupe by vehicleId in case the feed echoes duplicates.
    final List<_NearbyVehicle> nearby = [];
    final seenVehicleIds = <String>{};
    for (final v in vehicles) {
      final vehicleId = (v['vehicleId'] as String?) ?? '';
      final routeId   = (v['routeId']   as String?) ?? '';
      final shortName = RoutesLookup.instance.shortName(routeId);
      if (vehicleId.isEmpty || shortName.isEmpty) continue;
      if (!seenVehicleIds.add(vehicleId)) continue; // skip duplicates
      final lat = (v['lat'] as num?)?.toDouble();
      final lng = (v['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final double? dist = (userLat != null && userLng != null)
          ? _distanceMiles(userLat!, userLng!, lat, lng)
          : null;
      nearby.add(_NearbyVehicle(
        vehicleId: vehicleId,
        routeId:   routeId,
        shortName: shortName,
        lat: lat, lng: lng,
        distanceMiles: dist,
      ));
    }
    nearby.sort((a, b) {
      final da = a.distanceMiles ?? double.infinity;
      final db = b.distanceMiles ?? double.infinity;
      return da.compareTo(db);
    });

    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      // ListView tied to DraggableScrollableSheet's controller: pulling the
      // sheet and scrolling the list are unified gestures.
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
            child: Row(
              children: [
                const Text('🚌', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text(
                  'Buses near you',
                  style: TextStyle(
                    color: _kText, fontSize: 16, fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${nearby.length} live',
                  style: const TextStyle(color: _kSubtext, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // List — empty state OR rows of buses
          if (nearby.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 24),
              child: Row(
                children: [
                  Icon(Icons.directions_bus_outlined, color: _kSubtext, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No buses within range right now. Try zooming out.',
                      style: TextStyle(color: _kSubtext, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              child: Column(
                children: nearby.map((v) => _NearbyBusRow(
                  vehicle: v,
                  onTap: () => onVehicleTap(v.vehicleId, v.shortName, v.routeId),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _NearbyVehicle {
  final String vehicleId;
  final String routeId;
  final String shortName;
  final double lat;
  final double lng;
  final double? distanceMiles;
  const _NearbyVehicle({
    required this.vehicleId,
    required this.routeId,
    required this.shortName,
    required this.lat,
    required this.lng,
    required this.distanceMiles,
  });
}

class _NearbyBusRow extends StatelessWidget {
  final _NearbyVehicle vehicle;
  final VoidCallback onTap;
  const _NearbyBusRow({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dist = vehicle.distanceMiles;
    final distLabel = dist == null
        ? 'Live'
        : dist < 0.1
            ? 'Here'
            : '${dist.toStringAsFixed(1)} mi away';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            // Route pill
            Container(
              width: 52, height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                vehicle.shortName,
                style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Vehicle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route ${vehicle.shortName}',
                    style: const TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vehicle ${vehicle.vehicleId}',
                    style: const TextStyle(color: _kSubtext, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  distLabel,
                  style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Live',
                  style: TextStyle(color: _kAccent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Route Arrival Card ───────────────────────────────────────────────────────
class _RouteArrivalCard extends StatelessWidget {
  final String shortName;
  final String headsign;
  final String minutes;
  final int? confidence;
  final VoidCallback onTap;

  const _RouteArrivalCard({
    required this.shortName, required this.headsign,
    required this.minutes,   required this.onTap,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final conf = confidence ?? 94;
    final confColor = conf >= 90 ? _kAccent : conf >= 75 ? _kUrgentText : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(shortName,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(headsign,
                      style: const TextStyle(color: _kSubtext, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(minutes == '—' ? 'Live' : '$minutes min',
                style: const TextStyle(color: _kText, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: confColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$conf% confident',
                  style: TextStyle(color: confColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Active Route Panel ───────────────────────────────────────────────────────
class _ActiveRoutePanel extends StatelessWidget {
  final TransitRoute route;
  final String destName;
  final bool expanded;
  final bool filterActive;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleFilter;
  final VoidCallback onCancel;

  const _ActiveRoutePanel({
    required this.route, required this.destName,
    required this.expanded, required this.filterActive,
    required this.onToggleExpand, required this.onToggleFilter,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final merged = route.mergedSteps;
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          GestureDetector(
            onTap: onToggleExpand,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('To $destName',
                          style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${route.totalDuration}  ·  ${route.departureTime} → ${route.arrivalTime}',
                          style: const TextStyle(color: _kSubtext, fontSize: 12)),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: _buildMiniPills(merged)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.close_rounded, color: _kSubtext, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Filter toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GestureDetector(
              onTap: onToggleFilter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: filterActive ? _kPrimary : _kBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: filterActive ? _kPrimary : _kBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(filterActive ? Icons.directions_bus : Icons.directions_bus_outlined,
                        size: 15, color: filterActive ? Colors.white : _kSubtext),
                    const SizedBox(width: 6),
                    Text(
                      filterActive ? 'Showing route buses only' : 'Show route buses only',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: filterActive ? Colors.white : _kSubtext),
                    ),
                    const SizedBox(width: 6),
                    Icon(filterActive ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 14, color: filterActive ? Colors.white : _kSubtext),
                  ],
                ),
              ),
            ),
          ),

          // Expanded steps
          if (expanded) ...[
            const Divider(height: 1, color: _kBorder),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: merged.length,
                itemBuilder: (_, i) {
                  final s = merged[i];
                  return s.travelMode == 'TRANSIT'
                      ? _NavTransitRow(step: s)
                      : _NavWalkRow(step: s);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMiniPills(List<RouteStep> steps) {
    final widgets = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      if (i > 0) widgets.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Icon(Icons.arrow_forward_rounded, color: _kBorder, size: 10),
      ));
      final s = steps[i];
      if (s.travelMode == 'TRANSIT') {
        final label = s.lineShortName ?? s.lineName ?? '?';
        widgets.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ));
      } else {
        widgets.add(const Text('🚶', style: TextStyle(fontSize: 11)));
      }
    }
    return widgets;
  }
}

// ─── Nav Rows ─────────────────────────────────────────────────────────────────
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
            decoration: BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
            child: Center(child: Text(_vehicleEmoji(step.vehicleType), style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(6)),
                      child: Text(step.lineShortName ?? step.lineName ?? '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(step.headsign != null ? 'toward ${step.headsign}' : '',
                          style: const TextStyle(color: _kSubtext, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${step.departureStop} → ${step.arrivalStop}',
                    style: const TextStyle(color: _kText, fontSize: 12)),
                Text(
                  '${step.stepDepartureTime} → ${step.stepArrivalTime}'
                  '${step.numStops != null ? ' · ${step.numStops} stops' : ''}',
                  style: const TextStyle(color: _kSubtext, fontSize: 11),
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
            decoration: BoxDecoration(color: _kBg, shape: BoxShape.circle,
                border: Border.all(color: _kBorder)),
            child: const Center(child: Text('🚶', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Text('Walk ${step.distance}  ·  ${step.duration}',
              style: const TextStyle(color: _kText, fontSize: 13)),
        ],
      ),
    );
  }
}

String _vehicleEmoji(String? type) {
  switch (type) {
    case 'SUBWAY': case 'HEAVY_RAIL': return '🚇';
    case 'COMMUTER_TRAIN': case 'RAIL': return '🚆';
    case 'TRAM': case 'LIGHT_RAIL': return '🚊';
    case 'FERRY': return '⛴️';
    default: return '🚌';
  }
}

// ─── Map Control Button ───────────────────────────────────────────────────────
class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _MapControlButton({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _kSurface,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: _kShadow,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40, height: 40,
            child: Icon(icon, color: _kText, size: 20),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Button ───────────────────────────────────────────────────────────
class _ProfileButton extends ConsumerWidget {
  final VoidCallback onTap;
  const _ProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final initials = auth.isLoggedIn && auth.displayName.isNotEmpty
        ? auth.displayName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: _kSurface, shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Center(
          child: initials != null
              ? Text(initials, style: const TextStyle(color: _kPrimary, fontSize: 15, fontWeight: FontWeight.bold))
              : const Icon(Icons.person_outline_rounded, color: _kSubtext, size: 22),
        ),
      ),
    );
  }
}

// ─── Account Menu Sheet ───────────────────────────────────────────────────────
class _AccountMenuSheet extends StatelessWidget {
  final AuthState auth;
  final VoidCallback onLogin, onRegister, onAccount, onLogout;

  const _AccountMenuSheet({
    required this.auth, required this.onLogin, required this.onRegister,
    required this.onAccount, required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
          ),
          if (auth.isLoggedIn) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24, backgroundColor: _kPrimary.withOpacity(0.1),
                    child: Text(
                      auth.displayName.isNotEmpty
                          ? auth.displayName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
                          : '?',
                      style: const TextStyle(color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(auth.displayName, style: const TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(auth.email, style: const TextStyle(color: _kSubtext, fontSize: 13)),
                  ]),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            _MenuItem(icon: Icons.manage_accounts_outlined, label: 'My Account', onTap: onAccount),
            const Divider(height: 1, color: _kBorder),
            _MenuItem(icon: Icons.logout_rounded, label: 'Sign Out', color: Colors.red, onTap: onLogout),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: _kBg,
                      child: const Icon(Icons.person_outline_rounded, color: _kSubtext, size: 24)),
                  const SizedBox(width: 14),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Guest', style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Sign in to save routes', style: TextStyle(color: _kSubtext, fontSize: 13)),
                  ]),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            _MenuItem(icon: Icons.login_rounded, label: 'Sign In', color: _kPrimary, onTap: onLogin),
            const Divider(height: 1, color: _kBorder),
            _MenuItem(icon: Icons.person_add_outlined, label: 'Create Account', onTap: onRegister),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color = _kText});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Vehicle Info Card ────────────────────────────────────────────────────────
class _VehicleInfoCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onDismiss, onReport;
  const _VehicleInfoCard({required this.vehicle, required this.onDismiss, required this.onReport});

  @override
  Widget build(BuildContext context) {
    final shortName = vehicle['shortName'] as String;
    final vehicleId = vehicle['vehicleId'] as String;
    return Material(
      elevation: 0, borderRadius: BorderRadius.circular(16), color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kSurface, borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🚌', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(shortName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Live Bus', style: TextStyle(color: _kSubtext, fontSize: 11)),
                Text('Vehicle $vehicleId', style: const TextStyle(color: _kText, fontSize: 12), overflow: TextOverflow.ellipsis),
              ]),
            ),
            GestureDetector(
              onTap: onReport,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.red.shade50, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.flag_outlined, color: Colors.red, size: 14),
                  SizedBox(width: 5),
                  Text('Report', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(onTap: onDismiss,
                child: const Icon(Icons.close_rounded, color: _kBorder, size: 18)),
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
  const _VehicleReportSheet({required this.vehicle, required this.isLoggedIn, required this.onLoginTap});
  @override
  State<_VehicleReportSheet> createState() => _VehicleReportSheetState();
}

class _VehicleReportSheetState extends State<_VehicleReportSheet> {
  int _cleanliness = 0, _crowding = 0, _delay = 0;
  bool _submitting = false, _submitted = false;
  String? _error;
  bool get _hasAnyRating => _cleanliness > 0 || _crowding > 0 || _delay > 0;

  Future<void> _submit() async {
    if (!_hasAnyRating) return;
    setState(() { _submitting = true; _error = null; });
    final vehicleId = widget.vehicle['vehicleId'] as String;
    final routeId   = widget.vehicle['routeId'] as String? ?? '';
    try {
      final dio = buildApiClient();
      final futures = <Future>[];
      if (_cleanliness > 0) futures.add(dio.post('/transit/vehicles/$vehicleId/report/cleanliness', data: {'routeId': routeId, 'level': _cleanliness}));
      if (_crowding > 0)    futures.add(dio.post('/transit/vehicles/$vehicleId/report/crowding',    data: {'routeId': routeId, 'level': _crowding}));
      if (_delay > 0)       futures.add(dio.post('/transit/vehicles/$vehicleId/report/delay',       data: {'routeId': routeId, 'level': _delay}));
      await Future.wait(futures);
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to submit. Please try again.');
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
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 36, height: 4,
              decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🚌', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 5),
                    Text(shortName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Report this bus', style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Vehicle $vehicleId', style: const TextStyle(color: _kSubtext, fontSize: 12)),
                ])),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          if (!widget.isLoggedIn)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Icon(Icons.lock_outline_rounded, color: _kBorder, size: 40),
                const SizedBox(height: 12),
                const Text('Sign in to submit reports', style: TextStyle(color: _kSubtext, fontSize: 15)),
                const SizedBox(height: 16),
                FilledButton(onPressed: widget.onLoginTap, child: const Text('Sign In')),
              ]),
            )
          else if (_submitted)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(children: [
                Icon(Icons.check_circle_outline_rounded, color: _kAccent, size: 48),
                SizedBox(height: 12),
                Text('Report submitted!', style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Thank you for helping improve transit.', style: TextStyle(color: _kSubtext, fontSize: 13), textAlign: TextAlign.center),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(children: [
                _RatingRow(emoji: '🧹', label: 'Cleanliness', sublabels: const ['Very dirty','Dirty','Okay','Clean','Very clean'], value: _cleanliness, onChanged: (v) => setState(() => _cleanliness = v)),
                const SizedBox(height: 20),
                _RatingRow(emoji: '👥', label: 'Crowding',    sublabels: const ['Empty','Light','Moderate','Busy','Packed'],          value: _crowding,    onChanged: (v) => setState(() => _crowding = v)),
                const SizedBox(height: 20),
                _RatingRow(emoji: '⏱',  label: 'Delay',       sublabels: const ['On time','Slight','Moderate','Late','Very late'],    value: _delay,       onChanged: (v) => setState(() => _delay = v)),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_hasAnyRating && !_submitting) ? _submit : null,
                    style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                    child: _submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Report'),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String emoji, label;
  final List<String> sublabels;
  final int value;
  final ValueChanged<int> onChanged;
  const _RatingRow({required this.emoji, required this.label, required this.sublabels, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (value > 0) Text(sublabels[value - 1], style: const TextStyle(color: _kPrimary, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        Row(
          children: List.generate(5, (i) {
            final level = i + 1; final selected = value == level; final filled = value >= level && value > 0;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onChanged(selected ? 0 : level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 40,
                    decoration: BoxDecoration(
                      color: filled ? _kPrimary.withOpacity(0.1) : _kBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? _kPrimary : _kBorder, width: selected ? 1.5 : 1),
                    ),
                    child: Center(
                      child: Text('$level',
                          style: TextStyle(color: filled ? _kPrimary : _kSubtext,
                              fontWeight: filled ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('1 = Low', style: TextStyle(color: _kBorder, fontSize: 10)),
            Text('5 = High', style: TextStyle(color: _kBorder, fontSize: 10)),
          ]),
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
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))),
          const CircularProgressIndicator(color: _kPrimary),
          const SizedBox(height: 16),
          Text('Finding routes to $destName...', style: const TextStyle(color: _kSubtext, fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}