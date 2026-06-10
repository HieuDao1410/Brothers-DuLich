import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/location_model.dart';
import '../../services/api_service.dart';
import '../../services/community_service.dart';
import '../../utils/app_colors.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _image;
  List<LocationModel> _locations = [];
  LocationModel? _checkIn;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final data = await ApiService.fetchLocations();
      if (mounted) setState(() => _locations = data);
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _image = img);
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_contentController.text.trim().isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hãy nhập nội dung hoặc chọn ảnh!')));
      return;
    }

    setState(() => _isSubmitting = true);
    final ok = await CommunityService.createPost(
      userId: user.uid,
      content: _contentController.text.trim(),
      locationId: _checkIn?.id,
      imagePath: _image?.path,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng bài thất bại!'), backgroundColor: Colors.redAccent));
    }
  }

  void _showCheckInPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Check-in địa danh', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              if (_checkIn != null)
                ListTile(
                  leading: const Icon(Icons.location_off, color: Colors.redAccent),
                  title: const Text('Bỏ check-in', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    setState(() => _checkIn = null);
                    Navigator.pop(context);
                  },
                ),
              ..._locations.map((loc) => ListTile(
                    leading: const Icon(Icons.place, color: AppColors.green),
                    title: Text(loc.name, style: TextStyle(color: AppColors.text(context))),
                    subtitle: Text(loc.province, style: TextStyle(color: AppColors.textMuted(context))),
                    onTap: () {
                      setState(() => _checkIn = loc);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
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
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text('Tạo bài viết', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
        actions: [
          _isSubmitting
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2)))
              : TextButton(onPressed: _submit, child: const Text('ĐĂNG', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 6,
              style: TextStyle(color: AppColors.text(context), fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Chia sẻ trải nghiệm chuyến đi của bạn...',
                hintStyle: TextStyle(color: AppColors.textMuted(context)),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 12),
            if (_image != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(_image!.path), height: 220, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _image = null),
                      child: const CircleAvatar(backgroundColor: Colors.black54, radius: 16, child: Icon(Icons.close, color: Colors.white, size: 18)),
                    ),
                  ),
                ],
              ),
            if (_checkIn != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.place, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Đang ở: ${_checkIn!.name}', style: TextStyle(color: AppColors.text(context)))),
                  ],
                ),
              ),
            Divider(color: AppColors.border(context), height: 32),
            Row(
              children: [
                _actionChip(Icons.image_outlined, 'Ảnh', _pickImage),
                const SizedBox(width: 12),
                _actionChip(Icons.location_on_outlined, 'Check-in', _showCheckInPicker),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.green, size: 20),
      label: Text(label, style: TextStyle(color: AppColors.text(context))),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
