import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class ApiService {
  // Dùng 10.0.2.2 thay cho localhost nếu bạn chạy máy ảo Android (Emulator)
  static const String baseUrl = 'http://10.0.2.2:5144/api';

  // Gốc server (không có /api) để ghép đường dẫn ảnh tĩnh
  static const String serverRoot = 'http://10.0.2.2:5144';

  // Chuyển đường dẫn ảnh tương đối (/images/x.jpg) thành URL đầy đủ
  static String fullImageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$serverRoot$url';
  }

  // GET: Lấy toàn bộ địa danh
  static Future<List<LocationModel>> fetchLocations() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Locations'));

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => LocationModel.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi load dữ liệu');
      }
    } catch (e) {
      throw Exception('Không thể kết nối Server: $e');
    }
  }

  // POST: Thêm địa danh mới (gửi multipart, có thể kèm ảnh)
  static Future<bool> createLocation({
    required String name,
    required String category,
    required String province,
    required String description,
    required double latitude,
    required double longitude,
    String? imagePath,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/Locations'));
    _fillLocationFields(request, name, category, province, description, latitude, longitude);
    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('Image', imagePath));
    }
    final streamed = await request.send();
    return streamed.statusCode == 200 || streamed.statusCode == 201;
  }

  // PUT: Cập nhật địa danh (ảnh tùy chọn — không gửi thì giữ ảnh cũ)
  static Future<bool> updateLocation({
    required int id,
    required String name,
    required String category,
    required String province,
    required String description,
    required double latitude,
    required double longitude,
    String? imagePath,
  }) async {
    final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/Locations/$id'));
    _fillLocationFields(request, name, category, province, description, latitude, longitude);
    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('Image', imagePath));
    }
    final streamed = await request.send();
    return streamed.statusCode == 200;
  }

  // DELETE: Xóa địa danh
  static Future<bool> deleteLocation(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/Locations/$id'));
    return response.statusCode == 200;
  }

  // Lấy thông tin 1 user theo UID
  static Future<Map<String, dynamic>?> fetchUser(String uid) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/Users/$uid'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // Cập nhật họ tên hồ sơ cá nhân
  static Future<bool> updateUserProfile(String uid, String fullName) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Users/$uid/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fullName': fullName}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static void _fillLocationFields(
    http.MultipartRequest request,
    String name,
    String category,
    String province,
    String description,
    double latitude,
    double longitude,
  ) {
    request.fields['Name'] = name;
    request.fields['Category'] = category;
    request.fields['Province'] = province;
    request.fields['Description'] = description;
    request.fields['Latitude'] = latitude.toString();
    request.fields['Longitude'] = longitude.toString();
  }
}
