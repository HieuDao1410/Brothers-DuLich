import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/review_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../user/favorite_screen.dart';
import '../auth/login_screen.dart';

// 1. WIDGET GỐC CỦA TAB TÀI KHOẢN (Chứa Nested Navigator)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const ProfileMenuScreen(),
        );
      },
    );
  }
}

// 2. GIAO DIỆN MENU CHÍNH CỦA TAB TÀI KHOẢN
class ProfileMenuScreen extends StatelessWidget {
  const ProfileMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final reviewCount = reviewProvider.myReviews.length;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Khách du lịch';
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text('Tài khoản', style: TextStyle(color: AppColors.text(context), fontSize: 28, fontWeight: FontWeight.w900)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Thông tin người dùng thật (Firebase)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.green,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: TextStyle(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(email, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('$reviewCount đánh giá đã đóng góp', style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.border(context), height: 1),
            const SizedBox(height: 8),

            _buildMenuItem(context, Icons.favorite_border, 'Địa điểm yêu thích', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoriteScreen()));
            }),
            _buildMenuItem(context, Icons.rate_review_outlined, 'Đánh giá của tôi', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MyContributionsScreen()));
            }),
            _buildMenuItem(context, Icons.person_outline, 'Hồ sơ cá nhân', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
            }),
            _buildMenuItem(context, Icons.notifications_none, 'Thông báo', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
            }),
            _buildMenuItem(context, Icons.settings_outlined, 'Tùy chọn', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
            _buildMenuItem(context, Icons.help_outline, 'Hỗ trợ', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
            }),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OutlinedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.green, width: 1.5),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Đăng xuất', style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Phiên bản: v1.0.0', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, {required VoidCallback onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.text(context), size: 28),
          title: Text(title, style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
          trailing: Icon(Icons.arrow_forward_ios, color: AppColors.textMuted(context), size: 18),
          onTap: onTap,
        ),
        Divider(color: AppColors.border(context), height: 1, indent: 64, endIndent: 16),
      ],
    );
  }
}

// =====================================================================
// MÀN HÌNH ĐÓNG GÓP CỦA TÔI (dữ liệu thật từ MySQL)
// =====================================================================
class MyContributionsScreen extends StatefulWidget {
  const MyContributionsScreen({Key? key}) : super(key: key);

  @override
  State<MyContributionsScreen> createState() => _MyContributionsScreenState();
}

class _MyContributionsScreenState extends State<MyContributionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      Provider.of<ReviewProvider>(context, listen: false).loadMyReviews(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final myReviews = reviewProvider.myReviews;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Đánh giá của tôi', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      ),
      body: reviewProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : myReviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 80, color: AppColors.textMuted(context)),
                      const SizedBox(height: 16),
                      Text('Bạn chưa có đánh giá nào', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Hãy chia sẻ trải nghiệm của bạn\nvề các địa điểm đã ghé thăm.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted(context))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: myReviews.length,
                  itemBuilder: (context, index) {
                    final review = myReviews[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: AppColors.textMuted(context), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  review.locationName ?? 'Địa danh #${review.locationId}',
                                  style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(review.createdAt, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < review.rating.floor() ? Icons.star : Icons.star_border,
                                size: 16, color: AppColors.green,
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(review.comment, style: TextStyle(color: AppColors.textMuted(context), height: 1.5)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// =====================================================================
// HỒ SƠ CÁ NHÂN (thật - sửa & lưu họ tên)
// =====================================================================
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _email = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _email = user?.email ?? '';
    _nameController.text = user?.displayName ?? '';
    _loadFromBackend(user?.uid);
  }

  Future<void> _loadFromBackend(String? uid) async {
    if (uid == null) return;
    final data = await ApiService.fetchUser(uid);
    if (data != null && mounted) {
      setState(() {
        if ((_nameController.text).isEmpty) {
          _nameController.text = data['fullName'] ?? '';
        }
      });
    }
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    final name = _nameController.text.trim();
    if (user == null || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập họ tên!')));
      return;
    }

    setState(() => _saving = true);
    // Lưu lên MySQL + cập nhật tên hiển thị Firebase
    final ok = await ApiService.updateUserProfile(user.uid, name);
    try {
      await user.updateDisplayName(name);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã lưu hồ sơ!' : 'Lưu thất bại, kiểm tra Server!'),
        backgroundColor: ok ? AppColors.green : Colors.redAccent,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Hồ sơ cá nhân', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.green,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: TextStyle(color: AppColors.text(context)),
            decoration: InputDecoration(
              labelText: 'Họ và Tên',
              labelStyle: TextStyle(color: AppColors.textMuted(context)),
              filled: true,
              fillColor: AppColors.surface(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            enabled: false,
            controller: TextEditingController(text: _email),
            style: TextStyle(color: AppColors.textMuted(context)),
            decoration: InputDecoration(
              labelText: 'Email (không đổi được)',
              labelStyle: TextStyle(color: AppColors.textMuted(context)),
              filled: true,
              fillColor: AppColors.surface(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text('Lưu thay đổi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }
}

// =====================================================================
// THÔNG BÁO
// =====================================================================
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Thông báo', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: AppColors.surface(context),
            leading: const Icon(Icons.celebration, color: Colors.orange),
            title: Text('Chào mừng đến với hệ thống!', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
            subtitle: Text('Khám phá hàng ngàn địa điểm hấp dẫn ngay hôm nay.', style: TextStyle(color: AppColors.textMuted(context))),
          )
        ],
      ),
    );
  }
}

// =====================================================================
// TÙY CHỌN
// =====================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isGpsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Tùy chọn', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: Text('Giao diện Tối (Dark Mode)', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                subtitle: Text('Bật để dùng nền đen, tắt để dùng nền trắng', style: TextStyle(color: AppColors.textMuted(context))),
                value: themeProvider.isDarkMode,
                activeColor: AppColors.green,
                onChanged: (val) => themeProvider.setDarkMode(val),
              );
            },
          ),
          SwitchListTile(
            title: Text('Vị trí (GPS)', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
            subtitle: Text('Đề xuất địa điểm gần bạn', style: TextStyle(color: AppColors.textMuted(context))),
            value: _isGpsEnabled,
            activeColor: AppColors.green,
            onChanged: (val) => setState(() => _isGpsEnabled = val),
          ),
          Divider(color: AppColors.border(context), height: 32),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Xóa bộ nhớ đệm ảnh', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              imageCache.clear();
              imageCache.clearLiveImages();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa bộ nhớ đệm ảnh!'), backgroundColor: AppColors.green),
              );
            },
          )
        ],
      ),
    );
  }
}

// =====================================================================
// HỖ TRỢ
// =====================================================================
class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Hỗ trợ', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Chúng tôi có thể giúp gì cho bạn?', style: TextStyle(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildFaqItem(context, 'Cách thay đổi mật khẩu?'),
          _buildFaqItem(context, 'Làm sao để xóa bài đánh giá?'),
          _buildFaqItem(context, 'Cách tạo một Lịch trình mới?'),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: TextStyle(color: AppColors.text(context))),
        trailing: Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted(context)),
      ),
    );
  }
}
