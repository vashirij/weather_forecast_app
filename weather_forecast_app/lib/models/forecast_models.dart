// Simple forecast data models used across the app
class HourlyForecast {
  final String time;
  final String temp; // formatted like '22°C'
  final String icon; // standardized icon code (UI may map to IconData)

  const HourlyForecast({
    required this.time,
    required this.temp,
    required this.icon,
  });
}

class DailyForecast {
  final String day;
  final String high; // formatted like '25°C'
  final String low; // formatted like '18°C'
  final String icon;

  const DailyForecast({
    required this.day,
    required this.high,
    required this.low,
    required this.icon,
  });
}
