import 'package:flutter/material.dart';

// Khung minh hoạ trung tính khi địa điểm CHƯA có ảnh thật.
// Nền màu (theo tên) + icon theo loại + tên -> không bao giờ hiển thị ảnh sai, không để trống.
class LocationPlaceholder extends StatelessWidget {
  final String category;
  final String name;

  const LocationPlaceholder({Key? key, required this.category, required this.name}) : super(key: key);

  static const List<List<Color>> _palettes = [
    [Color(0xFF00AA6C), Color(0xFF00734A)],
    [Color(0xFF2E86DE), Color(0xFF1B4F9C)],
    [Color(0xFFE17055), Color(0xFFB23A24)],
    [Color(0xFF8E44AD), Color(0xFF5B2C6F)],
    [Color(0xFF16A085), Color(0xFF0E6655)],
    [Color(0xFFE67E22), Color(0xFFB9770E)],
    [Color(0xFF34495E), Color(0xFF1A252F)],
  ];

  IconData _icon() {
    switch (category) {
      case 'Khách sạn':
        return Icons.hotel;
      case 'Ăn uống':
      case 'Nhà hàng':
        return Icons.restaurant;
      case 'Tham quan':
        return Icons.photo_camera_back;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[name.hashCode.abs() % _palettes.length];
    return LayoutBuilder(
      builder: (context, c) {
        // Khu vực lớn (ảnh chi tiết / thẻ to) thì hiện thêm tên; thumbnail nhỏ chỉ hiện icon
        final big = c.maxHeight >= 110;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icon(), color: Colors.white, size: big ? 46 : 28),
              if (big) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
