import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/forecast_models.dart';
import '../../widgets/simple_chart.dart';
import 'package:weather_forecast_app/controllers/setting_controller.dart';

const Color _kPrimaryH = Color(0xFF0A3D62);
const double _kTileW = 110.0;
const double _kTileH = 120.0;

class HourlyScreen extends StatelessWidget {
  final String city;
  final List<HourlyForecast> hourly;
  const HourlyScreen({super.key, required this.city, required this.hourly});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final unitSuffix = settings.units == 'imperial' ? '°F' : '°C';
    String formatTemp(String raw) {
      if (raw.isEmpty) return 'N/A';
      final cleaned = raw.replaceAll(RegExp(r'[^0-9\.-]'), '');
      final n = int.tryParse(cleaned) ?? (double.tryParse(cleaned)?.round());
      if (n != null) return '${n}$unitSuffix';
      return raw.replaceAll(RegExp(r'°[CF]'), unitSuffix);
    }

    final chartItems = hourly.take(5).toList();
    final labels = chartItems.map((e) => e.time).toList();
    final highs = chartItems
        .map(
          (e) => int.tryParse(e.temp.replaceAll(RegExp(r'[^0-9\-]'), '')) ?? 0,
        )
        .toList();
    // create a lows series by subtracting 2 degrees (approx) so chart shows min line
    final lows = highs.map((v) => v - 2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Text(
                hourly.isNotEmpty ? formatTemp(hourly.first.temp) : 'N/A',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SimpleLineChart(
          seriesA: highs,
          seriesB: lows,
          labels: labels,
          colorA: Colors.orange,
          colorB: Colors.blue,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: _kTileW / _kTileH,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: hourly
                .take(9)
                .map((h) => TileSmall(top: h.time, bottom: formatTemp(h.temp)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class TileSmall extends StatelessWidget {
  final String top;
  final String bottom;
  const TileSmall({super.key, required this.top, required this.bottom});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(top, style: const TextStyle(fontSize: 12)),
          const Icon(Icons.wb_sunny, color: _kPrimaryH, size: 22),
          Text(
            bottom,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
