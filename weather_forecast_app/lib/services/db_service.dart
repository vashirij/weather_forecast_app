import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'weather_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE forecasts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city TEXT NOT NULL,
        lat REAL,
        lon REAL,
        fetched_at INTEGER NOT NULL,
        expires_at INTEGER,
        source TEXT,
        raw_json TEXT,
        UNIQUE(city, lat, lon)
      );
    ''');

    await db.execute('''
      CREATE TABLE hourly_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        forecast_id INTEGER NOT NULL,
        dt INTEGER NOT NULL,
        time TEXT,
        temp INTEGER,
        icon TEXT,
        UNIQUE(forecast_id, dt),
        FOREIGN KEY(forecast_id) REFERENCES forecasts(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE daily_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        forecast_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        day TEXT,
        high INTEGER,
        low INTEGER,
        icon TEXT,
        UNIQUE(forecast_id, date),
        FOREIGN KEY(forecast_id) REFERENCES forecasts(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city TEXT NOT NULL,
        lat REAL,
        lon REAL,
        note TEXT,
        created_at INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');

    await db.execute('CREATE INDEX idx_forecasts_city ON forecasts(city);');
    await db.execute(
      'CREATE INDEX idx_forecasts_fetched_at ON forecasts(fetched_at);',
    );
    await db.execute(
      'CREATE INDEX idx_hourly_forecast_dt ON hourly_entries(forecast_id, dt);',
    );
    await db.execute(
      'CREATE INDEX idx_daily_forecast_date ON daily_entries(forecast_id, date);',
    );
  }

  Future<int> insertForecast(Map<String, Object?> forecast) async {
    final database = await db;
    return await database.insert(
      'forecasts',
      forecast,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> upsertForecastWithEntries(
    Map<String, Object?> forecast,
    List<Map<String, Object?>> hourly,
    List<Map<String, Object?>> daily,
  ) async {
    final database = await db;
    return await database.transaction((txn) async {
      final id = await txn.insert(
        'forecasts',
        forecast,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // delete existing entries for id to simplify
      await txn.delete(
        'hourly_entries',
        where: 'forecast_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'daily_entries',
        where: 'forecast_id = ?',
        whereArgs: [id],
      );

      for (var h in hourly) {
        final hm = Map<String, Object?>.from(h);
        hm['forecast_id'] = id;
        await txn.insert(
          'hourly_entries',
          hm,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (var d in daily) {
        final dm = Map<String, Object?>.from(d);
        dm['forecast_id'] = id;
        await txn.insert(
          'daily_entries',
          dm,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      return id;
    });
  }

  Future<Map<String, Object?>?> getLatestForecast(String city) async {
    final database = await db;
    final res = await database.query(
      'forecasts',
      where: 'city = ?',
      whereArgs: [city],
      orderBy: 'fetched_at DESC',
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<List<Map<String, Object?>>> getHourlyForForecast(
    int forecastId,
  ) async {
    final database = await db;
    return await database.query(
      'hourly_entries',
      where: 'forecast_id = ?',
      whereArgs: [forecastId],
      orderBy: 'dt ASC',
    );
  }

  Future<List<Map<String, Object?>>> getDailyForForecast(int forecastId) async {
    final database = await db;
    return await database.query(
      'daily_entries',
      where: 'forecast_id = ?',
      whereArgs: [forecastId],
      orderBy: 'date ASC',
    );
  }

  Future<int> purgeExpired(int beforeEpochMs) async {
    final database = await db;
    return await database.delete(
      'forecasts',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [beforeEpochMs],
    );
  }
}
