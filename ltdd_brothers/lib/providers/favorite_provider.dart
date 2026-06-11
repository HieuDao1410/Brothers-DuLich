import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tự động lấy user ID
import '../models/location_model.dart';
import '../services/favorite_service.dart';

class FavoriteProvider with ChangeNotifier {
  final FavoriteService _favoriteService = FavoriteService();
  List<LocationModel> _favoriteLocations = [];
  bool _isLoading = false;

  List<LocationModel> get favoriteLocations => _favoriteLocations;
  bool get isLoading => _isLoading;

  // Tự động lấy UID của người dùng đang đăng nhập
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Gọi danh sách từ API Server khi app khởi động
  Future<void> loadFavorites() async {
    final uid = _uid;
    if (uid.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _favoriteLocations = await _favoriteService.getFavorites(uid);
    } catch (e) {
      debugPrint("Lỗi loadFavorites: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Giữ nguyên tên hàm 'toggleFavorite' và chỉ 1 tham số để KHÔNG LÀM LỖI UI cũ!
  Future<void> toggleFavorite(LocationModel location) async {
    final uid = _uid;
    if (uid.isEmpty) {
      debugPrint("Chưa đăng nhập, không thể thả tim");
      return;
    }

    final exists = isFavorite(location.id);

    // 1. Cập nhật giao diện ngay lập tức cho mượt mà (Không phải chờ mạng)
    if (exists) {
      _favoriteLocations.removeWhere((item) => item.id == location.id);
    } else {
      _favoriteLocations.add(location);
    }
    notifyListeners();

    // 2. Gửi request ngầm đồng bộ lên Server
    try {
      await _favoriteService.toggleFavorite(uid, location);
    } catch (e) {
      debugPrint("Lỗi đồng bộ thả tim lên server: $e");
      // Nếu server lỗi mạng, hoàn tác (rollback) lại giao diện
      if (exists) {
        _favoriteLocations.add(location);
      } else {
        _favoriteLocations.removeWhere((item) => item.id == location.id);
      }
      notifyListeners();
    }
  }

  // Kiểm tra địa danh hiện tại có nằm trong danh sách yêu thích không
  bool isFavorite(int locationId) {
    return _favoriteLocations.any((item) => item.id == locationId);
  }
}