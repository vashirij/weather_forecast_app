import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_forecast_app/controllers/setting_controller.dart';
import '../../services/weather_service.dart';

class SettingsScreen extends StatefulWidget {
  /// Optional initial settings map:
  /// { 'units': 'metric'|'imperial', 'theme': 'system'|'light'|'dark',
  ///   'useLocation': bool, 'location': String }
  final Map<String, dynamic>? initialSettings;

  const SettingsScreen({super.key, this.initialSettings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _locationController;
  late SettingsController _ctrl;
  bool _inittedFromWidget = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl = context.read<SettingsController>();
    // if caller passed initialSettings, apply them once (keeps compatibility)
    if (!_inittedFromWidget && widget.initialSettings != null) {
      final init = widget.initialSettings!;
      if ((init['units'] as String?) != null)
        _ctrl.setUnits(init['units'] as String);
      if ((init['theme'] as String?) != null)
        _ctrl.setTheme(init['theme'] as String);
      if ((init['useLocation'] as bool?) != null)
        _ctrl.setUseLocation(init['useLocation'] as bool);
      if ((init['location'] as String?) != null)
        _ctrl.setLocation((init['location'] as String).trim());
      _inittedFromWidget = true;
    }
    _locationController.text = _ctrl.location;
    _ctrl.addListener(_syncFromController);
    // ensure our text controller updates the settings controller when user types
    _locationController.removeListener(_onLocationControllerChanged);
    _locationController.addListener(_onLocationControllerChanged);
  }

  void _onLocationControllerChanged() {
    // Keep settings in sync with text field input
    if (!mounted) return;
    try {
      final txt = _locationController.text;
      // Use read to avoid rebuilding while typing; write to controller directly
      final c = context.read<SettingsController>();
      if (c.location != txt) c.setLocation(txt);
    } catch (_) {}
  }

  void _syncFromController() {
    if (!mounted) return;
    if (_locationController.text != _ctrl.location) {
      _locationController.text = _ctrl.location;
    }
    setState(() {}); // refresh UI for other setting changes
  }

  @override
  void dispose() {
    _ctrl.removeListener(_syncFromController);
    _locationController.dispose();
    super.dispose();
  }

  void _onDone() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SettingsController>();
    final dctrl = ctrl as dynamic;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _onDone,
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Units',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  value: 'metric',
                  groupValue: dctrl.units,
                  title: const Text('Celsius'),
                  onChanged: (v) => dctrl.setUnits(v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  value: 'imperial',
                  groupValue: dctrl.units,
                  title: const Text('Fahrenheit'),
                  onChanged: (v) => dctrl.setUnits(v!),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text(
            'Theme',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: ctrl.theme,
            items: const [
              DropdownMenuItem(value: 'system', child: Text('System')),
              DropdownMenuItem(value: 'light', child: Text('Light')),
              DropdownMenuItem(value: 'dark', child: Text('Dark')),
            ],
            onChanged: (v) => ctrl.setTheme(v ?? 'system'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const Divider(height: 24),
          const Text(
            'Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Use device location'),
            value: dctrl.useLocation,
            onChanged: (v) => dctrl.setUseLocation(v),
          ),
          const SizedBox(height: 8),
          // Autocomplete field that suggests cities from WeatherService
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              final text = textEditingValue.text;
              if (text.isEmpty || dctrl.useLocation) return const <String>[];
              try {
                final svc = WeatherService(
                  const String.fromEnvironment(
                    'OPENWEATHER_API_KEY',
                    defaultValue: '4a5003fd6f81c1b15a3472d2ad89f92e',
                  ),
                );
                final results = await svc.searchCities(text);
                return results;
              } catch (_) {
                return const <String>[];
              }
            },
            displayStringForOption: (s) => s,
            onSelected: (selection) {
              _locationController.text = selection;
              dctrl.setLocation(selection);
              // Close settings so the selection is applied immediately
              Navigator.of(context).pop();
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              // Use the state controller so listeners are stable across hot reloads
              return TextField(
                controller: _locationController,
                focusNode: focusNode,
                enabled: !ctrl.useLocation,
                decoration: const InputDecoration(
                  labelText: 'Manual location (city, state or lat,lon)',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                      maxWidth: 400,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final opt = options.elementAt(index);
                        return ListTile(
                          title: Text(opt),
                          onTap: () {
                            onSelected(opt);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.bookmark_add_outlined),
                            onPressed: () async {
                              // Await persistence, show feedback, then close settings safely
                              await dctrl.addSavedCity(opt);
                              _locationController.clear();
                              await dctrl.setLocation('');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved city')),
                              );
                              // Pop after the current frame to avoid Autocomplete overlay assertions
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) Navigator.of(context).pop();
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Weather alerts'),
            subtitle: const Text(
              'Receive notifications for storms, heavy rain, or high temperatures',
            ),
            value: dctrl.weatherNotificationsEnabled,
            onChanged: (v) => dctrl.setWeatherNotificationsEnabled(v),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (_) {
              final min = dctrl.units == 'metric' ? -10.0 : 14.0;
              final max = dctrl.units == 'metric' ? 50.0 : 122.0;
              final value = (dctrl.highTempThreshold as double)
                  .clamp(min, max)
                  .toDouble();
              final divisions = (max - min).toInt();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('High temperature threshold')),
                      Text(
                        '${value.toStringAsFixed(0)}°${ctrl.units == 'metric' ? 'C' : 'F'}',
                      ),
                    ],
                  ),
                  Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions > 0 ? divisions : null,
                    label: '${value.toStringAsFixed(0)}°',
                    onChanged: (v) => dctrl.setHighTempThreshold(v),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Search cities',
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      final svc = WeatherService(
                        const String.fromEnvironment(
                          'OPENWEATHER_API_KEY',
                          defaultValue: '4a5003fd6f81c1b15a3472d2ad89f92e',
                        ),
                      );
                      final q = await showDialog<String?>(
                        context: context,
                        builder: (ctx) {
                          final tctrl = TextEditingController();
                          return AlertDialog(
                            title: const Text('Search cities'),
                            content: TextField(
                              controller: tctrl,
                              decoration: const InputDecoration(
                                hintText: 'Enter city name',
                              ),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(null),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(tctrl.text.trim()),
                                child: const Text('Search'),
                              ),
                            ],
                          );
                        },
                      );
                      if (q == null || q.isEmpty) return;
                      // show results
                      showDialog<void>(
                        context: context,
                        builder: (ctx) {
                          return FutureBuilder<List<String>>(
                            future: svc.searchCities(q),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting)
                                return const AlertDialog(
                                  content: SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                );
                              if (snap.hasError)
                                return AlertDialog(
                                  title: const Text('Error'),
                                  content: Text('${snap.error}'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              final results = snap.data ?? [];
                              return AlertDialog(
                                title: const Text('Results'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: results.length,
                                    itemBuilder: (context, index) {
                                      final item = results[index];
                                      return ListTile(
                                        title: Text(item),
                                        onTap: () {
                                          ctrl.setLocation(item);
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context).pop();
                                        },
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.bookmark_add_outlined,
                                          ),
                                          onPressed: () async {
                                            await dctrl.addSavedCity(item);
                                            _locationController.clear();
                                            await dctrl.setLocation('');
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Saved city'),
                                              ),
                                            );
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (mounted)
                                                    Navigator.of(ctx).pop();
                                                  if (mounted)
                                                    Navigator.of(context).pop();
                                                });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                ],
              ),
              IconButton(
                tooltip: 'Add to saved cities',
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: dctrl.useLocation
                    ? null
                    : () async {
                        final v = _locationController.text.trim();
                        if (v.isNotEmpty) {
                          await dctrl.addSavedCity(v);
                          _locationController.clear();
                          await dctrl.setLocation('');
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved city')),
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) Navigator.of(context).pop();
                          });
                        }
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dctrl.savedCities.isNotEmpty) ...[
            const Text(
              'Saved cities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Show saved cities as a list with a checkbox to indicate the selected city
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dctrl.savedCities.length,
              itemBuilder: (context, index) {
                final c = dctrl.savedCities[index];
                final selected = dctrl.location == c;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  leading: Checkbox(
                    value: selected,
                    onChanged: (_) {
                      dctrl.setLocation(c);
                      // navigate back so DailyForecast picks up through listener
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Text(c),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => dctrl.removeSavedCity(c),
                  ),
                  onTap: () {
                    dctrl.setLocation(c);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Reset preferences'),
            onPressed: () async {
              await ctrl.clearAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preferences reset to defaults'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
