import 'dart:convert';
import 'package:http/http.dart' as http;

// Gọi API đồng bộ lịch trình giữa SQLite cục bộ và Server trung tâm (MySQL).
class ScheduleService {
  static const String baseUrl = 'http://10.0.2.2:5144/api/Schedules';

  // Đẩy 1 lịch trình lên Server, trả về scheduleId (khóa trên Server) nếu thành công
  static Future<int?> create({
    required String userId,
    required String title,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'startDate': startDate,
          'endDate': endDate,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['scheduleId'];
      }
    } catch (e) {
      // Offline hoặc Server lỗi -> trả null để giữ trạng thái chưa đồng bộ
    }
    return null;
  }

  // Xóa lịch trình trên Server
  static Future<bool> delete(int serverId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$serverId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
