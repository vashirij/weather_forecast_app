import '../../services/db_test.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../controllers/auth_controller.dart';
import 'package:weather_forecast_app/controllers/setting_controller.dart'; // fixed import
import '../auth/signin_screen.dart';
import '../settings/settings_screen.dart';
import '../../models/forecast_models.dart';
import '../../services/weather_service.dart';
import 'dart:developer' as developer;
import '../../utils/helpers.dart';
import 'today_screen.dart';
import 'hourly_screen.dart';
import 'weekly_screen.dart';
import '../../services/notification_service.dart';

// Simple daily forecast screen using WeatherService to load real data.
// Keeps widgets small and readable for maintenance.

const double kTileWidth = 110.0;
const double kTileHeight = 120.0;

class DailyForecastScreen extends StatefulWidget {
  final AuthController authController;
  DailyForecastScreen({super.key, AuthController? authController})
    : authController = authController ?? AuthController();

  @override
  State<DailyForecastScreen> createState() => _DailyForecastScreenState();
}

class _DailyForecastScreenState extends State<DailyForecastScreen> {
  final _titles = ['Today', 'Hourly', 'Weekly'];
  int _selectedIndex = 0;

  late final WeatherService _weatherService;
  final NotificationService _notificationService = NotificationService();
  List<HourlyForecast> _hourly = [];
  List<DailyForecast> _daily = [];
  bool _loading = true;
  String? _error;
  String _cityName = '';
  Map<String, dynamic>? _rawData;

  // Settings listener fields
  SettingsController? _settings;
  String? _lastUnits;
  bool? _lastUseLocation;
  String? _lastManualLocation;

  @override
  void initState() {
    super.initState();
    const apiKey = String.fromEnvironment(
      'OPENWEATHER_API_KEY',
      defaultValue: '4a5003fd6f81c1b15a3472d2ad89f92e',
    );
    // debug-only: run DB test in debug builds (use kDebugMode instead of assert wrapper)
    if (kDebugMode) runDbTest();
    _weatherService = WeatherService(apiKey);
    // If API key not set, populate with sample data so UI stays responsive.
    if (apiKey == 'YOUR_API_KEY') {
      _hourly = const [
        HourlyForecast(time: 'Now', temp: '22°C', icon: '01d'),
        HourlyForecast(time: '13:00', temp: '21°C', icon: '02d'),
        HourlyForecast(time: '14:00', temp: '21°C', icon: '03d'),
        HourlyForecast(time: '15:00', temp: '20°C', icon: '04d'),
        HourlyForecast(time: '16:00', temp: '19°C', icon: '10d'),
        HourlyForecast(time: '17:00', temp: '18°C', icon: '10d'),
        HourlyForecast(time: '18:00', temp: '17°C', icon: '10d'),
        HourlyForecast(time: '19:00', temp: '16°C', icon: '10d'),
        HourlyForecast(time: '20:00', temp: '15°C', icon: '10d'),
      ];
      _daily = const [
        DailyForecast(day: 'Mon', high: '25°C', low: '18°C', icon: '01d'),
        DailyForecast(day: 'Tue', high: '23°C', low: '17°C', icon: '02d'),
        DailyForecast(day: 'Wed', high: '20°C', low: '15°C', icon: '03d'),
        DailyForecast(day: 'Thu', high: '21°C', low: '16°C', icon: '04d'),
        DailyForecast(day: 'Fri', high: '19°C', low: '14°C', icon: '10d'),
        DailyForecast(day: 'Sat', high: '24°C', low: '17°C', icon: '01d'),
      ];
      _loading = false;
    } else {
      // initial load will respect settings in _loadWithLocation()
      // _loadWithLocation may be called later from didChangeDependencies when settings are available
      _loadWithLocation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attach settings controller and a listener so we can react to changes
    final s = context.read<SettingsController>();
    if (_settings != s) {
      _settings?.removeListener(_onSettingsChanged);
      _settings = s;
      _lastUnits = _settings?.units;
      _lastUseLocation = _settings?.useLocation;
      _lastManualLocation = _settings?.location;
      _settings?.addListener(_onSettingsChanged);
    }
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    // UI-level changes (theme, toggles) rebuild automatically when widgets use context.watch;
    // force rebuild to reflect any non-watched UI pieces
    setState(() {});

    // Decide whether to reload data
    final s = _settings;
    if (s == null) return;
    final unitsChanged = s.units != _lastUnits;
    final useLocationChanged = s.useLocation != _lastUseLocation;
    final manualLocChanged = s.location != _lastManualLocation;

    if (unitsChanged || useLocationChanged || manualLocChanged) {
      _lastUnits = s.units;
      _lastUseLocation = s.useLocation;
      _lastManualLocation = s.location;
      _loadWithLocation();
    }
  }

  Future<void> _loadWithLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final settings =
          (_settings ?? context.read<SettingsController>()) as dynamic;
      final unitsPref = settings.units as String;
      final useLocationPref = settings.useLocation as bool;
      final manualLocation = (settings.location as String).trim();

      // If user prefers manual location and provided one, try using it.
      if (!useLocationPref && manualLocation.isNotEmpty) {
        // If manual location looks like "lat,lon", parse and fetch by coordinates
        final parts = manualLocation.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lon = double.tryParse(parts[1].trim());
          if (lat != null && lon != null) {
            final res = await _weatherService.fetchForecast(
              lat,
              lon,
              unitsPref,
            );
            final city = await _weatherService.reverseGeocode(lat, lon);
            setState(() {
              _hourly = List<HourlyForecast>.from(res['hourly'] ?? []);
              _daily = List<DailyForecast>.from(res['daily'] ?? []);
              _rawData = (res['raw'] as Map<String, dynamic>?);
              _cityName = city.isNotEmpty
                  ? city
                  : ((res['city'] as String?) ?? '');
              _loading = false;
            });
            return;
          }
        }

        // If manual location is a text query (city name), try fetchForecastByQuery if available
        try {
          final res = await _weatherService.fetchForecastByQuery(
            manualLocation,
            units: unitsPref,
          );
          final city = (res['city'] as String?) ?? manualLocation;
          setState(() {
            _hourly = List<HourlyForecast>.from(res['hourly'] ?? []);
            _daily = List<DailyForecast>.from(res['daily'] ?? []);
            _rawData = (res['raw'] as Map<String, dynamic>?);
            _cityName = city;
            _loading = false;
            _error = null;
          });
          return;
        } catch (e, st) {
          // Surface the error so user sees why the manual query failed instead of
          // silently falling back to device location.
          developer.log(
            'fetchForecastByQuery failed for "$manualLocation": $e\n$st',
            name: 'DailyForecastScreen._loadWithLocation',
          );
          final message = 'Failed to fetch forecast for "$manualLocation": $e';
          if (mounted) {
            Helpers.showSnackBar(context, message, isError: true);
          }
          setState(() {
            _error = message;
            _loading = false;
          });
          return;
        }
      }

      // Default: use device location
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied ||
            req == LocationPermission.deniedForever) {
          setState(() {
            _error = 'Location permission denied';
            _loading = false;
          });
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final res = await _weather_service_fetchSafe(
        pos.latitude,
        pos.longitude,
        unitsPref,
      );
      final city = await _weather_service_reverseSafe(
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        _hourly = List<HourlyForecast>.from(res['hourly'] ?? []);
        _daily = List<DailyForecast>.from(res['daily'] ?? []);
        _rawData = (res['raw'] as Map<String, dynamic>?) ?? null;
        _cityName = city.isNotEmpty ? city : ((res['city'] as String?) ?? '');
        _loading = false;
        // debug: confirm API-derived counts
        // ignore: avoid_print
        print(
          'fetchForecast => city: $_cityName, hourly: ${_hourly.length}, daily: ${_daily.length}',
        );
      });

      // Alert detection + optional notification trigger
      try {
        final settings =
            (_settings ?? context.read<SettingsController>()) as dynamic;
        if ((settings.weatherNotificationsEnabled as bool) &&
            _rawData != null) {
          final alert = _weatherService.detectAlertsFromForecast(
            _rawData!,
            settings,
          );
          final summary = (alert['summary'] as String?) ?? '';
          final exceeds = alert['exceedsThreshold'] as bool? ?? false;
          final hasStorm = alert['hasStorm'] as bool? ?? false;
          final heavyRain = alert['heavyRain'] as bool? ?? false;
          if (summary.isNotEmpty) {
            // Try to call server endpoint to send notification. Endpoint is expected
            // to be provided via compile-time environment variable WEATHER_NOTIFICATION_ENDPOINT
            final endpointStr = const String.fromEnvironment(
              'WEATHER_NOTIFICATION_ENDPOINT',
              defaultValue: '',
            );
            if (endpointStr.isNotEmpty) {
              final uri = Uri.tryParse(endpointStr);
              if (uri != null) {
                final title = 'Weather alert for $_cityName';
                final body = summary;
                // prefer topic unless a server needs token targeting; include token for user-specific
                final token = settings.fcmToken as String?;
                _notificationService.requestSendNotification(
                  endpoint: uri,
                  topic: 'weather_alerts',
                  token: token,
                  title: title,
                  body: body,
                  data: {
                    'city': _cityName,
                    'hasStorm': hasStorm.toString(),
                    'heavyRain': heavyRain.toString(),
                    'exceeds': exceeds.toString(),
                  },
                );
              } else {
                if (kDebugMode)
                  print('Invalid WEATHER_NOTIFICATION_ENDPOINT: $endpointStr');
              }
            } else {
              if (kDebugMode) {
                print(
                  'Weather notifications enabled but WEATHER_NOTIFICATION_ENDPOINT not set.',
                );
              }
            }
          }
        }
      } catch (e) {
        developer.log(
          'Notification trigger failed: $e',
          name: 'DailyForecastScreen.alert',
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Helper to call fetchForecast and trap errors / ensure units param supported
  Future<Map<String, dynamic>> _weather_service_fetchSafe(
    double lat,
    double lon,
    String units,
  ) async {
    try {
      return await _weatherService.fetchForecast(lat, lon, units);
    } catch (_) {
      // fallback: try without units param if service doesn't support it
      return await _weatherService.fetchForecast(lat, lon, units);
    }
  }

  // Helper to call reverseGeocode and trap errors
  Future<String> _weather_service_reverseSafe(double lat, double lon) async {
    try {
      return await _weatherService.reverseGeocode(lat, lon);
    } catch (_) {
      return '';
    }
  }

  void _onMenuSelected(String value) async {
    if (value == 'settings') {
      // When returning from settings we still rely on the settings listener to reload data,
      // but push the screen so user can make changes.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      return;
    }
    if (value == 'logout') {
      try {
        await widget.authController.signOut();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SigninScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _settings?.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final dsettings = settings as dynamic;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            tooltip: dsettings.weatherNotificationsEnabled
                ? 'Weather alerts enabled'
                : 'Weather alerts disabled',
            icon: Icon(
              dsettings.weatherNotificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildBody(),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Hourly'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week),
            label: 'Weekly',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));

    final city = _cityName.isNotEmpty ? _cityName : 'San Francisco';
    final current = _hourly.isNotEmpty ? _hourly.first.temp : 'N/A';

    if (_selectedIndex == 1) return _hourlyFullView(city, current);
    if (_selectedIndex == 2) return _weeklyFullView(city, current);
    return _todayView(city, current);
  }

  Widget _todayView(String city, String current) {
    final preview = _hourly.where((h) => h.time != 'Now').take(4).toList();
    final todayMin = _daily.isNotEmpty ? _daily.first.low : null;
    final todayMax = _daily.isNotEmpty ? _daily.first.high : null;
    return Column(
      children: [
        _todayConditionWidget(),
        const SizedBox(height: 8),
        Expanded(
          child: TodayScreen(
            city: city,
            hourlyPreview: preview,
            weekly: _daily,
            min: todayMin,
            max: todayMax,
          ),
        ),
      ],
    );
  }

  Widget _hourlyFullView(String city, String current) {
    final data = _hourly.where((h) => h.time != 'Now').take(9).toList();
    return HourlyScreen(city: city, hourly: data);
  }

  Widget _weeklyFullView(String city, String current) {
    final data = _daily.take(6).toList();
    return WeeklyScreen(city: city, weekly: data);
  }

  Widget _todayConditionWidget() {
    try {
      if (_rawData == null) return const SizedBox.shrink();
      final list = (_rawData!['list'] as List<dynamic>?) ?? [];
      if (list.isEmpty) return const SizedBox.shrink();

      // find today's entries (local date)
      final now = DateTime.now();
      final todayEntries = list.where((e) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          (e['dt'] as int) * 1000,
          isUtc: true,
        ).toLocal();
        return dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day;
      }).toList();
      if (todayEntries.isEmpty) return const SizedBox.shrink();

      // prefer an entry where weather.main == 'Clouds'
      dynamic chosen;
      for (var e in todayEntries) {
        final weather = (e['weather'] as List).isNotEmpty
            ? e['weather'][0]
            : null;
        if (weather != null &&
            (weather['main'] as String?)?.toLowerCase() == 'clouds') {
          chosen = weather;
          break;
        }
      }
      // fallback to first today's weather or first overall
      if (chosen == null) {
        final fallback = todayEntries.isNotEmpty
            ? todayEntries.first
            : list.first;
        chosen = (fallback['weather'] as List).isNotEmpty
            ? fallback['weather'][0]
            : null;
      }
      if (chosen == null) return const SizedBox.shrink();

      final main = (chosen['main'] as String?) ?? '';
      final description = (chosen['description'] as String?) ?? '';
      final icon = (chosen['icon'] as String?) ?? '';
      final iconUrl = 'https://openweathermap.org/img/wn/$icon@2x.png';

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon.isNotEmpty)
              Image.network(
                iconUrl,
                width: 48,
                height: 48,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 48, height: 48),
              ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  main,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

// Reuse ForecastTile widget
class ForecastTile extends StatelessWidget {
  final String top;
  final IconData icon;
  final String bottom;
  const ForecastTile({
    super.key,
    required this.top,
    required this.icon,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(top, style: const TextStyle(fontSize: 12)),
          Icon(icon, color: Theme.of(context).primaryColor, size: 22),
          Text(
            bottom,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// Lightweight line chart painter (kept small)
class LineChart extends StatelessWidget {
  final List<int> seriesA;
  final List<int> seriesB;
  final List<String> labels;
  final Color colorA;
  final Color colorB;
  const LineChart({
    super.key,
    required this.seriesA,
    required this.seriesB,
    required this.labels,
    this.colorA = Colors.red,
    this.colorB = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 140),
      painter: _LinePainter(
        seriesA: seriesA,
        seriesB: seriesB,
        labels: labels,
        colorA: colorA,
        colorB: colorB,
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<int> seriesA;
  final List<int> seriesB;
  final List<String> labels;
  final Color colorA;
  final Color colorB;
  _LinePainter({
    required this.seriesA,
    required this.seriesB,
    required this.labels,
    required this.colorA,
    required this.colorB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()
      ..color = colorA
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final paintB = Paint()
      ..color = colorB
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final axis = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    final all = <int>[]
      ..addAll(seriesA)
      ..addAll(seriesB);
    if (all.isEmpty) return;
    final minV = all.reduce((a, b) => a < b ? a : b).toDouble();
    final maxV = all.reduce((a, b) => a > b ? a : b).toDouble();
    final vRange = (maxV - minV) == 0 ? 1 : (maxV - minV);

    final left = 20.0;
    final bottom = 24.0;
    final w = size.width - left - 8;
    final h = size.height - bottom - 8;

    for (int i = 0; i <= 3; i++) {
      final y = 8 + h * (i / 3);
      canvas.drawLine(Offset(left, y), Offset(left + w, y), axis);
    }

    Offset map(int index, int value, int count) {
      final x = left + (w) * (index / (count - 1));
      final y = 8 + h * (1 - ((value - minV) / vRange));
      return Offset(x, y);
    }

    final pathA = Path();
    for (var i = 0; i < seriesA.length; i++) {
      final p = map(i, seriesA[i], seriesA.length);
      if (i == 0)
        pathA.moveTo(p.dx, p.dy);
      else
        pathA.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(pathA, paintA);

    final pathB = Path();
    for (var i = 0; i < seriesB.length; i++) {
      final p = map(i, seriesB[i], seriesB.length);
      if (i == 0)
        pathB.moveTo(p.dx, p.dy);
      else
        pathB.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(pathB, paintB);

    final dotA = Paint()..color = colorA;
    final dotB = Paint()..color = colorB;
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (var i = 0; i < labels.length; i++) {
      final la = labels[i];
      final pA = map(i, seriesA[i], labels.length);
      final pB = map(i, seriesB[i], labels.length);
      // draw dots for both series
      canvas.drawCircle(pA, 3, dotA);
      canvas.drawCircle(pB, 3, dotB);
      tp.text = TextSpan(
        text: la,
        style: const TextStyle(color: Colors.black, fontSize: 11),
      );
      tp.layout(maxWidth: 60);
      tp.paint(canvas, Offset(pA.dx - tp.width / 2, size.height - bottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
