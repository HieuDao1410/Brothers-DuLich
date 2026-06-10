class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl; 
  final String role; 

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
  });

  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 'User',
    );
  }

  // Đóng gói dữ liệu gửi lên API (ví dụ khi cập nhật profile)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
    };
  }
}