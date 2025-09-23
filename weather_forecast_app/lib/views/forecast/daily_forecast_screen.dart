import 'package:flutter/material.dart';

class DailyForecastScreen extends StatelessWidget {
  const DailyForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Forecast")),
      body: const Center(
        child: Text(
          "Daily Forecast Data Here",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
