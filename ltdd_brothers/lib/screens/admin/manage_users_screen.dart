import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/app_colors.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final String _apiUrl = "http://10.0.2.2:5144/api/Users";

  Future<List<dynamic>> _fetchUsers() async {
    final response = await http.get(Uri.parse(_apiUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi tải dữ liệu người dùng');
    }
  }

  Future<void> _toggleBanUser(String userId, bool isCurrentlyBanned) async {
    try {
      final response = await http.put(Uri.parse("$_apiUrl/$userId/toggle-ban"));
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isCurrentlyBanned ? 'Đã mở khóa tài khoản!' : 'Đã khóa tài khoản thành công!'),
            backgroundColor: isCurrentlyBanned ? Colors.green : Colors.redAccent,
          ));
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Quản lý Tài khoản', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: Icon(Icons.refresh, color: AppColors.text(context)), onPressed: () => setState(() {}))],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(child: Text('Chưa có người dùng nào.', style: TextStyle(color: AppColors.textMuted(context))));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isBanned = user['isBanned'] ?? false;
              final bool isAdmin = user['role'] == 'Admin';
              final String userId = user['userId'];
              final String displayName = user['fullName'] ?? 'Khách du lịch';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBanned ? Colors.red[900] : AppColors.surface2(context),
                    child: Icon(isBanned ? Icons.block : Icons.person, color: isBanned ? Colors.white : AppColors.text(context)),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            color: isBanned ? AppColors.textMuted(context) : AppColors.text(context),
                            fontWeight: FontWeight.bold,
                            decoration: isBanned ? TextDecoration.lineThrough : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.purple[700] : AppColors.surface2(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(user['role'] ?? 'User', style: TextStyle(color: isAdmin ? Colors.white : AppColors.text(context), fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  subtitle: Text(user['email'] ?? '', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                  trailing: PopupMenuButton<String>(
                    color: AppColors.surface(context),
                    icon: Icon(Icons.more_vert, color: AppColors.text(context)),
                    onSelected: (value) {
                      if (value == 'toggle_ban') {
                        _toggleBanUser(userId, isBanned);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'toggle_ban',
                        child: Text(
                          isBanned ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                          style: TextStyle(color: isBanned ? Colors.green : Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
