import 'package:flutter/material.dart';
import '../../models/location_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';
import 'add_location_screen.dart';

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({Key? key}) : super(key: key);

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  late Future<List<LocationModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchLocations();
  }

  void _reload() {
    setState(() {
      _future = ApiService.fetchLocations();
    });
  }

  Future<void> _openForm({LocationModel? location}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddLocationScreen(location: location)),
    );
    if (result == true) _reload();
  }

  void _showDeleteDialog(LocationModel location) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Xác nhận xóa', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
          content: Text('Bạn có chắc muốn xóa "${location.name}"? Hành động này không thể hoàn tác.',
              style: TextStyle(color: AppColors.textMuted(context))),
          actions: [
            TextButton(child: Text('Hủy', style: TextStyle(color: AppColors.text(context))), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.of(context).pop();
                final ok = await ApiService.deleteLocation(location.id);
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text(ok ? 'Đã xóa địa danh' : 'Xóa thất bại!'),
                  backgroundColor: ok ? Colors.redAccent : Colors.grey,
                ));
                if (ok) _reload();
              },
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
        title: Text('Quản lý Địa danh', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: AppColors.text(context)), onPressed: _reload),
          IconButton(icon: Icon(Icons.add, color: AppColors.text(context)), onPressed: () => _openForm()),
        ],
      ),
      body: FutureBuilder<List<LocationModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.green));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Lỗi tải dữ liệu:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            );
          }

          final locations = snapshot.data ?? [];
          if (locations.isEmpty) {
            return Center(child: Text('Chưa có địa danh nào. Nhấn + để thêm.', style: TextStyle(color: AppColors.textMuted(context))));
          }

          return RefreshIndicator(
            color: AppColors.green,
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                return Card(
                  color: AppColors.surface(context),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: loc.imageUrl.isEmpty
                            ? Container(color: AppColors.surface2(context), child: Icon(Icons.image, color: AppColors.textMuted(context)))
                            : Image.network(ApiService.fullImageUrl(loc.imageUrl), headers: const {'User-Agent': 'ltdd_brothers/1.0'}, fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(color: AppColors.surface2(context), child: Icon(Icons.broken_image, color: AppColors.textMuted(context)))),
                      ),
                    ),
                    title: Text(loc.name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                    subtitle: Text('${loc.province} • ${loc.category} • ⭐ ${loc.rating}', style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent), onPressed: () => _openForm(location: loc)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _showDeleteDialog(loc)),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
