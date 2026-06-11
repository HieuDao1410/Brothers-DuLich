import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'review_screen.dart';
import 'location_reviews_screen.dart';
import 'location_map_screen.dart';
import '../../models/location_model.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/location_placeholder.dart';

class DetailScreen extends StatefulWidget {
  final LocationModel location;

  const DetailScreen({Key? key, required this.location}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final Color _tripGreen = AppColors.green;

  void _showSaveOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer2<FavoriteProvider, TripProvider>(
          builder: (context, favoriteProvider, tripProvider, child) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Lưu vào...', style: TextStyle(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Divider(color: AppColors.border(context)),
                  ListTile(
                    leading: Icon(
                      favoriteProvider.isFavorite(widget.location.id) ? Icons.favorite : Icons.favorite_border,
                      color: favoriteProvider.isFavorite(widget.location.id) ? Colors.redAccent : AppColors.text(context),
                    ),
                    title: Text('Địa điểm yêu thích', style: TextStyle(color: AppColors.text(context))),
                    onTap: () {
                      favoriteProvider.toggleFavorite(widget.location);
                      Navigator.pop(context);
                    },
                  ),
                  ...tripProvider.trips.map((trip) {
                    bool isSaved = trip.savedLocations.any((loc) => loc.id == widget.location.id);
                    return ListTile(
                      leading: Icon(Icons.public, color: isSaved ? _tripGreen : AppColors.text(context)),
                      title: Text(trip.name, style: TextStyle(color: AppColors.text(context))),
                      trailing: isSaved ? const Icon(Icons.check, color: AppColors.green) : null,
                      onTap: () {
                        if (isSaved) {
                          tripProvider.removeLocationFromTrip(trip.id, widget.location.id);
                        } else {
                          tripProvider.saveLocationToTrip(trip.id, widget.location);
                        }
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                ],
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
      backgroundColor: AppColors.bg(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: AppColors.bg(context),
            actions: [

              Consumer2<FavoriteProvider, TripProvider>(
                builder: (context, favProv, tripProv, child) {
                  bool isSaved = favProv.isFavorite(widget.location.id) ||
                      tripProv.trips.any((t) => t.savedLocations.any((l) => l.id == widget.location.id));
                  return IconButton(
                    icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? Colors.redAccent : Colors.white),
                    onPressed: () => _showSaveOptions(context),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.location.imageUrl.isEmpty
                  ? LocationPlaceholder(category: widget.location.category, name: widget.location.name)
                  : Image.network(
                      ApiService.fullImageUrl(widget.location.imageUrl),
                      headers: const {'User-Agent': 'ltdd_brothers/1.0'},
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => LocationPlaceholder(category: widget.location.category, name: widget.location.name),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.location.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.text(context))),
                  const SizedBox(height: 8),
                  Text(widget.location.province, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textMuted(context))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(index < widget.location.rating.floor() ? Icons.star : Icons.star_border, size: 18, color: _tripGreen);
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text('${widget.location.rating}/5.0', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationReviewsScreen(
                              locationId: widget.location.id,
                              locationName: widget.location.name,
                            ),
                          ),
                        ),
                        child: Text('(Xem đánh giá)', style: TextStyle(color: AppColors.textMuted(context), fontSize: 14, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.rate_review_outlined, 'Đánh giá', onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => WriteReviewScreen(locationId: widget.location.id)));
                      }),
                      _buildActionButton(Icons.map_outlined, 'Bản đồ', onTap: () {
                        if (widget.location.latitude == 0 && widget.location.longitude == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Địa danh này chưa có tọa độ bản đồ.')),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LocationMapScreen(location: widget.location)),
                        );
                      }),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Divider(thickness: 1, color: AppColors.border(context)),
                  ),
                  Text('Giới thiệu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text(context))),
                  const SizedBox(height: 16),
                  Text(widget.location.description, style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.textMuted(context))),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _showSaveOptions(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _tripGreen,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Thêm vào Lịch trình', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.textMuted(context))),
            child: Icon(icon, size: 28, color: AppColors.text(context)),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text(context))),
        ],
      ),
    );
  }
}
