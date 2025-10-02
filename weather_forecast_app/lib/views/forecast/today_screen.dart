import 'package:flutter/material.dart';
import '../../models/forecast_models.dart';

const Color _kPrimary = Color(0xFF0A3D62);
const double _kTileW = 110.0;
const double _kTileH = 120.0;

class TodayScreen extends StatelessWidget {
  final String city;
  final List<HourlyForecast> hourlyPreview; // 4 items
  final List<DailyForecast> weekly;
  final String? min;
  final String? max;

  const TodayScreen({
    super.key,
    required this.city,
    required this.hourlyPreview,
    required this.weekly,
    this.min,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    final current = hourlyPreview.isNotEmpty ? hourlyPreview.first.temp : 'N/A';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  current,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                // Show max above min on Today header, same font style for consistency
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Max: ${max ?? '-'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Min: ${min ?? '-'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Chip(
                  label: Text('Rain: -'),
                  backgroundColor: _kPrimary.withOpacity(0.08),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                height: _kTileH,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: hourlyPreview.length,
                  itemBuilder: (context, index) {
                    final it = hourlyPreview[index];
                    return SizedBox(
                      width: _kTileW,
                      child: TileSmall(top: it.time, bottom: it.temp),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                height: _kTileH,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: weekly.length,
                  itemBuilder: (context, index) {
                    final w = weekly[index];
                    return SizedBox(
                      width: _kTileW,
                      child: TileSmall(top: w.day, bottom: w.high),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
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
          const Icon(Icons.wb_sunny, color: _kPrimary, size: 22),
          Text(
            bottom,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
