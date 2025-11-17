import '../../services/db_test.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/auth_controller.dart';
import '../auth/signin_screen.dart';
import '../settings/settings_screen.dart';
import '../../models/forecast_models.dart';
import '../../services/weather_service.dart';
import 'today_screen.dart';
import 'hourly_screen.dart';
import 'weekly_screen.dart';

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
  List<HourlyForecast> _hourly = [];
  List<DailyForecast> _daily = [];
  bool _loading = true;
  String? _error;
  String _cityName = '';

  @override
  void initState() {
    super.initState();
    const apiKey = String.fromEnvironment(
      'OPENWEATHER_API_KEY',
      defaultValue: '4a5003fd6f81c1b15a3472d2ad89f92e',
    );
    // debug-only: run DB test in debug builds
    assert(() {
      runDbTest();
      return true;
    }());
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
      _loadWithLocation();
    }
  }

  Future<void> _loadWithLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
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
      final res = await _weatherService.fetchForecast(
        pos.latitude,
        pos.longitude,
      );
      final city = await _weatherService.reverseGeocode(
        pos.latitude,
        pos.longitude,
      );
      setState(() {
        _hourly = List<HourlyForecast>.from(res['hourly'] ?? []);
        _daily = List<DailyForecast>.from(res['daily'] ?? []);
        _cityName = city.isNotEmpty ? city : ((res['city'] as String?) ?? '');
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onMenuSelected(String value) async {
    if (value == 'settings') {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
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
    return TodayScreen(
      city: city,
      hourlyPreview: preview,
      weekly: _daily,
      min: todayMin,
      max: todayMax,
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
