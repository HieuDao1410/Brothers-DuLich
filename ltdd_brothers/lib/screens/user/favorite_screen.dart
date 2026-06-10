import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorite_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/location_placeholder.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final favoriteItems = favoriteProvider.favoriteLocations;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: Text('Địa điểm yêu thích', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.bg(context),
        iconTheme: IconThemeData(color: AppColors.text(context)),
        elevation: 0,
      ),
      body: favoriteItems.isEmpty
          ? Center(child: Text("Danh sách yêu thích trống", style: TextStyle(color: AppColors.textMuted(context), fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                final location = favoriteItems[index];
                return Card(
                  color: AppColors.surface(context),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 80, height: 80,
                        child: location.imageUrl.isEmpty
                            ? LocationPlaceholder(category: location.category, name: location.name)
                            : Image.network(ApiService.fullImageUrl(location.imageUrl), headers: const {'User-Agent': 'ltdd_brothers/1.0'}, fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => LocationPlaceholder(category: location.category, name: location.name)),
                      ),
                    ),
                    title: Text(location.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(context))),
                    subtitle: Text('${location.province}\n⭐ ${location.rating}', style: TextStyle(color: AppColors.textMuted(context))),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                      onPressed: () {
                        favoriteProvider.toggleFavorite(location);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa khỏi danh sách yêu thích'), backgroundColor: Colors.redAccent),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
