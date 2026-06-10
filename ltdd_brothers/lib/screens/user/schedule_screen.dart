import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/location_model.dart';
import '../../utils/app_colors.dart';

// ============================================================================
// 1. MÀN HÌNH CHÍNH (SCHEDULE SCREEN)
// ============================================================================
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TripProvider>(context, listen: false).loadTrips();
    });
  }

  // Mở lịch chọn KHOẢNG ngày (date range) trên 1 lịch - giống TripAdvisor
  Future<DateTimeRange?> _pickDateRange(BuildContext context, DateTimeRange? current) {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3, 12, 31),
      initialDateRange: current,
      helpText: 'Chọn ngày đi',
      saveText: 'XONG',
      cancelText: 'HỦY',
    );
  }

  void _showCreateTripDialog(BuildContext context) {
    final TextEditingController tripNameController = TextEditingController();
    DateTimeRange? range;

    String fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    String iso(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final days = range == null ? 0 : range!.duration.inDays + 1;

            return AlertDialog(
              backgroundColor: AppColors.surface(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Tạo chuyến đi mới', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tripNameController,
                    style: TextStyle(color: AppColors.text(context)),
                    decoration: InputDecoration(
                      hintText: 'Nhập tên chuyến đi (VD: Đà Lạt)',
                      hintStyle: TextStyle(color: AppColors.textMuted(context), fontSize: 14),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border(context))),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.green)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 1 nút mở lịch chọn khoảng ngày
                  InkWell(
                    onTap: () async {
                      final picked = await _pickDateRange(context, range);
                      if (picked != null) setStateDialog(() => range = picked);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bg(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, color: AppColors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: range == null
                                ? Text('Chọn ngày đi (tùy chọn)', style: TextStyle(color: AppColors.textMuted(context)))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${fmt(range!.start)}  →  ${fmt(range!.end)}',
                                          style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('$days ngày', style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('HỦY', style: TextStyle(color: AppColors.textMuted(context)))),
                ElevatedButton(
                  onPressed: () {
                    String tripName = tripNameController.text.trim();
                    if (tripName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập tên chuyến đi!')),
                      );
                      return;
                    }
                    Provider.of<TripProvider>(context, listen: false).addTrip(
                      tripName,
                      startDate: range != null ? iso(range!.start) : null,
                      endDate: range != null ? iso(range!.end) : null,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                  child: const Text('TẠO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String tripId, String tripName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Xóa chuyến đi?', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
          content: Text(
            'Bạn có chắc chắn muốn xóa chuyến đi "$tripName" không? Toàn bộ địa điểm đã lưu trong này sẽ bị mất.',
            style: TextStyle(color: AppColors.textMuted(context), height: 1.5),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('HỦY', style: TextStyle(color: AppColors.textMuted(context)))),
            ElevatedButton(
              onPressed: () {
                Provider.of<TripProvider>(context, listen: false).deleteTrip(tripId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa chuyến đi thành công!'), backgroundColor: Colors.redAccent),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('XÓA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final createdTrips = tripProvider.trips;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        title: Text('Chuyến đi', style: TextStyle(color: AppColors.text(context), fontSize: 28, fontWeight: FontWeight.w900)),
        actions: [
          if (createdTrips.isNotEmpty)
            IconButton(icon: Icon(Icons.add, color: AppColors.text(context)), onPressed: () => _showCreateTripDialog(context))
        ],
      ),
      body: createdTrips.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: AppColors.bg(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(context))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flight, color: AppColors.text(context), size: 48),
                      const SizedBox(height: 24),
                      Text('Lập kế hoạch chuyến đi', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text(context))),
                      const SizedBox(height: 16),
                      Text('Hãy bắt đầu hành trình của bạn bằng cách tạo một chuyến đi mới.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted(context), fontSize: 15, height: 1.5)),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => _showCreateTripDialog(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                        child: const Text('Tạo một chuyến đi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: createdTrips.length,
              itemBuilder: (context, index) {
                final trip = createdTrips[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(context))),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(width: 64, height: 64, color: AppColors.surface2(context), child: Icon(Icons.flight_takeoff, color: AppColors.textMuted(context), size: 28)),
                    ),
                    title: Text(trip.name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.dateRange, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(trip.status, style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(trip.synced ? Icons.cloud_done : Icons.cloud_off, size: 14, color: trip.synced ? AppColors.green : AppColors.textMuted(context)),
                                  const SizedBox(width: 4),
                                  Text(trip.synced ? 'Đã đồng bộ' : 'Lưu cục bộ', style: TextStyle(color: AppColors.textMuted(context), fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppColors.textMuted(context)),
                      color: AppColors.surface(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteConfirmDialog(context, trip.id, trip.name);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              SizedBox(width: 12),
                              Text('Xóa chuyến đi', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TripDetailScreen(tripId: trip.id)));
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// 2. MÀN HÌNH CHI TIẾT CHUYẾN ĐI
// ============================================================================
class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<DateTime> _tripDates = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = Provider.of<TripProvider>(context, listen: false);
      final idx = tp.trips.indexWhere((t) => t.id == widget.tripId);
      if (idx == -1) return;
      final trip = tp.trips[idx];
      _noteController.text = trip.notes;
      _generateDatesFromTrip(trip);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _generateDatesFromTrip(TripItem trip) {
    if (trip.startDate == null || trip.startDate!.isEmpty) return;
    final start = DateTime.tryParse(trip.startDate!);
    if (start == null) return;
    final end = (trip.endDate != null && trip.endDate!.isNotEmpty) ? (DateTime.tryParse(trip.endDate!) ?? start) : start;

    final List<DateTime> days = [];
    var d = start;
    while (!d.isAfter(end)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    setState(() {
      _tripDates
        ..clear()
        ..addAll(days);
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2030),
    );
    if (picked != null && !_tripDates.contains(picked)) {
      setState(() {
        _tripDates.add(picked);
        _tripDates.sort();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);
    final tripExists = tripProvider.trips.any((t) => t.id == widget.tripId);
    if (!tripExists) {
      return Scaffold(backgroundColor: AppColors.bg(context), body: Center(child: Text('Chuyến đi không tồn tại', style: TextStyle(color: AppColors.text(context)))));
    }

    final currentTrip = tripProvider.trips.firstWhere((t) => t.id == widget.tripId);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(backgroundColor: AppColors.bg(context), elevation: 0, iconTheme: IconThemeData(color: AppColors.text(context))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(currentTrip.name, style: TextStyle(color: AppColors.text(context), fontSize: 32, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.green,
            labelColor: AppColors.text(context),
            unselectedLabelColor: AppColors.textMuted(context),
            indicatorWeight: 3,
            tabs: const [Tab(text: 'Các mục đã lưu'), Tab(text: 'Lịch trình'), Tab(text: 'Ghi chú')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSavedItemsTab(currentTrip.savedLocations, tripProvider, currentTrip.id),
                _buildItineraryTab(),
                _buildNotesTab(tripProvider, currentTrip.id),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSavedItemsTab(List<LocationModel> savedItems, TripProvider tripProvider, String tripId) {
    if (savedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: AppColors.textMuted(context)),
            const SizedBox(height: 16),
            Text('Chưa có địa điểm nào được lưu', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedItems.length,
      itemBuilder: (context, index) {
        final location = savedItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border(context))),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(width: 64, height: 64, color: AppColors.surface2(context), child: Icon(Icons.landscape, color: AppColors.textMuted(context))),
            ),
            title: Text(location.name, style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(location.province, style: TextStyle(color: AppColors.textMuted(context), fontSize: 13)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => tripProvider.removeLocationFromTrip(tripId, location.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItineraryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(25)),
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: AppColors.textMuted(context), size: 18),
                      const SizedBox(width: 8),
                      Text('Thêm ngày', style: TextStyle(color: AppColors.textMuted(context), fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _tripDates.isEmpty
                ? Center(child: Text('Hãy thêm ngày để sắp xếp lịch trình', style: TextStyle(color: AppColors.textMuted(context))))
                : ListView.builder(
                    itemCount: _tripDates.length,
                    itemBuilder: (context, index) {
                      final date = _tripDates[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            const Icon(Icons.event, color: AppColors.green, size: 20),
                            const SizedBox(width: 12),
                            Text("Ngày ${index + 1}: ${date.day}/${date.month}/${date.year}",
                                style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildNotesTab(TripProvider tripProvider, String tripId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border(context)),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: AppColors.text(context), height: 1.5),
                decoration: InputDecoration(
                  hintText: 'Ghi chú cho chuyến đi: vé máy bay, khách sạn, đồ cần mang...',
                  hintStyle: TextStyle(color: AppColors.textMuted(context)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              FocusScope.of(context).unfocus();
              tripProvider.updateNotes(tripId, _noteController.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu ghi chú!'), backgroundColor: AppColors.green),
              );
            },
            icon: const Icon(Icons.save_outlined, color: Colors.black),
            label: const Text('Lưu ghi chú', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ],
      ),
    );
  }
}
