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
  bool _showSuggestions = false;
  Map<String, dynamic>? _tappedVehicle; // {vehicleId, shortName, routeId}
  Marker? _destinationMarker;
  Timer? _debounce;
  String? _destName;
  double? _destLat;
  double? _destLng;
  TransitRoute? _activeRoute;
  bool _navStepsExpanded = false;
  bool _filterToRouteOnly = false;
  Set<String> _activeRouteShortNames = {};
  List<Map<String, dynamic>> _lastVehicles = [];

  @override
  void initState() {
    super.initState();
    RoutesLookup.instance.load();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
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
          _showSuggestions = results.isNotEmpty;
          _loadingSuggestions = false;
        });
      }
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion s) async {
    _searchCtrl.text = s.mainText;
    _searchFocus.unfocus();
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
      _loadingSuggestions = true;
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
    final originLat = position?.latitude ?? 47.6062;
    final originLng = position?.longitude ?? -122.3321;

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
            color: const Color(0xFF7FDBFF),
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
      _navStepsExpanded = false;
      _activeRouteShortNames = shortNames;
      _filterToRouteOnly = false;
      _polylines..clear()..addAll(newPolylines);
      _stopMarkers..clear()..addAll(newStopMarkers);
    });
  }

  void _cancelNavigation() {
    setState(() {
      _activeRoute = null;
      _polylines.clear();
      _stopMarkers.clear();
      _navStepsExpanded = false;
      _filterToRouteOnly = false;
      _activeRouteShortNames = {};
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _debounce?.cancel();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _loadingSuggestions = false;
      _destinationMarker = null;
      _destName = null;
      _destLat = null;
      _destLng = null;
      _activeRoute = null;
      _polylines.clear();
      _stopMarkers.clear();
      _navStepsExpanded = false;
      _filterToRouteOnly = false;
      _activeRouteShortNames = {};
    });
  }

  Future<void> _updateMarkers(List<Map<String, dynamic>> vehicles) async {
    _lastVehicles = vehicles;
    final newMarkers = <Marker>{};
    for (final v in vehicles) {
      final vehicleId = v['vehicleId'] as String;
      final routeId = (v['routeId'] as String?) ?? '?';
      final shortName = RoutesLookup.instance.shortName(routeId);
      final lat = (v['lat'] as num).toDouble();
      final lng = (v['lng'] as num).toDouble();

      // Skip vehicles not on the active route when filter is enabled
      if (_filterToRouteOnly &&
          _activeRouteShortNames.isNotEmpty &&
          !_activeRouteShortNames.contains(shortName)) {
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
    if (_destinationMarker != null) newMarkers.add(_destinationMarker!);
    newMarkers.addAll(_stopMarkers);
    if (mounted) setState(() => _markers..clear()..addAll(newMarkers));
  }

  void _showAccountMenu(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountMenuSheet(
        auth: auth,
        onLogin: () {
          Navigator.of(context).pop();
          context.push('/login');
        },
        onRegister: () {
          Navigator.of(context).pop();
          context.push('/register');
        },
        onAccount: () {
          Navigator.of(context).pop();
          context.push('/account');
        },
        onLogout: () async {
          Navigator.of(context).pop();
          await ref.read(authProvider.notifier).logout();
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
            mapType: MapType.normal,
            myLocationEnabled: hasLocation,
            myLocationButtonEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              c.setMapStyle(_mapStyle);
            },
            onTap: (_) {
              _searchFocus.unfocus();
              setState(() {
                _showSuggestions = false;
                _tappedVehicle = null;
              });
            },
          ),

          // Search bar
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 68, // leave room for the profile button
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(28),
              color: Colors.transparent,
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search destination...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: _loadingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white54),
                          ),
                        )
                      : const Icon(Icons.search, color: Colors.white54, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white38, size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xE6122340),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  if (_suggestions.isNotEmpty) _selectSuggestion(_suggestions.first);
                },
              ),
            ),
          ),

          // Profile / account button (top-right, beside search bar)
          Positioned(
            top: topPad + 12,
            right: 16,
            child: _ProfileButton(
              onTap: () => _showAccountMenu(context, ref),
            ),
          ),

          // Autocomplete dropdown — separate Positioned so it's never clipped
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: topPad + 12 + 52 + 6, // below search bar
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xF2122340),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _suggestions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _selectSuggestion(s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              child: Row(
                                children: [
                                  const Icon(Icons.place_outlined,
                                      color: Color(0xFF7FDBFF), size: 18),
                                  const SizedBox(width: 12),
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
                                              fontWeight: FontWeight.w500),
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
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (i < _suggestions.length - 1)
                            const Divider(height: 1, color: Colors.white10),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Weather chip — below search bar, left-aligned
          Positioned(
            top: topPad + 12 + 52 + 10,
            left: 16,
            child: (_showSuggestions || _tappedVehicle != null)
                ? const SizedBox.shrink()
                : const WeatherChip(),
          ),

          // Vehicle info card — shown when a bus marker is tapped
          if (_tappedVehicle != null && !_showSuggestions)
            Positioned(
              top: topPad + 12 + 52 + 10,
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

          // Active navigation panel
          if (_activeRoute != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ActiveRoutePanel(
                route: _activeRoute!,
                destName: _destName ?? 'Destination',
                expanded: _navStepsExpanded,
                filterActive: _filterToRouteOnly,
                onToggleExpand: () =>
                    setState(() => _navStepsExpanded = !_navStepsExpanded),
                onToggleFilter: () {
                  setState(() => _filterToRouteOnly = !_filterToRouteOnly);
                  _updateMarkers(_lastVehicles);
                },
                onCancel: _cancelNavigation,
              ),
            ),

          // Map controls — zoom + my location (top-right, below profile button)
          Positioned(
            top: topPad + 12 + 52 + 10,
            right: 16,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
                const SizedBox(height: 8),
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
  final bool expanded;
  final bool filterActive;
  final VoidCallback onToggleExpand;
  final VoidCallback onToggleFilter;
  final VoidCallback onCancel;

  const _ActiveRoutePanel({
    required this.route,
    required this.destName,
    required this.expanded,
    required this.filterActive,
    required this.onToggleExpand,
    required this.onToggleFilter,
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
                const Icon(Icons.navigation,
                    color: Color(0xFF7FDBFF), size: 20),
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
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Pills summary (horizontal scroll)
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _buildMiniPills(merged),
                    ),
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
                    child: const Icon(Icons.close,
                        color: Colors.white54, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // Filter toggle chip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: GestureDetector(
              onTap: onToggleFilter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: filterActive
                      ? const Color(0xFF7FDBFF)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filterActive
                          ? Icons.directions_bus
                          : Icons.directions_bus_outlined,
                      size: 15,
                      color: filterActive
                          ? const Color(0xFF0D1B2A)
                          : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filterActive
                          ? 'Showing route buses only'
                          : 'Show route buses only',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: filterActive
                            ? const Color(0xFF0D1B2A)
                            : Colors.white54,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      filterActive
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color: filterActive
                          ? const Color(0xFF0D1B2A)
                          : Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded steps
          if (expanded) ...[
            const Divider(height: 1, color: Colors.white10),
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
            color: const Color(0xFF0F4C81),
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
            decoration: const BoxDecoration(
                color: Color(0xFF0F4C81), shape: BoxShape.circle),
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
                        color: const Color(0xFF0F4C81),
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

// ─── Map Control Button ───────────────────────────────────────────────────────

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _MapControlButton(
      {required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xE6122340),
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 20),
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
        ? auth.displayName
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xE6122340),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
        ),
        child: Center(
          child: initials != null
              ? Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF7FDBFF),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(Icons.person_outline,
                  color: Colors.white54, size: 22),
        ),
      ),
    );
  }
}

// ─── Account Menu Sheet ───────────────────────────────────────────────────────

class _AccountMenuSheet extends StatelessWidget {
  final AuthState auth;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onAccount;
  final VoidCallback onLogout;

  const _AccountMenuSheet({
    required this.auth,
    required this.onLogin,
    required this.onRegister,
    required this.onAccount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

          if (auth.isLoggedIn) ...[
            // Logged-in header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF0F4C81),
                    child: Text(
                      auth.displayName.isNotEmpty
                          ? auth.displayName
                              .trim()
                              .split(' ')
                              .take(2)
                              .map((w) => w[0].toUpperCase())
                              .join()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFF7FDBFF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text(auth.email,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            _MenuItem(
              icon: Icons.manage_accounts_outlined,
              label: 'My Account',
              onTap: onAccount,
            ),
            const Divider(height: 1, color: Colors.white10),
            _MenuItem(
              icon: Icons.logout,
              label: 'Sign Out',
              color: Colors.redAccent,
              onTap: onLogout,
            ),
          ] else ...[
            // Guest header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF122340),
                    child: Icon(Icons.person_outline,
                        color: Colors.white38, size: 24),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guest',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text('Sign in to save routes',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            _MenuItem(
              icon: Icons.login,
              label: 'Sign In',
              color: const Color(0xFF7FDBFF),
              onTap: onLogin,
            ),
            const Divider(height: 1, color: Colors.white10),
            _MenuItem(
              icon: Icons.person_add_outlined,
              label: 'Create Account',
              onTap: onRegister,
            ),
          ],

          const SizedBox(height: 16),
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

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

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
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withOpacity(0.4), size: 20),
          ],
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
                      'On time',
                      'Slight',
                      'Moderate',
                      'Late',
                      'Very late'
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
  final int value; // 0 = unset, 1–5 = selected
  final ValueChanged<int> onChanged;

  const _RatingRow({
    required this.emoji,
    required this.label,
    required this.sublabels,
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
                        '$level',
                        style: TextStyle(
                          color: filled ? Colors.white : Colors.white38,
                          fontWeight: filled
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        // Scale hint
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
