import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class DirectionsService {
  // OpenRouteService API
  static const String _baseUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car';
  static const String _apiKey =
      '5b3ce3597851110001cf6248f7f5e6f0a4e94a6f9c9e3e1b8c0c9c5c'; // Free OpenRouteService API key

  Future<List<LatLng>> getRouteCoordinates(
      LatLng origin, LatLng destination) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': _apiKey,
        },
        body: json.encode({
          'coordinates': [
            [origin.longitude, origin.latitude],
            [destination.longitude, destination.latitude]
          ],
          'format': 'geojson'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract coordinates from GeoJSON
        final coordinates =
            data['features'][0]['geometry']['coordinates'] as List;

        // Convert to LatLng list
        return coordinates
            .map((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();
      } else {
        debugPrint(
            'Failed to fetch route: ${response.statusCode}, ${response.body}');
        // Return a straight line as fallback
        return [origin, destination];
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
      // Return a straight line as fallback
      return [origin, destination];
    }
  }
}
