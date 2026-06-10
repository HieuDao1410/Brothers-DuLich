class PostModel {
  final int id;
  final String userId;
  final String userName;
  final String userAvatar;
  final int? locationId;
  final String? locationName;
  final String content;
  final String imageUrl;
  int likesCount; // mutable để cập nhật nhanh khi like
  final int commentsCount;
  final String createdAt;
  bool isLiked;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    this.locationId,
    this.locationName,
    required this.content,
    required this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.isLiked,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['postId'] ?? 0,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Người dùng',
      userAvatar: json['userAvatar'] ?? '',
      locationId: json['locationId'],
      locationName: json['locationName'],
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      createdAt: _formatDate(json['createdAt']),
      isLiked: json['isLiked'] ?? false,
    );
  }

  static String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

class CommentModel {
  final int id;
  final String userId;
  final String userName;
  final String content;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['commentId'] ?? 0,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Người dùng',
      content: json['content'] ?? '',
      createdAt: PostModel._formatDate(json['createdAt']),
    );
  }
}
