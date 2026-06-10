import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Quản lý chế độ giao diện Sáng/Tối toàn hệ thống, lưu lại bằng SharedPreferences
class ThemeProvider with ChangeNotifier {
  static const String _key = 'isDarkMode';
  bool _isDarkMode = true; // Mặc định nền tối

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Nạp lựa chọn đã lưu khi mở app
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_key) ?? true;
    notifyListeners();
  }

  // Bật/tắt chế độ tối và lưu lại
  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
