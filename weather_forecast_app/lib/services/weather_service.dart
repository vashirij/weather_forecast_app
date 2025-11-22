// ...existing code...
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/forecast_models.dart';
import 'package:flutter/foundation.dart';
import 'package:weather_forecast_app/controllers/setting_controller.dart';

class WeatherService {
  final String apiKey;
  WeatherService(this.apiKey);
  // Add this method to support fetching forecast by city name
  Future<Map<String, dynamic>> fetchForecastByQuery(
    String query, {
    String units = 'metric',
  }) async {
    // Use Uri.https to ensure the query is properly encoded (e.g. "New York")
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
      'q': query,
      'units': units,
      'appid': apiKey,
    });
    if (kDebugMode) {
      developer.log(
        'fetchForecastByQuery GET: $uri',
        name: 'weather_service.fetchForecastByQuery',
      );
    }
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Parse hourly and daily forecasts from API response as needed
      final city = data['city']?['name'] ?? query;
      final list = data['list'] as List<dynamic>? ?? [];
      final unitSuffix = units == 'imperial' ? '°F' : '°C';
      final hourly = list.take(9).map((e) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          e['dt'] * 1000,
          isUtc: true,
        ).toLocal();
        final tempNum = (e['main']['temp'] as num).round();
        final temp = '$tempNum$unitSuffix';
        final icon = (e['weather'] as List).isNotEmpty
            ? e['weather'][0]['icon']
            : '';
        return HourlyForecast(time: '${dt.hour}:00', temp: temp, icon: icon);
      }).toList();

      // Build daily aggregates similar to fetchForecast
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
          if ((e['weather'] as List).isNotEmpty) {
            icon = (e['weather'][0]['icon'] as String);
          }
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
            high: '${maxT ?? 0}$unitSuffix',
            low: '${minT ?? 0}$unitSuffix',
            icon: icon,
          ),
        );
      });

      return {'city': city, 'hourly': hourly, 'daily': daily, 'raw': data};
    } else {
      // Include response body for better diagnostics when a query fails
      throw Exception(
        'Failed to fetch forecast for $query: ${response.statusCode} ${response.body}',
      );
    }
    // Ensure the function never completes normally without returning or throwing
  }

  /// Analyze raw forecast JSON (OpenWeather 3-hourly list) and return alert info.
  /// Returns map with keys: 'highTemp' (double), 'hasStorm' (bool), 'heavyRain' (bool), 'summary' (String)
  Map<String, dynamic> detectAlertsFromForecast(
    Map<String, dynamic> raw,
    SettingsController settings,
  ) {
    final list = raw['list'] as List<dynamic>? ?? [];
    double highest = double.negativeInfinity;
    bool hasStorm = false;
    bool heavyRain = false;

    for (var e in list) {
      try {
        final main = (e['main'] as Map<String, dynamic>?) ?? {};
        final temp =
            (main['temp'] as num?)?.toDouble() ?? double.negativeInfinity;
        if (temp > highest) highest = temp;

        final weatherList = (e['weather'] as List<dynamic>?) ?? [];
        if (weatherList.isNotEmpty) {
          final w = weatherList[0] as Map<String, dynamic>;
          final mainDesc = (w['main'] as String?)?.toLowerCase() ?? '';
          if (mainDesc.contains('thunder') || mainDesc.contains('storm')) {
            hasStorm = true;
          }
        }

        // heavy rain: check 'rain' field for volume > 10mm in 3h
        if (e.containsKey('rain')) {
          final rain = e['rain'] as Map<String, dynamic>?;
          final vol = (rain?['3h'] as num?)?.toDouble() ?? 0.0;
          if (vol >= 10.0) heavyRain = true;
        }
      } catch (_) {}
    }

    // Compare highest to user threshold (settings.units influence units)
    // Some analyzer setups may not resolve the controller getters; use dynamic
    // access to ensure runtime behavior remains correct while avoiding
    // spurious static analyzer errors.
    final threshold = (settings as dynamic).highTempThreshold as double;
    final exceeds = highest != double.negativeInfinity && highest >= threshold;

    final parts = <String>[];
    if (hasStorm) parts.add('Storm expected');
    if (heavyRain) parts.add('Heavy rain expected');
    if (exceeds)
      parts.add(
        'High temperature ${highest.round()} exceeding ${threshold.round()}',
      );

    final summary = parts.isEmpty ? '' : parts.join(' · ');
    return {
      'highTemp': highest == double.negativeInfinity ? null : highest,
      'hasStorm': hasStorm,
      'heavyRain': heavyRain,
      'exceedsThreshold': exceeds,
      'summary': summary,
    };
  }

  /// Search cities using OpenWeather Direct Geocoding API.
  /// Returns a list of formatted strings like 'Mountain View, CA, US'.
  Future<List<String>> searchCities(String query, {int limit = 5}) async {
    final uri = Uri.https('api.openweathermap.org', '/geo/1.0/direct', {
      'q': query,
      'limit': limit.toString(),
      'appid': apiKey,
    });
    if (kDebugMode)
      developer.log(
        'searchCities GET: $uri',
        name: 'weather_service.searchCities',
      );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      if (kDebugMode)
        developer.log(
          'searchCities error ${res.statusCode}: ${res.body}',
          name: 'weather_service.searchCities',
        );
      throw Exception('Geocoding error ${res.statusCode}: ${res.body}');
    }
    final list = json.decode(res.body) as List<dynamic>;
    final out = <String>[];
    for (var item in list) {
      final m = item as Map<String, dynamic>;
      final name = (m['name'] as String?) ?? '';
      final state = (m['state'] as String?) ?? '';
      final country = (m['country'] as String?) ?? '';
      final formatted = [
        name,
        if (state.isNotEmpty) state,
        if (country.isNotEmpty) country,
      ].join(', ');
      out.add(formatted);
    }
    return out;
  }

  // Fetch forecast using 3-hour forecast endpoint (free plan).
  // Returns map with 'hourly' (3-hour slots), 'daily' (aggregated highs/lows), and 'city' name.
  Future<Map<String, dynamic>> fetchForecast(
    double lat,
    double lon,
    String units,
  ) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=$units&appid=$apiKey',
    );
    final res = await http.get(url);

    // Print / log raw response for debugging
    if (kDebugMode) {
      developer.log('Weather GET: $url', name: 'weather_service.fetchForecast');
      developer.log(
        'Status: ${res.statusCode}',
        name: 'weather_service.fetchForecast',
      );
      try {
        final parsed = json.decode(res.body);
        final pretty = const JsonEncoder.withIndent('  ').convert(parsed);
        developer.log(
          'Response body (pretty):\n$pretty',
          name: 'weather_service.fetchForecast',
        );
        print('Weather API response (pretty):\n$pretty');
      } catch (e) {
        developer.log(
          'Response body (raw): ${res.body}',
          name: 'weather_service.fetchForecast',
        );
        print('Weather API response (raw): ${res.body}');
      }
    }

    if (res.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('Weather API error ${res.statusCode}: ${res.body}');
      }
      throw Exception('Weather API error: ${res.statusCode}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    // extract city name if available
    final cityName = (data['city'] != null && data['city']['name'] != null)
        ? (data['city']['name'] as String)
        : '';

    // 'list' contains 3-hour forecast entries
    final list = data['list'] as List<dynamic>;

    final unitSuffix = units == 'imperial' ? '°F' : '°C';
    final hourly = list.map((h) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        (h['dt'] as int) * 1000,
        isUtc: true,
      ).toLocal();
      final timeLabel = '${dt.hour.toString().padLeft(2, '0')}:00';
      final temp = '${(h['main']['temp'] as num).round()}$unitSuffix';
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
        if ((e['weather'] as List).isNotEmpty) {
          icon = (e['weather'][0]['icon'] as String);
        }
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
          high: '${maxT ?? 0}$unitSuffix',
          low: '${minT ?? 0}$unitSuffix',
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

    return {'hourly': hourly, 'daily': daily, 'city': cityName, 'raw': data};
  }

  // Reverse geocode using OpenWeather Geocoding API to get city name from coordinates
  Future<String> reverseGeocode(double lat, double lon) async {
    final url = Uri.https('api.openweathermap.org', '/geo/1.0/reverse', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'limit': '1',
      'appid': apiKey,
    });
    final res = await http.get(url);

    // Print / log raw response for debugging
    if (kDebugMode) {
      developer.log(
        'ReverseGeocode GET: $url',
        name: 'weather_service.reverseGeocode',
      );
      developer.log(
        'Status: ${res.statusCode}',
        name: 'weather_service.reverseGeocode',
      );
      try {
        final parsed = json.decode(res.body);
        final pretty = const JsonEncoder.withIndent('  ').convert(parsed);
        developer.log(
          'ReverseGeocode response (pretty):\n$pretty',
          name: 'weather_service.reverseGeocode',
        );
        print('ReverseGeocode response (pretty):\n$pretty');
      } catch (e) {
        developer.log(
          'ReverseGeocode response (raw): ${res.body}',
          name: 'weather_service.reverseGeocode',
        );
        print('ReverseGeocode response (raw): ${res.body}');
      }
    }

    if (res.statusCode != 200) {
      if (kDebugMode) {
        debugPrint('Reverse geocode error ${res.statusCode}: ${res.body}');
      }
      return '';
    }
    final data = json.decode(res.body) as List<dynamic>;
    if (data.isEmpty) return '';
    final item = data[0] as Map<String, dynamic>;
    return (item['name'] as String?) ?? '';
  }
}
