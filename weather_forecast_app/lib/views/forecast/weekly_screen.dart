import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/forecast_models.dart';
import '../../widgets/simple_chart.dart';
import 'package:weather_forecast_app/controllers/setting_controller.dart';

const double _kTileW = 110.0;
const double _kTileH = 120.0;

class WeeklyScreen extends StatelessWidget {
  final String city;
  final List<DailyForecast> weekly;
  const WeeklyScreen({super.key, required this.city, required this.weekly});

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
                weekly.isNotEmpty ? formatTemp(weekly.first.high) : 'N/A',
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
                .map(
                  (d) => TileSmall(
                    top: d.day,
                    high: formatTemp(d.high),
                    low: formatTemp(d.low),
                  ),
                )
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tempStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ) ??
        TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.45)
                : Colors.black.withOpacity(0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            top,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ) ??
                TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          Icon(
            Icons.wb_sunny,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
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
