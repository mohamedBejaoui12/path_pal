import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pfe1/features/business/presentation/user_business_profile_screen.dart';
import 'package:pfe1/shared/theme/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/map_provider.dart';
import '../../business/domain/business_model.dart';
import '../../business/data/business_list_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({Key? key}) : super(key: key);
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  bool _locationPermissionChecked = false;
  String? _profileImageUrl;
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  BusinessModel? _selectedBusiness;

  @override
  void initState() {
    super.initState();
    // Initialize map with current location and fetch user profile
    Future.microtask(() async {
      await _checkLocationPermission();
      await _fetchUserProfile();
      ref.read(mapProvider.notifier).initializeMap();
      // Fetch all businesses
      ref.read(businessListProvider.notifier).fetchAllBusinesses();
    });

    // Add listener for real-time search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Debounce mechanism for search
  DateTime _lastSearchTime = DateTime.now();
  void _onSearchChanged() {
    final now = DateTime.now();
    if (now.difference(_lastSearchTime) > const Duration(milliseconds: 300)) {
      _lastSearchTime = now;
      if (_searchController.text.isNotEmpty) {
        _searchBusiness(_searchController.text);
      } else {
        ref.read(businessSearchProvider.notifier).searchBusinesses('');
      }
    }
  }

  // Fetch user profile to get the profile image URL
  Future<void> _fetchUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null && user.email != null) {
        final response = await _supabase
            .from('user')
            .select('profile_image_url')
            .eq('email', user.email!)
            .single();

        if (response != null && response['profile_image_url'] != null) {
          setState(() {
            _profileImageUrl = response['profile_image_url'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  // Search for places
  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Call the business search instead of the mock implementation
      await _searchBusiness(query);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for "$query"'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Search for businesses
  Future<void> _searchBusiness(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      await ref.read(businessSearchProvider.notifier).searchBusinesses(query);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching for "$query"'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Handle business selection
  void _onBusinessSelected(BusinessModel business) {
    setState(() {
      _selectedBusiness = business;
    });

    // Move map to business location
    if (business.latitude != null && business.longitude != null) {
      final businessLocation = LatLng(business.latitude!, business.longitude!);
      _mapController.move(businessLocation, 15.0);
    }

    // Clear search results
    _searchController.clear();
    ref.read(businessSearchProvider.notifier).searchBusinesses('');
  }

  Future<void> _checkLocationPermission() async {
    if (_locationPermissionChecked) return;

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Location services are disabled. Please enable them.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _locationPermissionChecked = true;
  }

  // Updated method to open external maps with only Google Maps
  Future<void> _openMapsWithDirections() async {
    final mapState = ref.read(mapProvider);

    if (mapState.currentLocation == null || mapState.selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentPos = mapState.currentLocation!.position;
    final destPos = mapState.selectedLocation!.position;

    // Directly launch Google Maps without showing options dialog
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${currentPos.latitude},${currentPos.longitude}&destination=${destPos.latitude},${destPos.longitude}&travelmode=driving';
    await _launchUrl(url);
  }

  // Add a floating action button to get directions to selected location
  Widget _buildDirectionsButton() {
    final mapState = ref.watch(mapProvider);

    // Only show the button if a location is selected and no business is selected
    if (mapState.selectedLocation == null || _selectedBusiness != null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        onPressed: () =>
            _showDirectionsPopup(mapState.selectedLocation!.position),
        backgroundColor: AppColors.primaryColor,
        tooltip: 'Get directions to selected location',
        child: const Icon(Icons.directions, color: Colors.white),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Navigate to business profile
  void _navigateToBusinessProfile(BusinessModel business) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserBusinessProfileScreen(
          businessId: business.id, // Changed from businessEmail to businessId
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final businessesState = ref.watch(businessListProvider);
    final businessSearchState = ref.watch(businessSearchProvider);
    final isDarkMode = ref.watch(themeProvider);

    // Get businesses for markers
    final businesses = businessesState.maybeWhen(
      data: (data) => data,
      orElse: () => <BusinessModel>[],
    );
    // Get search results
    final searchResults = businessSearchState.maybeWhen(
      data: (data) => data,
      orElse: () => <BusinessModel>[],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Map',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // Changed to white
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: () async {
              await _checkLocationPermission();
              ref.read(mapProvider.notifier).refreshLocation();
              if (mapState.currentLocation != null) {
                _mapController.move(
                  mapState.currentLocation!.position,
                  15.0,
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.currentLocation?.position ??
                  const LatLng(36.8065, 10.1815),
              initialZoom: 15.0,
              onTap: (_, point) {
                // When user taps on the map, set it as the selected location
                ref.read(mapProvider.notifier).onMapTap(point);

                // Show directions popup instead of snackbar
                _showDirectionsPopup(point);
              },
            ),
            children: [
              // Base map layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pfe1',
              ),
              // Markers layer
              MarkerLayer(
                markers: [
                  // Current location marker with user profile image
                  if (mapState.currentLocation != null)
                    Marker(
                      point: mapState.currentLocation!.position,
                      width: 80,
                      height: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImageUrl != null
                                  ? Image.network(
                                      _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                        Icons.location_on,
                                        color: Colors.blue,
                                        size: 32,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                      size: 32,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Text(
                              'My Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Selected location marker (enhanced)
                  if (mapState.selectedLocation != null)
                    Marker(
                      point: mapState.selectedLocation!.position,
                      width: 80,
                      height: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.place,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Selected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Add business markers
                  ...businesses
                      .where((business) =>
                          business.latitude != null &&
                          business.longitude != null)
                      .map(
                        (business) => Marker(
                          point:
                              LatLng(business.latitude!, business.longitude!),
                          width: 80,
                          height: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _navigateToBusinessProfile(business),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: business.imageUrl != null
                                        ? Image.network(
                                            business.imageUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                              Icons.business,
                                              color: AppColors.primaryColor,
                                              size: 32,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.business,
                                            color: AppColors.primaryColor,
                                            size: 32,
                                          ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _navigateToBusinessProfile(business),
                                child: Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 2,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    business.businessName.length > 15
                                        ? '${business.businessName.substring(0, 15)}...'
                                        : business.businessName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ],
          ),
          // Search bar with results
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search input field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for places, businesses...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.primaryColor),
                      suffixIcon: _isSearching
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(6),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(businessSearchProvider.notifier)
                                    .searchBusinesses('');
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onSubmitted: _searchPlace,
                  ),
                ),
                // Search results
                if (searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final business = searchResults[index];
                        return ListTile(
                          leading: business.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    business.imageUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(Icons.business,
                                          color: Colors.grey),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.business,
                                      color: Colors.grey),
                                ),
                          title: Text(
                            business.businessName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(business.email ?? 'No email'),
                          onTap: () => _onBusinessSelected(business),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Business details when selected
          if (_selectedBusiness != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _navigateToBusinessProfile(_selectedBusiness!),
                          child: _selectedBusiness!.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _selectedBusiness!.imageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.business,
                                          color: Colors.grey, size: 30),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.business,
                                      color: Colors.grey, size: 30),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _navigateToBusinessProfile(
                                    _selectedBusiness!),
                                child: Text(
                                  _selectedBusiness!.businessName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDarkMode
                                        ? Colors.white
                                        : AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedBusiness!.email ?? 'No email',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedBusiness = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedBusiness!.latitude != null &&
                            _selectedBusiness!.longitude != null &&
                            mapState.currentLocation != null) {
                          final url =
                              'https://www.google.com/maps/dir/?api=1&origin=${mapState.currentLocation!.position.latitude},${mapState.currentLocation!.position.longitude}&destination=${_selectedBusiness!.latitude},${_selectedBusiness!.longitude}&travelmode=driving';
                          _launchUrl(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Cannot get directions to this business'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions),
                          SizedBox(width: 8),
                          Text(
                            'Get Directions to Business',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Add the directions button inside the Stack
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} meters';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  // Show directions popup when a location is tapped
  void _showDirectionsPopup(LatLng point) {
    final mapState = ref.read(mapProvider);
    if (mapState.currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your current location is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isDarkMode = ref.read(themeProvider);

    // Show a bottom sheet instead of a dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.place,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Close button
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openMapsWithDirections();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions),
                  SizedBox(width: 8),
                  Text(
                    'Get Directions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
