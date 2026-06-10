import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../services/community_service.dart';
import '../../utils/app_colors.dart';

class CommentsScreen extends StatefulWidget {
  final int postId;
  const CommentsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<CommentModel>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = CommunityService.fetchComments(widget.postId);
  }

  void _reload() {
    setState(() => _future = CommunityService.fetchComments(widget.postId));
  }

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();
    if (user == null || text.isEmpty) return;

    setState(() => _sending = true);
    final ok = await CommunityService.addComment(widget.postId, user.uid, text);
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      _controller.clear();
      FocusScope.of(context).unfocus();
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi bình luận thất bại!'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Bình luận', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<CommentModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.green));
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return Center(child: Text('Chưa có bình luận. Hãy là người đầu tiên!', style: TextStyle(color: AppColors.textMuted(context))));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 18, backgroundColor: AppColors.surface2(context), child: Icon(Icons.person, color: AppColors.textMuted(context), size: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(c.userName, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                                      Text(c.createdAt, style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c.content, style: TextStyle(color: AppColors.text(context), height: 1.4)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.surface(context), border: Border(top: BorderSide(color: AppColors.border(context)))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: AppColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'Viết bình luận...',
                        hintStyle: TextStyle(color: AppColors.textMuted(context)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  _sending
                      ? const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)))
                      : IconButton(icon: const Icon(Icons.send, color: AppColors.green), onPressed: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
