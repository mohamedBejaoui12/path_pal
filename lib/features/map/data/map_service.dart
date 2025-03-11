import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../domain/location_model.dart';

class MapService {
  // Check and request location permissions
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return false;
    }

    // Permissions are granted
    return true;
  }

  // Get current user location
  Future<LocationModel?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return LocationModel(
        position: LatLng(position.latitude, position.longitude),
        name: 'My Location',
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    final distance = const Distance().as(
      LengthUnit.Meter,
      point1,
      point2,
    );
    return distance;
  }
}