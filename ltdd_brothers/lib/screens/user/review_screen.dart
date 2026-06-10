import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/review_provider.dart';
import '../../utils/app_colors.dart';

// ============================================================================
// TAB ĐÁNH GIÁ — hiển thị các đánh giá thật của người dùng (từ MySQL)
// ============================================================================
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        Provider.of<ReviewProvider>(context, listen: false).loadMyReviews(uid);
      }
    });
  }

  void _promptOpenLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mở một địa danh ở tab Khám phá/Lân cận rồi chọn "Đánh giá" để viết.'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'Khách du lịch';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.black,
        onPressed: _promptOpenLocation,
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: Consumer<ReviewProvider>(
          builder: (context, reviewProvider, child) {
            final myReviews = reviewProvider.myReviews;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const SizedBox(height: 8),
                Text('Đánh giá', style: TextStyle(color: AppColors.text(context), fontSize: 36, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.green,
                      child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${myReviews.length} đánh giá', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Đánh giá của bạn', style: TextStyle(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                if (reviewProvider.isLoading)
                  const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator(color: AppColors.green)))
                else if (myReviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textMuted(context)),
                        const SizedBox(height: 12),
                        Text('Bạn chưa viết đánh giá nào', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Mở một địa danh và nhấn "Đánh giá".', style: TextStyle(color: AppColors.textMuted(context))),
                      ],
                    ),
                  )
                else
                  ...myReviews.map((review) => Container(
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
                                  child: Text(review.locationName ?? 'Địa danh #${review.locationId}',
                                      style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Text(review.createdAt, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: List.generate(5, (i) => Icon(
                                    i < review.rating.floor() ? Icons.star : Icons.star_border,
                                    size: 16, color: AppColors.green,
                                  )),
                            ),
                            const SizedBox(height: 8),
                            Text(review.comment, style: TextStyle(color: AppColors.textMuted(context), height: 1.5)),
                          ],
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// MÀN HÌNH VIẾT ĐÁNH GIÁ
// ============================================================================
class WriteReviewScreen extends StatefulWidget {
  final int locationId;

  const WriteReviewScreen({Key? key, required this.locationId}) : super(key: key);

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  double _currentRating = 0;
  bool _isSubmitting = false;

  void _submitReview() async {
    if (_currentRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn số sao!')));
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá!')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để viết đánh giá!')));
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await Provider.of<ReviewProvider>(context, listen: false).submitReview(
      locationId: widget.locationId,
      userId: user.uid,
      rating: _currentRating.toInt(),
      comment: _commentController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã đóng góp đánh giá!'), backgroundColor: AppColors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi đánh giá thất bại. Vui lòng thử lại!'), backgroundColor: Colors.redAccent),
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
        title: Text('Đánh giá trải nghiệm', style: TextStyle(color: AppColors.text(context), fontSize: 18)),
        actions: [
          _isSubmitting
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2)))
              : TextButton(
                  onPressed: _submitReview,
                  child: const Text('ĐĂNG', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Bạn đánh giá địa điểm này thế nào?', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 35,
                  icon: Icon(
                    index < _currentRating ? Icons.star : Icons.star_border,
                    color: index < _currentRating ? AppColors.green : AppColors.textMuted(context),
                  ),
                  onPressed: () => setState(() => _currentRating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(context))),
              child: TextField(
                controller: _commentController,
                maxLines: 8,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  hintText: 'Chia sẻ chi tiết về trải nghiệm của bạn tại đây...',
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
