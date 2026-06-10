import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../services/api_service.dart';
import '../../services/community_service.dart';
import '../../utils/app_colors.dart';
import 'create_post_screen.dart';
import 'comments_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<PostModel> _posts = [];
  bool _isLoading = true;
  String _error = '';

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await CommunityService.fetchFeed(_uid);
      if (!mounted) return;
      setState(() {
        _posts = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được bảng tin';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(PostModel post) async {
    setState(() {
      post.isLiked = !post.isLiked;
      post.likesCount += post.isLiked ? 1 : -1;
    });
    final res = await CommunityService.toggleLike(post.id, _uid);
    if (res != null && mounted) {
      setState(() {
        post.likesCount = res['likesCount'] ?? post.likesCount;
        post.isLiked = res['isLiked'] ?? post.isLiked;
      });
    }
  }

  Future<void> _openCreatePost() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
    if (result == true) _loadFeed();
  }

  Future<void> _openComments(PostModel post) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => CommentsScreen(postId: post.id)));
    _loadFeed();
  }

  Future<void> _deletePost(PostModel post) async {
    final ok = await CommunityService.deletePost(post.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _posts.removeWhere((p) => p.id == post.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bài viết'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text('Cộng đồng', style: TextStyle(color: AppColors.text(context), fontSize: 28, fontWeight: FontWeight.w900)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.black,
        onPressed: _openCreatePost,
        child: const Icon(Icons.edit),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : _error.isNotEmpty
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.green,
                  onRefresh: _loadFeed,
                  child: _posts.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Icon(Icons.groups_outlined, size: 80, color: AppColors.textMuted(context)),
                            const SizedBox(height: 16),
                            Center(child: Text('Chưa có bài viết nào', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold))),
                            const SizedBox(height: 8),
                            Center(child: Text('Hãy chia sẻ hành trình đầu tiên!', style: TextStyle(color: AppColors.textMuted(context)))),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) => _buildPostCard(_posts[index]),
                        ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: AppColors.textMuted(context), size: 60),
          const SizedBox(height: 16),
          Text(_error, style: TextStyle(color: AppColors.text(context))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFeed,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Thử lại', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final bool isOwner = post.userId == _uid;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
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
            subtitle: Row(
              children: [
                Text(post.createdAt, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                if (post.locationName != null && post.locationName!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.place, color: AppColors.green, size: 12),
                  Flexible(child: Text(post.locationName!, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.green, fontSize: 12))),
                ],
              ],
            ),
            trailing: isOwner
                ? PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: AppColors.textMuted(context)),
                    color: AppColors.surface2(context),
                    onSelected: (v) {
                      if (v == 'delete') _deletePost(post);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          SizedBox(width: 8),
                          Text('Xóa bài', style: TextStyle(color: Colors.redAccent)),
                        ]),
                      ),
                    ],
                  )
                : null,
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(post.content, style: TextStyle(color: AppColors.text(context), fontSize: 15, height: 1.4)),
            ),
          if (post.imageUrl.isNotEmpty)
            Image.network(
              ApiService.fullImageUrl(post.imageUrl),
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(height: 200, color: AppColors.surface2(context), child: const Center(child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2)));
              },
              errorBuilder: (context, error, stack) =>
                  Container(height: 200, color: AppColors.surface2(context), child: Icon(Icons.broken_image, color: AppColors.textMuted(context))),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _toggleLike(post),
                  icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.redAccent : AppColors.textMuted(context), size: 20),
                  label: Text('${post.likesCount}', style: TextStyle(color: AppColors.textMuted(context))),
                ),
                TextButton.icon(
                  onPressed: () => _openComments(post),
                  icon: Icon(Icons.chat_bubble_outline, color: AppColors.textMuted(context), size: 20),
                  label: Text('${post.commentsCount}', style: TextStyle(color: AppColors.textMuted(context))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
