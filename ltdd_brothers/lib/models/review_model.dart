class ReviewModel {
  final int id;
  final int locationId;
  final String? locationName; // Tên địa danh (dùng cho màn "Đánh giá của tôi" / Admin)
  final String userId;
  final String userName; // Tên người bình luận
  final String userAvatar;
  final double rating; // Số sao (1.0 đến 5.0)
  final String comment;
  final String createdAt; // Thời gian bình luận

  ReviewModel({
    required this.id,
    required this.locationId,
    this.locationName,
    this.userId = '',
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      // Backend ASP.NET trả về 'reviewId'; vẫn nhận 'id' để tương thích
      id: json['reviewId'] ?? json['id'] ?? 0,
      locationId: json['locationId'] ?? 0,
      locationName: json['locationName'],
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Người dùng ẩn danh',
      userAvatar: json['userAvatar'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: _formatDate(json['createdAt']),
    );
    
  }

  // Đóng gói dữ liệu gửi lên API khi viết đánh giá mới
  Map<String, dynamic> toCreateJson() {
    return {
      'locationId': locationId,
      'userId': userId,
      'rating': rating.toInt(),
      'comment': comment,
    };
  }

  // Chuyển chuỗi ISO DateTime của backend thành dạng dd/MM/yyyy HH:mm dễ đọc
  static String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString();
    final dt = DateTime.tryParse(str);
    if (dt == null) return str;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
