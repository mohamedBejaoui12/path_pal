import 'package:latlong2/latlong.dart';

class LocationModel {
  final LatLng position;
  final String? name;
  final String? address;
  final double? distance; // Distance in meters

  LocationModel({
    required this.position,
    this.name,
    this.address,
    this.distance,
  });

  LocationModel copyWith({
    LatLng? position,
    String? name,
    String? address,
    double? distance,
  }) {
    return LocationModel(
      position: position ?? this.position,
      name: name ?? this.name,
      address: address ?? this.address,
      distance: distance ?? this.distance,
    );
  }
}