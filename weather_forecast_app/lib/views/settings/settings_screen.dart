import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Units',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Text('Celsius'),
                SizedBox(width: 12),
                Text('Fahrenheit'),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () {}, child: const Text('Clear Cache')),
          ],
        ),
      ),
    );
  }
}
