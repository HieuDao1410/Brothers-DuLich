import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Quản lý cơ sở dữ liệu SQLite cục bộ trên thiết bị (hoạt động Offline).
// Lưu lịch trình chuyến đi (trips) và các địa điểm đã lưu trong từng chuyến (trip_locations).
class LocalDb {
  LocalDb._privateConstructor();
  static final LocalDb instance = LocalDb._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'travel_local.db');
    return await openDatabase(
      path,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Nâng cấp DB cũ: thêm cột ghi chú cho bảng trips
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE trips ADD COLUMN notes TEXT');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id TEXT PRIMARY KEY,
            serverId INTEGER,
            userId TEXT,
            name TEXT,
            startDate TEXT,
            endDate TEXT,
            status TEXT,
            synced INTEGER DEFAULT 0,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE trip_locations (
            rowId INTEGER PRIMARY KEY AUTOINCREMENT,
            tripId TEXT,
            locationId INTEGER,
            name TEXT,
            province TEXT,
            description TEXT,
            imageUrl TEXT,
            rating REAL,
            category TEXT,
            latitude REAL,
            longitude REAL
          )
        ''');
      },
    );
  }

  // ===== TRIPS =====
  Future<void> insertTrip(Map<String, dynamic> trip) async {
    final db = await database;
    await db.insert('trips', trip, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTrip(String id, Map<String, dynamic> values) async {
    final db = await database;
    await db.update('trips', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateNotes(String id, String notes) async {
    final db = await database;
    await db.update('trips', {'notes': notes}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTrips(String userId) async {
    final db = await database;
    return await db.query('trips', where: 'userId = ?', whereArgs: [userId], orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTrips(String userId) async {
    final db = await database;
    return await db.query('trips', where: 'userId = ? AND synced = 0', whereArgs: [userId]);
  }

  Future<void> deleteTrip(String id) async {
    final db = await database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
    await db.delete('trip_locations', where: 'tripId = ?', whereArgs: [id]);
  }

  // ===== TRIP LOCATIONS =====
  Future<void> insertTripLocation(Map<String, dynamic> loc) async {
    final db = await database;
    await db.insert('trip_locations', loc);
  }

  Future<void> deleteTripLocation(String tripId, int locationId) async {
    final db = await database;
    await db.delete('trip_locations', where: 'tripId = ? AND locationId = ?', whereArgs: [tripId, locationId]);
  }

  Future<List<Map<String, dynamic>>> getTripLocations(String tripId) async {
    final db = await database;
    return await db.query('trip_locations', where: 'tripId = ?', whereArgs: [tripId]);
  }
}
