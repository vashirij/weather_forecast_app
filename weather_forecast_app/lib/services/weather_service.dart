import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecast_models.dart';
import 'package:flutter/foundation.dart';

class WeatherService {
  final String apiKey;
  WeatherService(this.apiKey);

  // Fetch forecast using 3-hour forecast endpoint (free plan).
  // Returns map with 'hourly' (3-hour slots), 'daily' (aggregated highs/lows), and 'city' name.
  Future<Map<String, dynamic>> fetchForecast(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      if (kDebugMode)
        debugPrint('Weather API error ${res.statusCode}: ${res.body}');
      throw Exception('Weather API error: ${res.statusCode}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;

    // extract city name if available
    final cityName = (data['city'] != null && data['city']['name'] != null)
        ? (data['city']['name'] as String)
        : '';

    // 'list' contains 3-hour forecast entries
    final list = data['list'] as List<dynamic>;

    final hourly = list.map((h) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (h['dt'] as int) * 1000,
        isUtc: true,
      ).toLocal();
      final timeLabel = '${dt.hour.toString().padLeft(2, '0')}:00';
      final temp = '${(h['main']['temp'] as num).round()}°C';
      final icon = (h['weather'] as List).isNotEmpty
          ? (h['weather'][0]['icon'] as String)
          : '01d';
      return HourlyForecast(time: timeLabel, temp: temp, icon: icon);
    }).toList();

    // Aggregate daily highs/lows
    final Map<String, List<dynamic>> byDate = {};
    for (var h in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (h['dt'] as int) * 1000,
        isUtc: true,
      ).toLocal();
      final key = '${dt.year}-${dt.month}-${dt.day}';
      byDate.putIfAbsent(key, () => []).add(h);
    }

    final daily = <DailyForecast>[];
    byDate.forEach((key, entries) {
      int? maxT;
      int? minT;
      String icon = '01d';
      DateTime dtFirst = DateTime.now();
      for (var e in entries) {
        final temp = (e['main']['temp'] as num).round();
        maxT = (maxT == null || temp > maxT) ? temp : maxT;
        minT = (minT == null || temp < minT) ? temp : minT;
        if ((e['weather'] as List).isNotEmpty)
          icon = (e['weather'][0]['icon'] as String);
        dtFirst = DateTime.fromMillisecondsSinceEpoch(
          (e['dt'] as int) * 1000,
          isUtc: true,
        ).toLocal();
      }
      final dayLabel = [
        'Sun',
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
      ][dtFirst.weekday % 7];
      daily.add(
        DailyForecast(
          day: dayLabel,
          high: '${maxT ?? 0}°C',
          low: '${minT ?? 0}°C',
          icon: icon,
        ),
      );
    });

    // Sort daily by date ascending - keep original order using parsed dates
    // We'll return as-is (map insertion order), but ensure deterministic order by sorting keys
    daily.sort((a, b) {
      final idx = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return idx.indexOf(a.day).compareTo(idx.indexOf(b.day));
    });

    return {'hourly': hourly, 'daily': daily, 'city': cityName};
  }

  // Reverse geocode using OpenWeather Geocoding API to get city name from coordinates
  Future<String> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      'http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) {
      if (kDebugMode)
        debugPrint('Reverse geocode error ${res.statusCode}: ${res.body}');
      return '';
    }
    final data = json.decode(res.body) as List<dynamic>;
    if (data.isEmpty) return '';
    final item = data[0] as Map<String, dynamic>;
    return (item['name'] as String?) ?? '';
  }
}
