import 'package:flutter/material.dart';
import 'detail_screen.dart';
import 'profile_screen.dart' show NotificationScreen;
import '../../models/location_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/location_placeholder.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToNearby;

  const HomeScreen({Key? key, required this.onNavigateToNearby}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color _tripGreen = AppColors.green;
  final TextEditingController _searchController = TextEditingController();

  List<LocationModel> _allLocations = [];
  List<LocationModel> _filtered = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final data = await ApiService.fetchLocations();
      if (!mounted) return;
      setState(() {
        _allLocations = data;
        _filtered = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể kết nối máy chủ';
        _isLoading = false;
      });
    }
  }

  void _applySearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _allLocations
          : _allLocations.where((loc) {
              return loc.name.toLowerCase().contains(q) ||
                  loc.province.toLowerCase().contains(q) ||
                  loc.category.toLowerCase().contains(q);
            }).toList();
    });
  }

  void _openDetail(LocationModel loc) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(location: loc)));
  }

  @override
  Widget build(BuildContext context) {
    final bool searching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: RefreshIndicator(
          color: _tripGreen,
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Đi đâu?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.text(context))),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppColors.surface(context),
                        child: Icon(Icons.notifications_none, color: AppColors.text(context)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _applySearch,
                    style: TextStyle(color: AppColors.text(context)),
                    decoration: InputDecoration(
                      hintText: 'Tìm địa danh, tỉnh thành...',
                      hintStyle: TextStyle(color: AppColors.textMuted(context), fontSize: 15),
                      prefixIcon: Icon(Icons.search, color: AppColors.text(context)),
                      suffixIcon: searching
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.textMuted(context)),
                              onPressed: () {
                                _searchController.clear();
                                _applySearch('');
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator(color: _tripGreen)),
                  )
                else if (_error.isNotEmpty)
                  _buildError()
                else if (searching)
                  _buildSearchResults()
                else
                  _buildBrowse(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.cloud_off, color: AppColors.textMuted(context), size: 60),
            const SizedBox(height: 16),
            Text(_error, style: TextStyle(color: AppColors.text(context))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: _tripGreen),
              child: const Text('Thử lại', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(child: Text('Không tìm thấy địa danh phù hợp', style: TextStyle(color: AppColors.textMuted(context)))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kết quả (${_filtered.length})',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text(context))),
        const SizedBox(height: 12),
        ..._filtered.map(_buildListRow),
      ],
    );
  }

  Widget _buildBrowse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: AppColors.surface2(context), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(Icons.location_on, color: _tripGreen)),
          ),
          title: Text('Khám phá khu vực lân cận',
              style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text('Xem các địa danh quanh bạn trên bản đồ', style: TextStyle(color: AppColors.textMuted(context))),
          trailing: Icon(Icons.arrow_forward_ios, color: AppColors.text(context), size: 16),
          onTap: widget.onNavigateToNearby,
        ),
        const SizedBox(height: 24),

        if (_allLocations.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(child: Text('Chưa có địa danh nào', style: TextStyle(color: AppColors.textMuted(context)))),
          )
        else ...[
          Text('Gợi ý cho bạn',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _allLocations.length > 8 ? 8 : _allLocations.length,
              itemBuilder: (context, index) => _buildCard(_allLocations[index]),
            ),
          ),
          const SizedBox(height: 32),
          Text('Tất cả địa danh',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text(context))),
          const SizedBox(height: 16),
          ..._allLocations.map(_buildListRow),
        ],
      ],
    );
  }

  Widget _buildCard(LocationModel loc) {
    return GestureDetector(
      onTap: () => _openDetail(loc),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 120, width: double.infinity, child: _image(loc)),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: _tripGreen, size: 14),
                      const SizedBox(width: 4),
                      Text('${loc.rating}', style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(loc.province,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textMuted(context), fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListRow(LocationModel loc) {
    return GestureDetector(
      onTap: () => _openDetail(loc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 70, height: 70, child: _image(loc)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: _tripGreen, size: 14),
                      const SizedBox(width: 4),
                      Text('${loc.rating}', style: TextStyle(color: AppColors.text(context), fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: BoxDecoration(color: AppColors.textMuted(context), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(loc.category, style: TextStyle(color: _tripGreen, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(loc.province, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.textMuted(context), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _image(LocationModel loc) {
    if (loc.imageUrl.isEmpty) {
      // Không có ảnh thật -> khung minh hoạ trung tính (không để trống, không sai)
      return LocationPlaceholder(category: loc.category, name: loc.name);
    }
    return Image.network(
      ApiService.fullImageUrl(loc.imageUrl),
      headers: const {'User-Agent': 'ltdd_brothers/1.0'},
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.surface2(context),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _tripGreen)),
        );
      },
      errorBuilder: (context, error, stack) => LocationPlaceholder(category: loc.category, name: loc.name),
    );
  }
}
