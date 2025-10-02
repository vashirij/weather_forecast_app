import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'db_service.dart';

Future<void> runDbTest() async {
  final db = DBService();
  try {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final forecast = {
      'city': 'TestCity',
      'lat': 1.23,
      'lon': 4.56,
      'fetched_at': nowMs,
      'expires_at': nowMs + 1000 * 60 * 30,
      'source': 'test',
      'raw_json': null,
    };

    final hourly = List.generate(3, (i) {
      final dt =
          DateTime.now().add(Duration(hours: i)).millisecondsSinceEpoch ~/ 1000;
      return {
        'dt': dt,
        'time':
            '${DateTime.now().add(Duration(hours: i)).hour.toString().padLeft(2, '0')}:00',
        'temp': 20 + i,
        'icon': '01d',
      };
    });

    final daily = List.generate(3, (i) {
      final date = DateTime.now().add(Duration(days: i));
      final dateStr = '${date.year}-${date.month}-${date.day}';
      return {
        'date': dateStr,
        'day': [
          'Sun',
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
        ][date.weekday % 7],
        'high': 25 + i,
        'low': 15 + i,
        'icon': '01d',
      };
    });

    final id = await db.upsertForecastWithEntries(forecast, hourly, daily);
    debugPrint('Inserted forecast id: $id');

    final fetched = await db.getLatestForecast('TestCity');
    debugPrint('Fetched forecast row: $fetched');

    final hourlyRows = await db.getHourlyForForecast(id);
    debugPrint('Hourly rows count: ${hourlyRows.length}');
    for (var r in hourlyRows) debugPrint('  hourly: $r');

    final dailyRows = await db.getDailyForForecast(id);
    debugPrint('Daily rows count: ${dailyRows.length}');
    for (var r in dailyRows) debugPrint('  daily: $r');

    final purged = await db.purgeExpired(
      DateTime.now().millisecondsSinceEpoch + 1,
    );
    debugPrint('Purged forecasts count (should be 0): $purged');

    debugPrint('DB test completed successfully');
  } catch (e, st) {
    debugPrint('DB test failed: $e');
    if (kDebugMode) log('DB test stack', error: e, stackTrace: st);
  }
}
