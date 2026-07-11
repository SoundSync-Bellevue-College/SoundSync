import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';

const _mapsApiKey = googleMapsMobileKey;

// Seattle centre — used to bias autocomplete results
const _biaslat = 47.6062;
const _biaslng = -122.3321;

class GeocodingResult {
  final String formattedAddress;
  final double lat;
  final double lng;
  const GeocodingResult(this.formattedAddress, this.lat, this.lng);
}

class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  const PlaceSuggestion(this.placeId, this.mainText, this.secondaryText);
}

class GeocodingService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://maps.googleapis.com/maps/api',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Returns up to 5 autocomplete suggestions for [input].
  static Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (input.trim().isEmpty) return [];
    try {
      final resp = await _dio.get('/place/autocomplete/json', queryParameters: {
        'input': input,
        'key': _mapsApiKey,
        'location': '$_biaslat,$_biaslng',
        'radius': 50000,
        'components': 'country:us',
      });

      final status = resp.data['status'] as String? ?? 'NO_STATUS';
      final errorMsg = resp.data['error_message'] as String? ?? '';
      debugPrint('[Places] key_len=${_mapsApiKey.length} status=$status error=$errorMsg');

      if (status != 'OK') return [];

      final predictions = resp.data['predictions'] as List<dynamic>;
      return predictions.map((p) {
        final sf = p['structured_formatting'] as Map<String, dynamic>;
        return PlaceSuggestion(
          p['place_id'] as String,
          sf['main_text'] as String? ?? '',
          sf['secondary_text'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('[Places] autocomplete error: $e');
      return [];
    }
  }

  /// Geocodes a free-text [address] to coordinates.
  static Future<GeocodingResult?> geocode(String address) async {
    try {
      final resp = await _dio.get('/geocode/json', queryParameters: {
        'address': address,
        'key': _mapsApiKey,
        'components': 'country:us',
      });
      if (resp.data['status'] != 'OK') return null;
      final result = (resp.data['results'] as List).first as Map<String, dynamic>;
      final loc = result['geometry']['location'] as Map<String, dynamic>;
      return GeocodingResult(
        result['formatted_address'] as String,
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolves a [placeId] to coordinates + formatted address.
  static Future<GeocodingResult?> placeDetails(String placeId) async {
    try {
      final resp = await _dio.get('/place/details/json', queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,formatted_address',
        'key': _mapsApiKey,
      });

      final result = resp.data['result'] as Map<String, dynamic>;
      final loc = result['geometry']['location'] as Map<String, dynamic>;
      return GeocodingResult(
        result['formatted_address'] as String,
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
