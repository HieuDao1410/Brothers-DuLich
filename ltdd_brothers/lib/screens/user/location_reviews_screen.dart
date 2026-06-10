import 'package:flutter/material.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../utils/app_colors.dart';
import 'review_screen.dart';

// Màn hình hiển thị toàn bộ đánh giá thật của một địa danh (lấy từ MySQL)
class LocationReviewsScreen extends StatefulWidget {
  final int locationId;
  final String locationName;

  const LocationReviewsScreen({
    Key? key,
    required this.locationId,
    required this.locationName,
  }) : super(key: key);

  @override
  State<LocationReviewsScreen> createState() => _LocationReviewsScreenState();
}

class _LocationReviewsScreenState extends State<LocationReviewsScreen> {
  late Future<List<ReviewModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ReviewService.fetchByLocation(widget.locationId);
  }

  void _reload() {
    setState(() {
      _future = ReviewService.fetchByLocation(widget.locationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Đánh giá', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<ReviewModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.green));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi tải đánh giá:\n${snapshot.error}',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            );
          }

          final reviews = snapshot.data ?? [];
          final double avg = reviews.isEmpty
              ? 0
              : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

          return RefreshIndicator(
            color: AppColors.green,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(widget.locationName, style: TextStyle(color: AppColors.text(context), fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(avg.toStringAsFixed(1), style: const TextStyle(color: AppColors.green, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(i < avg.round() ? Icons.star : Icons.star_border, color: AppColors.green, size: 18);
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text('${reviews.length} đánh giá', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                Divider(color: AppColors.border(context), height: 32),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textMuted(context)),
                        const SizedBox(height: 16),
                        Text('Chưa có đánh giá nào', style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Hãy là người đầu tiên chia sẻ trải nghiệm!', style: TextStyle(color: AppColors.textMuted(context))),
                      ],
                    ),
                  )
                else
                  ...reviews.map((r) => _buildReviewItem(r)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.edit),
        label: const Text('Viết đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WriteReviewScreen(locationId: widget.locationId)),
          );
          if (result == true) _reload();
        },
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: AppColors.surface2(context), child: Icon(Icons.person, color: AppColors.textMuted(context), size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(review.createdAt, style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(i < review.rating.floor() ? Icons.star : Icons.star_border, color: AppColors.green, size: 14);
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment, style: TextStyle(color: AppColors.text(context), height: 1.5)),
          ],
        ],
      ),
    );
  }
}
