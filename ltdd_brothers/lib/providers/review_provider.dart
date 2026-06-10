import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider with ChangeNotifier {
  // Danh sách đánh giá của chính người dùng (tải từ MySQL qua API)
  List<ReviewModel> _myReviews = [];
  bool _isLoading = false;

  List<ReviewModel> get myReviews => _myReviews;
  bool get isLoading => _isLoading;

  // Tải danh sách đánh giá của người dùng từ backend
  Future<void> loadMyReviews(String userId) async {
    if (userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      _myReviews = await ReviewService.fetchByUser(userId);
    } catch (e) {
      debugPrint('Lỗi tải đánh giá của tôi: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // Gửi một đánh giá mới lên backend, sau đó tải lại danh sách
  Future<bool> submitReview({
    required int locationId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final ok = await ReviewService.createReview(
      locationId: locationId,
      userId: userId,
      rating: rating,
      comment: comment,
    );
    if (ok) {
      await loadMyReviews(userId);
    }
    return ok;
  }
}
