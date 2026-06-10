import 'package:flutter/material.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../utils/app_colors.dart';

class ModerateReviewsScreen extends StatefulWidget {
  const ModerateReviewsScreen({Key? key}) : super(key: key);

  @override
  State<ModerateReviewsScreen> createState() => _ModerateReviewsScreenState();
}

class _ModerateReviewsScreenState extends State<ModerateReviewsScreen> {
  late Future<List<ReviewModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ReviewService.fetchAll();
  }

  void _reload() {
    setState(() {
      _future = ReviewService.fetchAll();
    });
  }

  Future<void> _confirmDelete(ReviewModel review) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Gỡ bỏ đánh giá?', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
          content: Text('Bạn có chắc muốn gỡ bỏ đánh giá vi phạm này không? Hành động không thể hoàn tác.',
              style: TextStyle(color: AppColors.textMuted(context))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy', style: TextStyle(color: AppColors.text(context)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.pop(context);
                final ok = await ReviewService.deleteReview(review.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Đã gỡ bỏ đánh giá.' : 'Gỡ bỏ thất bại!'),
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
        title: Text('Kiểm duyệt Đánh giá', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: Icon(Icons.refresh, color: AppColors.text(context)), onPressed: _reload)],
      ),
      body: FutureBuilder<List<ReviewModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)));
          }

          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return Center(child: Text('Chưa có đánh giá nào để kiểm duyệt.', style: TextStyle(color: AppColors.textMuted(context))));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 16, backgroundColor: AppColors.surface2(context), child: Icon(Icons.person, color: AppColors.textMuted(context), size: 16)),
                            const SizedBox(width: 8),
                            Text(review.userName, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(review.createdAt, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Tại: ', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                        Expanded(
                          child: Text(review.locationName ?? 'Địa danh #${review.locationId}',
                              style: TextStyle(color: AppColors.text(context), fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(5, (i) => Icon(Icons.circle, color: i < review.rating.floor() ? AppColors.green : AppColors.textMuted(context), size: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(review.comment.isEmpty ? '(Không có nội dung)' : review.comment, style: TextStyle(color: AppColors.text(context), fontSize: 14, height: 1.4)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _confirmDelete(review),
                          icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.redAccent),
                          label: const Text('Gỡ bỏ', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
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
