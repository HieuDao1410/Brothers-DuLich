import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/favorite_provider.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  void initState() {
    super.initState();
    // Tự động fetch dữ liệu yêu thích từ Server khi vừa mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoriteProvider>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa điểm yêu thích'),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          // 1. Đang tải dữ liệu
          if (favoriteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = favoriteProvider.favoriteLocations;

          // 2. Nếu danh sách trống
          if (favorites.isEmpty) {
            return const Center(
              child: Text('Bạn chưa có địa điểm yêu thích nào.'),
            );
          }

          // 3. Hiển thị danh sách
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final location = favorites[index];
              return ListTile(
                leading: location.imageUrl.isNotEmpty
                    ? Image.network(location.imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 60),
                title: Text(location.name),
                subtitle: Text('${location.province} • ⭐ ${location.rating}'),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    // Bấm vào tim ở đây sẽ xóa khỏi danh sách yêu thích
                    favoriteProvider.toggleFavorite(location);
                  },
                ),
                onTap: () {
                  // Bấm vào item thì chuyển sang màn hình chi tiết
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(location: location),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}