import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'providers/favorite_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/review_provider.dart';
import 'providers/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Nạp lựa chọn giao diện đã lưu trước khi chạy app
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FavoriteProvider()),
        ChangeNotifierProvider(create: (context) => TripProvider()),
        ChangeNotifierProvider(create: (context) => ReviewProvider()),
        ChangeNotifierProvider(create: (context) => themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe ThemeProvider để đổi giao diện ngay khi người dùng bật/tắt
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Ứng Dụng Du Lịch',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      // Giao diện Sáng
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00AA6C), brightness: Brightness.light),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      // Giao diện Tối
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00AA6C), brightness: Brightness.dark),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
