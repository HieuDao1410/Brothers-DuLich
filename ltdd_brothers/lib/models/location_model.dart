class LocationModel {
  final int id;
  final String name;
  final String province;
  final String description;
  String imageUrl; // có thể gán lại sau khi lấy ảnh thật (vd Mapillary)
  final double rating;
  
  // Bổ sung các trường mới cho khớp với Database MySQL
  final String category;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.id,
    required this.name,
    required this.province,
    required this.description,
    required this.imageUrl,
    required this.rating,
    this.category = 'Địa danh',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  // HÀM DỊCH THUẬT: Từ JSON của Backend API thành Object Flutter
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      // Lưu ý: Tên key trong ngoặc vuông (vd: 'locationId') 
      // phải khớp chính xác với JSON API ASP.NET trả về (mặc định là viết thường chữ cái đầu)
      id: json['locationId'] ?? 0,
      name: json['name'] ?? 'Chưa cập nhật',
      province: json['province'] ?? 'Chưa cập nhật',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(), // Ép kiểu để đảm bảo luôn là số thập phân
      category: json['category'] ?? 'Địa danh',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}