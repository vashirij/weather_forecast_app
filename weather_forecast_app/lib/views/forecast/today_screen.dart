import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/forecast_models.dart';
import 'package:weather_forecast_app/controllers/setting_controller.dart';

const Color _kPrimary = Color(0xFF0A3D62);
const double _kTileW = 110.0;
const double _kTileH = 120.0;

class TodayScreen extends StatelessWidget {
  final String city;
  final List<HourlyForecast> hourlyPreview; // 4 items
  final List<DailyForecast> weekly;
  final String? min;
  final String? max;

  // Optional "feels like" temperature to show just below city
  final String? feelsLike;

  // Optional API-provided condition fields
  final String? conditionMain;
  final String? conditionDescription;
  final String? conditionIcon; // e.g. "04n"

  const TodayScreen({
    super.key,
    required this.city,
    required this.hourlyPreview,
    required this.weekly,
    this.min,
    this.max,
    this.feelsLike,
    this.conditionMain,
    this.conditionDescription,
    this.conditionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final unitSuffix = settings.units == 'imperial' ? '°F' : '°C';
    final currentRaw = hourlyPreview.isNotEmpty
        ? hourlyPreview.first.temp
        : null;
    String formatTemp(String? raw) {
      if (raw == null || raw.isEmpty) return 'N/A';
      // try to extract numeric part and reformat with unit suffix
      final cleaned = raw.replaceAll(RegExp(r'[^0-9\.-]'), '');
      final n = double.tryParse(cleaned);
      if (n != null) return '${n.round()}$unitSuffix';
      // fallback: replace existing ° symbol
      final replaced = raw.replaceAll(RegExp(r'°[CF]'), unitSuffix);
      if (replaced == raw) return '$raw$unitSuffix';
      return replaced;
    }

    final current = formatTemp(currentRaw);

    Widget _buildCondition() {
      // If API condition available, show it (icon + main + description)
      if ((conditionMain != null && conditionMain!.isNotEmpty) ||
          (conditionIcon != null && conditionIcon!.isNotEmpty)) {
        final iconUrl = (conditionIcon != null && conditionIcon!.isNotEmpty)
            ? 'https://openweathermap.org/img/wn/${conditionIcon}@2x.png'
            : null;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconUrl != null)
              Image.network(
                iconUrl,
                width: 36,
                height: 36,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 36, height: 36),
              ),
            if (iconUrl != null) const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conditionMain ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (conditionDescription != null &&
                    conditionDescription!.isNotEmpty)
                  Text(
                    conditionDescription!,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
              ],
            ),
          ],
        );
      }

      // Fallback chip when no API condition provided
      return Chip(
        label: const Text('Condition: -'),
        backgroundColor: _kPrimary.withOpacity(0.08),
      );
    }

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
                // Feels-like immediately under city (smaller, subtle)
                if (feelsLike != null && feelsLike!.isNotEmpty)
                  Text(
                    'Feels like: ${formatTemp(feelsLike)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                if (feelsLike != null && feelsLike!.isNotEmpty)
                  const SizedBox(height: 6),
                // Main current temperature (large)
                Text(
                  current,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                // Show max above min on Today header
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Max: ${max != null ? formatTemp(max) : '-'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Min: ${min != null ? formatTemp(min) : '-'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildCondition(),
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
                      child: TileSmall(
                        top: it.time,
                        bottom: formatTemp(it.temp),
                        iconCode: it.icon,
                      ),
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
                      child: TileSmall(
                        top: w.day,
                        bottom: formatTemp(w.high),
                        iconCode: w.icon,
                      ),
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
  final String? iconCode; // optional OpenWeather icon code

  const TileSmall({
    super.key,
    required this.top,
    required this.bottom,
    this.iconCode,
  });

  @override
  Widget build(BuildContext context) {
    Widget leading;
    if (iconCode != null && iconCode!.isNotEmpty) {
      final iconUrl = 'https://openweathermap.org/img/wn/${iconCode}@2x.png';
      leading = Image.network(
        iconUrl,
        width: 28,
        height: 28,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.wb_sunny, color: _kPrimary, size: 22),
      );
    } else {
      leading = const Icon(Icons.wb_sunny, color: _kPrimary, size: 22);
    }

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
          leading,
          Text(
            bottom,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
