import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/location_model.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class AddLocationScreen extends StatefulWidget {
  final LocationModel? location;

  const AddLocationScreen({Key? key, this.location}) : super(key: key);

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = ['Địa danh', 'Khách sạn', 'Nhà hàng', 'Ăn uống', 'Tham quan'];

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isSaving = false;

  bool get _isEditMode => widget.location != null;

  @override
  void initState() {
    super.initState();
    final loc = widget.location;
    if (loc != null) {
      _nameController.text = loc.name;
      _provinceController.text = loc.province;
      _descController.text = loc.description;
      _latController.text = loc.latitude.toString();
      _lngController.text = loc.longitude.toString();
      if (_categories.contains(loc.category)) _selectedCategory = loc.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _provinceController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) setState(() => _pickedImage = image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không mở được thư viện ảnh: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên địa danh!')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục!')));
      return;
    }

    final double lat = double.tryParse(_latController.text.trim()) ?? 0;
    final double lng = double.tryParse(_lngController.text.trim()) ?? 0;

    setState(() => _isSaving = true);

    bool ok;
    if (_isEditMode) {
      ok = await ApiService.updateLocation(
        id: widget.location!.id,
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        province: _provinceController.text.trim(),
        description: _descController.text.trim(),
        latitude: lat,
        longitude: lng,
        imagePath: _pickedImage?.path,
      );
    } else {
      ok = await ApiService.createLocation(
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        province: _provinceController.text.trim(),
        description: _descController.text.trim(),
        latitude: lat,
        longitude: lng,
        imagePath: _pickedImage?.path,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditMode ? 'Đã cập nhật địa danh!' : 'Đã thêm địa danh mới!'),
        backgroundColor: AppColors.green,
      ));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu thất bại. Kiểm tra kết nối Server!'), backgroundColor: Colors.redAccent),
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
        iconTheme: IconThemeData(color: AppColors.text(context)),
        title: Text(_isEditMode ? 'Sửa Địa danh' : 'Thêm Địa danh', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(_nameController, 'Tên địa danh', 'VD: Vịnh Hạ Long'),
            const SizedBox(height: 16),
            _buildTextField(_provinceController, 'Tỉnh / Thành phố', 'VD: Quảng Ninh'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: AppColors.surface(context),
                  value: _selectedCategory,
                  hint: Text('Chọn danh mục', style: TextStyle(color: AppColors.textMuted(context))),
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.text(context)),
                  isExpanded: true,
                  style: TextStyle(color: AppColors.text(context), fontSize: 16),
                  items: _categories.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  onChanged: (newValue) => setState(() => _selectedCategory = newValue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(_latController, 'Vĩ độ (Latitude)', 'VD: 20.9101', isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_lngController, 'Kinh độ (Longitude)', 'VD: 107.1839', isNumber: true)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_descController, 'Mô tả chi tiết', 'Nhập giới thiệu...', maxLines: 5),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : Text(_isEditMode ? 'Cập nhật Địa danh' : 'Xuất bản Địa danh', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_pickedImage != null) {
      return Image.file(File(_pickedImage!.path), fit: BoxFit.cover, width: double.infinity);
    }
    final existing = widget.location?.imageUrl ?? '';
    if (existing.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(ApiService.fullImageUrl(existing), headers: const {'User-Agent': 'ltdd_brothers/1.0'}, fit: BoxFit.cover, errorBuilder: (c, e, s) => _uploadHint()),
          Container(
            color: Colors.black38,
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(8),
            child: const Text('Nhấn để đổi ảnh khác', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
    return _uploadHint();
  }

  Widget _uploadHint() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, size: 50, color: AppColors.textMuted(context)),
        const SizedBox(height: 12),
        Text('Nhấn để tải ảnh lên', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
      style: TextStyle(color: AppColors.text(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted(context)),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted(context)),
        filled: true,
        fillColor: AppColors.surface(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.green, width: 1.5)),
      ),
    );
  }
}
