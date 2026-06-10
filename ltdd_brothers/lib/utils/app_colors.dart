import 'package:flutter/material.dart';

// Bộ màu trung tâm, tự đổi theo chế độ Sáng/Tối (dựa vào Theme.brightness).
// Dùng thay cho Colors.black/white/grey... cố định để hỗ trợ Light/Dark.
class AppColors {
  static bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

  // Nền chính (Scaffold, AppBar)
  static Color bg(BuildContext c) => isDark(c) ? Colors.black : Colors.white;

  // Nền thẻ/card, ô nhập
  static Color surface(BuildContext c) => isDark(c) ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F5);

  // Nền phụ (ảnh placeholder, chip)
  static Color surface2(BuildContext c) => isDark(c) ? const Color(0xFF2A2A2A) : const Color(0xFFE3E3E8);

  // Chữ chính
  static Color text(BuildContext c) => isDark(c) ? Colors.white : const Color(0xFF111111);

  // Chữ phụ / mờ
  static Color textMuted(BuildContext c) => isDark(c) ? Colors.grey : Colors.grey.shade600;

  // Viền
  static Color border(BuildContext c) => isDark(c) ? Colors.grey.shade800 : Colors.grey.shade300;

  // Màu nhấn cố định (xanh thương hiệu)
  static const Color green = Color(0xFF00AA6C);
}
