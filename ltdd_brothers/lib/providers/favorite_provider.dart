import 'package:flutter/material.dart';
import '../models/location_model.dart';

class FavoriteProvider with ChangeNotifier {
  // Danh sách lưu trữ các đối tượng địa điểm đã được thả tim toàn cục
  final List<LocationModel> _favoriteLocations = [];

  List<LocationModel> get favoriteLocations => _favoriteLocations;

  // Kiểm tra xem địa điểm đã được thả tim hay chưa
  bool isFavorite(int id) {
    return _favoriteLocations.any((loc) => loc.id == id);
  }

  // Hàm xử lý Thả tim / Bỏ thả tim
  void toggleFavorite(LocationModel location) {
    final exists = isFavorite(location.id);
    if (exists) {
      _favoriteLocations.removeWhere((loc) => loc.id == location.id);
    } else {
      _favoriteLocations.add(location);
    }
    // Lệnh quan trọng: Thông báo cho toàn bộ các màn hình khác cập nhật lại giao diện ngay lập tức
    notifyListeners();
  }
}