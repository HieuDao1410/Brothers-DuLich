import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/map_style.dart';
import '../../models/location_model.dart';
import 'detail_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/location_service.dart';
import '../../utils/location_placeholder.dart';

class NearbyLocation {
  final LocationModel model;
  final LatLng coordinates;
  final String category;

  NearbyLocation({
    required this.model,
    required this.coordinates,
    required this.category,
  });
}

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({Key? key}) : super(key: key);

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  GoogleMapController? _mapController;
  final Color _tripGreen = const Color(0xFF00AA6C);
  final LocationService _locationService = LocationService();
  // Vị trí người dùng (mặc định TP.HCM, sẽ cập nhật theo GPS)
  LatLng _userLatLng = const LatLng(10.8016, 106.6304);

  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'Tất cả',
    'Địa danh',
    'Khách sạn',
    'Ăn uống',
  ];

  final TextEditingController _searchController = TextEditingController();

  List<NearbyLocation> _allNearbyPlaces = [];
  List<NearbyLocation> _filteredPlaces = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocationAndFetch();
  }

  String _getFullImageUrl(String url) {
    if (url.isEmpty) {
      return '';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'http://10.0.2.2:5144$url';
  }

  // Map danh mục giao diện -> 'type' của Google Places
  String _googleType() {
    switch (_categories[_selectedCategoryIndex]) {
      case 'Khách sạn':
        return 'lodging';
      case 'Ăn uống':
        return 'restaurant';
      default:
        return 'tourist_attraction';
    }
  }

  // Lấy vị trí GPS rồi tải địa điểm thật quanh đó
  Future<void> _initLocationAndFetch() async {
    final pos = await _locationService.getCurrentLocation();
    if (pos != null) {
      _userLatLng = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLng(_userLatLng));
    }
    await _fetchNearby();
  }

  // Gọi Google Places lấy địa điểm thật theo danh mục đang chọn
  Future<void> _fetchNearby() async {
    setState(() => _isLoading = true);
    try {
      final places = await _locationService.getNearbyPlaces(
        _userLatLng.latitude,
        _userLatLng.longitude,
        _googleType(),
      );

      if (!mounted) return;
      setState(() {
        _allNearbyPlaces = places
            .map((loc) => NearbyLocation(
                  model: loc,
                  category: _categories[_selectedCategoryIndex],
                  coordinates: LatLng(loc.latitude, loc.longitude),
                ))
            .toList();
        _filteredPlaces = _allNearbyPlaces;
        _isLoading = false;
      });
      _updateMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allNearbyPlaces = [];
        _filteredPlaces = [];
        _isLoading = false;
      });
      _updateMarkers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), duration: const Duration(seconds: 5)),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    String selectedCategory = _categories[_selectedCategoryIndex];

    setState(() {
      _filteredPlaces = _allNearbyPlaces.where((place) {
        final matchesCategory =
            selectedCategory == 'Tất cả' || place.category == selectedCategory;
        final matchesSearch = place.model.name.toLowerCase().contains(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });

    _updateMarkers();
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};
    for (var place in _filteredPlaces) {
      newMarkers.add(
        Marker(
          markerId: MarkerId(place.model.id.toString()),
          position: place.coordinates,
          infoWindow: InfoWindow(
            title: place.model.name,
            snippet: '⭐ ${place.model.rating} - ${place.model.province}',
            onTap: () => _navigateToDetail(place.model),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place.category == 'Khách sạn'
                ? BitmapDescriptor.hueOrange
                : place.category == 'Ăn uống'
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    setState(() {
      _markers = newMarkers;
    });
  }

  void _navigateToDetail(LocationModel location) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailScreen(location: location)),
    );
  }

  void _showSaveOptionsBottomSheet(
    BuildContext context,
    LocationModel location,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer2<FavoriteProvider, TripProvider>(
          builder: (context, favoriteProvider, tripProvider, child) {
            final isGlobalFav = favoriteProvider.isFavorite(location.id);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Lưu vào...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24),

                    ListTile(
                      leading: Icon(
                        isGlobalFav ? Icons.favorite : Icons.favorite_border,
                        color: isGlobalFav ? Colors.redAccent : Colors.white,
                      ),
                      title: const Text(
                        'Địa điểm yêu thích',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      trailing: isGlobalFav
                          ? const Icon(Icons.check, color: Color(0xFF00AA6C))
                          : null,
                      onTap: () {
                        favoriteProvider.toggleFavorite(location);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isGlobalFav
                                  ? 'Đã xóa khỏi Yêu thích'
                                  : 'Đã lưu vào Yêu thích',
                            ),
                            backgroundColor: isGlobalFav
                                ? Colors.redAccent
                                : const Color(0xFF00AA6C),
                          ),
                        );
                      },
                    ),

                    ...tripProvider.trips.map((trip) {
                      bool isSavedInTrip = trip.savedLocations.any(
                        (loc) => loc.id == location.id,
                      );
                      return ListTile(
                        leading: Icon(
                          Icons.public,
                          color: isSavedInTrip
                              ? const Color(0xFF00AA6C)
                              : Colors.white,
                        ),
                        title: Text(
                          trip.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        trailing: isSavedInTrip
                            ? const Icon(Icons.check, color: Color(0xFF00AA6C))
                            : null,
                        onTap: () {
                          if (isSavedInTrip) {
                            tripProvider.removeLocationFromTrip(
                              trip.id,
                              location.id,
                            );
                          } else {
                            tripProvider.saveLocationToTrip(trip.id, location);
                          }
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),

                    const Divider(color: Colors.white24),

                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.white),
                      title: const Text(
                        'Tạo chuyến đi mới',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLatLng,
                zoom: 13.5,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _mapController?.setMapStyle(MapStyle.darkStyle);
                _mapController?.animateCamera(CameraUpdate.newLatLng(_userLatLng));
              },
            ),

            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _applyFilters(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm địa điểm lân cận...',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedCategoryIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategoryIndex = index);
                            _fetchNearby();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: isSelected ? _tripGreen : Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? _tripGreen
                                    : Colors.grey[800]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _categories[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.grey[900],
                      onPressed: () {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(_userLatLng),
                        );
                      },
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),

                  SizedBox(
                    height: 124,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00AA6C),
                            ),
                          )
                        : _filteredPlaces.isEmpty
                        ? Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900]?.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                "Không tìm thấy địa điểm nào phù hợp!",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredPlaces.length,
                            itemBuilder: (context, index) {
                              final item = _filteredPlaces[index];

                              final favoriteProvider =
                                  Provider.of<FavoriteProvider>(context);
                              final tripProvider = Provider.of<TripProvider>(
                                context,
                              );

                              final bool isSavedGlobal = favoriteProvider
                                  .isFavorite(item.model.id);
                              final bool isSavedInAnyTrip = tripProvider.trips
                                  .any(
                                    (trip) => trip.savedLocations.any(
                                      (loc) => loc.id == item.model.id,
                                    ),
                                  );

                              final bool isFavorited =
                                  isSavedGlobal || isSavedInAnyTrip;

                              return GestureDetector(
                                onTap: () => _navigateToDetail(item.model),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  margin: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[900]?.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[800]!,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.grey[800],
                                            child: item.model.imageUrl.isEmpty
                                              ? LocationPlaceholder(category: item.category, name: item.model.name)
                                              : Image.network(
                                              _getFullImageUrl(item.model.imageUrl),
                                              headers: const {'User-Agent': 'ltdd_brothers/1.0'},
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF00AA6C),
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) =>
                                                  LocationPlaceholder(category: item.category, name: item.model.name),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item.model.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.model.province,
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.circle,
                                                    size: 12,
                                                    color: _tripGreen,
                                                  ),
                                                  Icon(
                                                    Icons.circle,
                                                    size: 12,
                                                    color: _tripGreen,
                                                  ),
                                                  Icon(
                                                    Icons.circle,
                                                    size: 12,
                                                    color: _tripGreen,
                                                  ),
                                                  Icon(
                                                    Icons.circle,
                                                    size: 12,
                                                    color: _tripGreen,
                                                  ),
                                                  const Icon(
                                                    Icons.circle_outlined,
                                                    size: 12,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${item.model.rating}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isFavorited
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isFavorited
                                                ? Colors.redAccent
                                                : Colors.white60,
                                          ),
                                          onPressed: () {
                                            _showSaveOptionsBottomSheet(
                                              context,
                                              item.model,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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