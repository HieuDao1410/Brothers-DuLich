import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class FavoriteService {
  // Thay đổi baseUrl phù hợp với cấu hình máy/emulator của bạn (VD: http://10.0.2.2:5000/api)
  final String baseUrl = "http://10.0.2.2:5000/api/Favorites";

  // Lấy danh sách địa danh yêu thích của một cơ sở dữ liệu trung tâm
  Future<List<LocationModel>> getFavorites(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/$userId'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => LocationModel.fromJson(item)).toList();
    } else {
      throw Exception("Không thể tải danh sách địa danh yêu thích");
    }
  }

  // Thêm hoặc bỏ yêu thích (Toggle)
  Future<bool> toggleFavorite(String userId, int locationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/toggle'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "locationId": locationId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['isFavorite'] as bool; // Trả về trạng thái hiện tại sau khi bấm
    } else {
      throw Exception("Lỗi xử lý yêu thích địa danh");
    }
  }
}