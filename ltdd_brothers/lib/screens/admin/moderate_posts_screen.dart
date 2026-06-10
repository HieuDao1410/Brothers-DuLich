import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/api_service.dart';
import '../../services/community_service.dart';
import '../../utils/app_colors.dart';

class ModeratePostsScreen extends StatefulWidget {
  const ModeratePostsScreen({Key? key}) : super(key: key);

  @override
  State<ModeratePostsScreen> createState() => _ModeratePostsScreenState();
}

class _ModeratePostsScreenState extends State<ModeratePostsScreen> {
  late Future<List<PostModel>> _future;

  @override
  void initState() {
    super.initState();
    // userId rỗng -> lấy toàn bộ bài đăng để kiểm duyệt
    _future = CommunityService.fetchFeed('');
  }

  void _reload() {
    setState(() => _future = CommunityService.fetchFeed(''));
  }

  Future<void> _confirmDelete(PostModel post) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Gỡ bỏ bài đăng?', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
          content: Text('Bạn có chắc muốn gỡ bài đăng vi phạm này? Hành động không thể hoàn tác.',
              style: TextStyle(color: AppColors.textMuted(context))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy', style: TextStyle(color: AppColors.text(context)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(context);
                final ok = await CommunityService.deletePost(post.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Đã gỡ bỏ bài đăng.' : 'Gỡ bỏ thất bại!'),
                  backgroundColor: ok ? Colors.redAccent : Colors.grey,
                ));
                if (ok) _reload();
              },
              child: const Text('Gỡ bỏ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Kiểm duyệt Bài đăng', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: Icon(Icons.refresh, color: AppColors.text(context)), onPressed: _reload)],
      ),
      body: FutureBuilder<List<PostModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)));
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(child: Text('Chưa có bài đăng nào để kiểm duyệt.', style: TextStyle(color: AppColors.textMuted(context))));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.green,
                        child: Text(post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(post.userName, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                      subtitle: Text(post.createdAt, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                    ),
                    if (post.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(post.content, style: TextStyle(color: AppColors.text(context), height: 1.4)),
                      ),
                    if (post.imageUrl.isNotEmpty)
                      ClipRRect(
                        child: Image.network(
                          ApiService.fullImageUrl(post.imageUrl),
                          headers: const {'User-Agent': 'ltdd_brothers/1.0'},
                          width: double.infinity, height: 160, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(height: 160, color: AppColors.surface2(context), child: Icon(Icons.broken_image, color: AppColors.textMuted(context))),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('❤ ${post.likesCount}   💬 ${post.commentsCount}', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                          OutlinedButton.icon(
                            onPressed: () => _confirmDelete(post),
                            icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.redAccent),
                            label: const Text('Gỡ bài', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
