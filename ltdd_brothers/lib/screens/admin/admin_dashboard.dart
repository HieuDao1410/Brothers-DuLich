import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';
import '../../utils/app_colors.dart';
import 'manage_locations_screen.dart';
import 'moderate_reviews_screen.dart';
import 'moderate_posts_screen.dart';
import 'manage_users_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const String _base = 'http://10.0.2.2:5144/api';
  int? _users, _locations, _reviews, _posts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<int?> _count(String path, {String? userIdQuery}) async {
    try {
      final uri = Uri.parse('$_base/$path');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) return data.length;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _count('Users'),
      _count('Locations'),
      _count('Reviews'),
      _count('Posts'),
    ]);
    if (!mounted) return;
    setState(() {
      _users = results[0];
      _locations = results[1];
      _reviews = results[2];
      _posts = results[3];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text('Quản trị Hệ thống', style: TextStyle(color: AppColors.text(context), fontSize: 24, fontWeight: FontWeight.w900)),
        centerTitle: false,
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: AppColors.text(context)), onPressed: _loadStats),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          )
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Tổng quan dữ liệu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Người dùng', _fmt(_users), Icons.people_alt, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Địa danh', _fmt(_locations), Icons.landscape, AppColors.green)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Đánh giá', _fmt(_reviews), Icons.star, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Bài đăng', _fmt(_posts), Icons.dynamic_feed, Colors.purpleAccent)),
              ],
            ),
            const SizedBox(height: 40),
            Text('Công cụ Quản lý', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
            const SizedBox(height: 16),
            _buildActionTile(context, Icons.edit_location_alt, 'Quản lý Địa danh', 'Xem, thêm, sửa hoặc xóa địa danh', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageLocationsScreen()));
            }),
            _buildActionTile(context, Icons.reviews, 'Kiểm duyệt Đánh giá', 'Xóa các đánh giá vi phạm', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ModerateReviewsScreen()));
            }),
            _buildActionTile(context, Icons.dynamic_feed, 'Kiểm duyệt Bài đăng', 'Gỡ các bài đăng vi phạm cộng đồng', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ModeratePostsScreen()));
            }),
            _buildActionTile(context, Icons.manage_accounts, 'Quản lý Tài khoản', 'Khóa/mở khóa tài khoản thành viên', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ManageUsersScreen()));
            }),
          ],
        ),
      ),
    );
  }

  String _fmt(int? v) => _loading ? '...' : (v?.toString() ?? '—');

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: AppColors.textMuted(context), fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: AppColors.surface(context),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.bg(context), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.text(context)),
        ),
        title: Text(title, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
        trailing: Icon(Icons.arrow_forward_ios, color: AppColors.textMuted(context), size: 16),
      ),
    );
  }
}
