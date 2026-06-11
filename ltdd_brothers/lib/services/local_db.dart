import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static final LocalDb instance = LocalDb._init();
  static Database? _database;

  LocalDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('travel_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Bảng lưu thông tin chuyến đi tổng quát (Offline)
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        serverId INTEGER,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        startDate TEXT,
        endDate TEXT,
        status TEXT,
        synced INTEGER NOT NULL DEFAULT 0,
        notes TEXT
      )
    ''');

    // 2. Bảng lưu chi tiết các địa danh đã lưu trong chuyến đi
    await db.execute('''
      CREATE TABLE trip_locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId TEXT NOT NULL,
        locationId INTEGER NOT NULL,
        name TEXT,
        province TEXT,
        description TEXT,
        imageUrl TEXT,
        rating REAL,
        category TEXT,
        latitude REAL,
        longitude REAL,
        FOREIGN KEY (tripId) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================================
  // CÁC HÀM TƯƠNG TÁC CHO CHUYẾN ĐI (TRIPS)
  // ==========================================================

  Future<List<Map<String, dynamic>>> getTrips(String uid) async {
    final db = await instance.database;
    // Sắp xếp chuyến đi mới tạo lên đầu
    return await db.query('trips', where: 'userId = ?', whereArgs: [uid], orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTrips(String uid) async {
    final db = await instance.database;
    return await db.query('trips', where: 'userId = ? AND synced = 0', whereArgs: [uid]);
  }

  Future<int> insertTrip(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('trips', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTrip(String id, Map<String, dynamic> values) async {
    final db = await instance.database;
    return await db.update('trips', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateNotes(String tripId, String notes) async {
    final db = await instance.database;
    return await db.update('trips', {'notes': notes}, where: 'id = ?', whereArgs: [tripId]);
  }

  Future<int> deleteTrip(String tripId) async {
    final db = await instance.database;
    // Xóa các địa danh thuộc chuyến đi trước (tránh rác DB)
    await db.delete('trip_locations', where: 'tripId = ?', whereArgs: [tripId]);
    return await db.delete('trips', where: 'id = ?', whereArgs: [tripId]);
  }

  // ==========================================================
  // CÁC HÀM TƯƠNG TÁC CHO ĐỊA ĐIỂM (TRIP LOCATIONS)
  // ==========================================================

  Future<List<Map<String, dynamic>>> getTripLocations(String tripId) async {
    final db = await instance.database;
    return await db.query('trip_locations', where: 'tripId = ?', whereArgs: [tripId]);
  }

  Future<int> insertTripLocation(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('trip_locations', row, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> deleteTripLocation(String tripId, int locationId) async {
    final db = await instance.database;
    return await db.delete('trip_locations', where: 'tripId = ? AND locationId = ?', whereArgs: [tripId, locationId]);
  }

  Future close() async {
    final db = await _database;
    if (db != null) await db.close();
  }
}