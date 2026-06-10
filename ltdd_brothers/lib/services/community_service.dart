import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class CommunityService {
  static const String baseUrl = 'http://10.0.2.2:5144/api/Posts';

  // News Feed (kèm userId hiện tại để biết bài nào đã like)
  static Future<List<PostModel>> fetchFeed(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl?userId=$userId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => PostModel.fromJson(e)).toList();
    }
    throw Exception('Không tải được bảng tin (mã ${response.statusCode})');
  }

  // Đăng bài (multipart, ảnh + check-in tùy chọn)
  static Future<bool> createPost({
    required String userId,
    required String content,
    int? locationId,
    String? imagePath,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
    request.fields['UserId'] = userId;
    request.fields['Content'] = content;
    if (locationId != null) request.fields['LocationId'] = locationId.toString();
    if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('Image', imagePath));
    }
    final streamed = await request.send();
    return streamed.statusCode == 200 || streamed.statusCode == 201;
  }

  // Bật/tắt thích, trả về {likesCount, isLiked}
  static Future<Map<String, dynamic>?> toggleLike(int postId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$postId/like'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  // Danh sách bình luận
  static Future<List<CommentModel>> fetchComments(int postId) async {
    final response = await http.get(Uri.parse('$baseUrl/$postId/comments'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => CommentModel.fromJson(e)).toList();
    }
    throw Exception('Không tải được bình luận');
  }

  // Thêm bình luận
  static Future<bool> addComment(int postId, String userId, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$postId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'content': content}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Xóa bài đăng (chủ bài / admin)
  static Future<bool> deletePost(int postId) async {
    final response = await http.delete(Uri.parse('$baseUrl/$postId'));
    return response.statusCode == 200;
  }
}
