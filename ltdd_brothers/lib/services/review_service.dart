import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';

class ReviewService {
  // Dùng 10.0.2.2 thay cho localhost khi chạy máy ảo Android (Emulator)
  static const String baseUrl = 'http://10.0.2.2:5144/api/Reviews';

  // 1. Lấy danh sách đánh giá của 1 địa danh
  static Future<List<ReviewModel>> fetchByLocation(int locationId) async {
    final response = await http.get(Uri.parse('$baseUrl/location/$locationId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => ReviewModel.fromJson(e)).toList();
    }
    throw Exception('Không tải được đánh giá (mã ${response.statusCode})');
  }

  // 2. Lấy danh sách đánh giá do 1 người dùng viết
  static Future<List<ReviewModel>> fetchByUser(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => ReviewModel.fromJson(e)).toList();
    }
    throw Exception('Không tải được đánh giá của bạn (mã ${response.statusCode})');
  }

  // 3. Lấy toàn bộ đánh giá (dùng cho màn Kiểm duyệt của Admin)
  static Future<List<ReviewModel>> fetchAll() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => ReviewModel.fromJson(e)).toList();
    }
    throw Exception('Không tải được danh sách đánh giá (mã ${response.statusCode})');
  }

  // 4. Gửi một đánh giá mới
  static Future<bool> createReview({
    required int locationId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'locationId': locationId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 5. Admin gỡ bỏ một đánh giá
  static Future<bool> deleteReview(int reviewId) async {
    final response = await http.delete(Uri.parse('$baseUrl/$reviewId'));
    return response.statusCode == 200;
  }
}
