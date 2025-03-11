import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../domain/location_model.dart';
import 'map_service.dart';
import 'directions_service.dart';

// Provider for the MapService
final mapServiceProvider = Provider<MapService>((ref) {
  return MapService();
});

// Provider for the DirectionsService
final directionsServiceProvider = Provider<DirectionsService>((ref) {
  return DirectionsService();
});

// State class for the map
class MapState {
  final LocationModel? currentLocation;
  final LocationModel? selectedLocation;
  final List<LatLng> routePoints;
  final bool isLoading;
  final String? error;

  MapState({
    this.currentLocation,
    this.selectedLocation,
    this.routePoints = const [],
    this.isLoading = false,
    this.error,
  });

  MapState copyWith({
    LocationModel? currentLocation,
    LocationModel? selectedLocation,
    List<LatLng>? routePoints,
    bool? isLoading,
    String? error,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      routePoints: routePoints ?? this.routePoints,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier for the map state
class MapNotifier extends StateNotifier<MapState> {
  final MapService _mapService;
  final DirectionsService _directionsService;

  MapNotifier(this._mapService, this._directionsService) : super(MapState());
  // Initialize the map with current location
  Future<void> initializeMap() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentLocation = await _mapService.getCurrentLocation();

      if (currentLocation == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not get current location',
        );
        return;
      }

      state = state.copyWith(
        currentLocation: currentLocation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error initializing map: $e',
      );
    }
  }

  // Handle tap on map
  Future<void> onMapTap(LatLng tappedPoint) async {
    if (state.currentLocation == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final distance = _mapService.calculateDistance(
        state.currentLocation!.position,
        tappedPoint,
      );
      final selectedLocation = LocationModel(
        position: tappedPoint,
        name: 'Selected Location',
        distance: distance,
      );
      // Get route between current location and tapped point
      final routePoints = await _directionsService.getRouteCoordinates(
        state.currentLocation!.position,
        tappedPoint,
      );
      state = state.copyWith(
        selectedLocation: selectedLocation,
        routePoints: routePoints,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error getting route: $e',
        isLoading: false,
      );
    }
  }

  // Refresh current location
  Future<void> refreshLocation() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentLocation = await _mapService.getCurrentLocation();

      if (currentLocation == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not get current location',
        );
        return;
      }

      // If there's a selected location, recalculate distance and route
      LocationModel? updatedSelectedLocation;
      List<LatLng>? updatedRoutePoints;

      if (state.selectedLocation != null) {
        final distance = _mapService.calculateDistance(
          currentLocation.position,
          state.selectedLocation!.position,
        );

        updatedSelectedLocation = state.selectedLocation!.copyWith(
          distance: distance,
        );

        // Update route
        updatedRoutePoints = await _directionsService.getRouteCoordinates(
          currentLocation.position,
          state.selectedLocation!.position,
        );
      }

      state = state.copyWith(
        currentLocation: currentLocation,
        selectedLocation: updatedSelectedLocation,
        routePoints: updatedRoutePoints,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error refreshing location: $e',
      );
    }
  }
}

// Provider for the map state
final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  final mapService = ref.watch(mapServiceProvider);
  final directionsService = ref.watch(directionsServiceProvider);
  return MapNotifier(mapService, directionsService);
});
