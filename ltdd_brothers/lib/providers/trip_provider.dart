import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/location_model.dart';
import '../services/local_db.dart';
import '../services/schedule_service.dart';

// Cấu trúc dữ liệu của 1 Chuyến đi (Trip)
class TripItem {
  final String id; // ID cục bộ (timestamp)
  String name;
  String? startDate; // ISO 'yyyy-MM-dd'
  String? endDate;
  int? serverId; // ScheduleId trên Server sau khi đồng bộ
  bool synced; // Đã đồng bộ lên Server chưa
  String status;
  String notes; // Ghi chú của chuyến đi
  final List<LocationModel> savedLocations;

  TripItem({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.serverId,
    this.synced = false,
    this.status = 'Sắp tới',
    this.notes = '',
    List<LocationModel>? savedLocations,
  }) : savedLocations = savedLocations ?? [];

  // Hiển thị khoảng ngày của chuyến đi
  String get dateRange {
    if (startDate == null || startDate!.isEmpty) {
      return 'Chưa lên ngày khởi hành';
    }
    final s = _fmt(startDate!);
    final e = (endDate != null && endDate!.isNotEmpty) ? _fmt(endDate!) : s;
    return '$s - $e';
  }

  static String _fmt(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

class TripProvider with ChangeNotifier {
  List<TripItem> _trips = [];
  List<TripItem> get trips => _trips;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Nạp toàn bộ chuyến đi từ SQLite cục bộ, sau đó thử đồng bộ các chuyến chưa đồng bộ
  Future<void> loadTrips() async {
    final uid = _uid;
    if (uid.isEmpty) return;

    final rows = await LocalDb.instance.getTrips(uid);
    final List<TripItem> list = [];
    for (final r in rows) {
      final locRows = await LocalDb.instance.getTripLocations(r['id'] as String);
      list.add(TripItem(
        id: r['id'] as String,
        name: r['name'] as String? ?? '',
        startDate: r['startDate'] as String?,
        endDate: r['endDate'] as String?,
        serverId: r['serverId'] as int?,
        synced: (r['synced'] as int? ?? 0) == 1,
        status: r['status'] as String? ?? 'Sắp tới',
        notes: r['notes'] as String? ?? '',
        savedLocations: locRows.map(_mapToLocation).toList(),
      ));
    }
    _trips = list;
    notifyListeners();

    // Có mạng thì đẩy nốt những chuyến tạo lúc offline lên Server
    _syncUnsynced(uid);
  }

  // Tạo chuyến đi mới (lưu ngay SQLite, rồi thử đồng bộ Server)
  Future<void> addTrip(String name, {String? startDate, String? endDate}) async {
    final uid = _uid;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = TripItem(id: id, name: name, startDate: startDate, endDate: endDate, synced: false);

    _trips.insert(0, item);
    notifyListeners();

    await LocalDb.instance.insertTrip(_tripToRow(item, uid));

    final serverId = await ScheduleService.create(
      userId: uid, title: name, startDate: startDate, endDate: endDate,
    );
    if (serverId != null) {
      item.serverId = serverId;
      item.synced = true;
      await LocalDb.instance.updateTrip(id, {'serverId': serverId, 'synced': 1});
      notifyListeners();
    }
  }

  // Lưu địa điểm vào 1 chuyến đi
  Future<void> saveLocationToTrip(String tripId, LocationModel location) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx == -1) return;
    if (_trips[idx].savedLocations.any((l) => l.id == location.id)) return;

    _trips[idx].savedLocations.add(location);
    notifyListeners();
    await LocalDb.instance.insertTripLocation(_locToRow(tripId, location));
  }

  // Xóa địa điểm khỏi chuyến đi
  Future<void> removeLocationFromTrip(String tripId, int locationId) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx == -1) return;

    _trips[idx].savedLocations.removeWhere((l) => l.id == locationId);
    notifyListeners();
    await LocalDb.instance.deleteTripLocation(tripId, locationId);
  }

  // Lưu ghi chú của chuyến đi (cục bộ SQLite)
  Future<void> updateNotes(String tripId, String notes) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    if (idx == -1) return;
    _trips[idx].notes = notes;
    await LocalDb.instance.updateNotes(tripId, notes);
    notifyListeners();
  }

  // Xóa toàn bộ chuyến đi (cục bộ + trên Server nếu đã đồng bộ)
  Future<void> deleteTrip(String tripId) async {
    final idx = _trips.indexWhere((t) => t.id == tripId);
    final int? serverId = idx != -1 ? _trips[idx].serverId : null;

    _trips.removeWhere((t) => t.id == tripId);
    notifyListeners();

    await LocalDb.instance.deleteTrip(tripId);
    if (serverId != null) {
      await ScheduleService.delete(serverId);
    }
  }

  // Đẩy các chuyến chưa đồng bộ lên Server
  Future<void> _syncUnsynced(String uid) async {
    final rows = await LocalDb.instance.getUnsyncedTrips(uid);
    bool changed = false;
    for (final r in rows) {
      final serverId = await ScheduleService.create(
        userId: uid,
        title: r['name'] as String? ?? '',
        startDate: r['startDate'] as String?,
        endDate: r['endDate'] as String?,
      );
      if (serverId != null) {
        await LocalDb.instance.updateTrip(r['id'] as String, {'serverId': serverId, 'synced': 1});
        final idx = _trips.indexWhere((t) => t.id == r['id']);
        if (idx != -1) {
          _trips[idx].serverId = serverId;
          _trips[idx].synced = true;
        }
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // ===== Helpers chuyển đổi dữ liệu <-> SQLite =====
  Map<String, dynamic> _tripToRow(TripItem t, String uid) => {
        'id': t.id,
        'serverId': t.serverId,
        'userId': uid,
        'name': t.name,
        'startDate': t.startDate,
        'endDate': t.endDate,
        'status': t.status,
        'synced': t.synced ? 1 : 0,
        'notes': t.notes,
      };

  Map<String, dynamic> _locToRow(String tripId, LocationModel l) => {
        'tripId': tripId,
        'locationId': l.id,
        'name': l.name,
        'province': l.province,
        'description': l.description,
        'imageUrl': l.imageUrl,
        'rating': l.rating,
        'category': l.category,
        'latitude': l.latitude,
        'longitude': l.longitude,
      };

  LocationModel _mapToLocation(Map<String, dynamic> m) => LocationModel(
        id: m['locationId'] as int? ?? 0,
        name: m['name'] as String? ?? '',
        province: m['province'] as String? ?? '',
        description: m['description'] as String? ?? '',
        imageUrl: m['imageUrl'] as String? ?? '',
        rating: (m['rating'] as num? ?? 0).toDouble(),
        category: m['category'] as String? ?? 'Địa danh',
        latitude: (m['latitude'] as num? ?? 0).toDouble(),
        longitude: (m['longitude'] as num? ?? 0).toDouble(),
      );
}
