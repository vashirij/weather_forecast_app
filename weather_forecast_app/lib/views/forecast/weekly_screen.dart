import 'package:flutter/material.dart';
import '../../models/forecast_models.dart';
import '../../widgets/simple_chart.dart';

const Color _kPrimaryW = Color(0xFF0A3D62);
const double _kTileW = 110.0;
const double _kTileH = 120.0;

class WeeklyScreen extends StatelessWidget {
  final String city;
  final List<DailyForecast> weekly;
  const WeeklyScreen({super.key, required this.city, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final chartItems = weekly.take(5).toList();
    final labels = chartItems.map((d) => d.day).toList();
    final highs = chartItems
        .map(
          (d) => int.tryParse(d.high.replaceAll(RegExp(r'[^0-9\-]'), '')) ?? 0,
        )
        .toList();
    final lows = chartItems
        .map(
          (d) => int.tryParse(d.low.replaceAll(RegExp(r'[^0-9\-]'), '')) ?? 0,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Text(
                city,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                weekly.isNotEmpty ? weekly.first.high : 'N/A',
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
          colorA: Colors.red,
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
            children: weekly
                .take(6)
                .map((d) => TileSmall(top: d.day, high: d.high, low: d.low))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class TileSmall extends StatelessWidget {
  final String top;
  final String high;
  final String low;
  const TileSmall({
    super.key,
    required this.top,
    required this.high,
    required this.low,
  });

  @override
  Widget build(BuildContext context) {
    const tempStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );
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
          const Icon(Icons.wb_sunny, color: _kPrimaryW, size: 22),
          Column(
            children: [
              Text(high, style: tempStyle),
              const SizedBox(height: 4),
              Text(low, style: tempStyle),
            ],
          ),
        ],
      ),
    );
  }
}
