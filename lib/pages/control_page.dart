import 'package:flutter/material.dart';
import '../models/lab_models.dart';
import '../services/lab_repository.dart';
import '../widgets/common_widgets.dart';

class ControlPage extends StatelessWidget {
  final LabRepository repository;
  const ControlPage({super.key, required this.repository});

  Future<void> sendCommand(BuildContext context, String action) async {
    try {
      await repository.sendCommand(action);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Command not confirmed. Check the device connection.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = repository.reading;
    final enabled = repository.online && !repository.commandPending && repository.error == null;
    final alarmState = reading == null ? 'N/A' : reading.alarm ? 'ON' : 'OFF';
    final confirmed = repository.online && reading != null && repository.settings.matches(reading.settings);
    return PageContent(children: [
      StatusCard(repository: repository),
      sectionTitle('Alarm control'),
      dataCard('Buzzer', alarmState, Icons.volume_up),
      dataCard('Warning light', alarmState, Icons.lightbulb),
      const Padding(padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Buzzer and light share one relay. A manual test lasts 10 seconds.')),
      ElevatedButton(
        onPressed: enabled ? () => sendCommand(context, 'test_alarm') : null,
        child: const Text('Test Alarm (10 seconds)'),
      ),
      OutlinedButton(
        onPressed: enabled ? () => sendCommand(context, 'stop_test') : null,
        child: const Text('Stop Test'),
      ),
      if (repository.commandMessage != null)
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(repository.commandMessage!)),
      if (!repository.online) const Text('Connect the ESP32 to enable control.'),
      const SizedBox(height: 12),
      const Card(child: ListTile(
        leading: Icon(Icons.security, color: Colors.green),
        title: Text('Automatic alarm enabled'),
        subtitle: Text('Detected hazards activate the alarm on the ESP32. Stop Test cannot silence an active hazard alarm.'),
      )),
      sectionTitle('Alarm thresholds'),
      Card(child: Column(children: [
        ListTile(title: const Text('Temperature ON / clear'),
          subtitle: Text('${repository.settings.temperatureHigh} °C / ${repository.settings.temperatureClear} °C')),
        ListTile(title: const Text('Gas ON / clear'),
          subtitle: Text('${repository.settings.gasHigh} / ${repository.settings.gasClear} raw')),
        ListTile(title: const Text('Settings status'),
          subtitle: Text(confirmed ? 'Confirmed by ESP32' : 'Waiting for ESP32 confirmation')),
      ])),
      OutlinedButton(
        onPressed: enabled ? () => showDialog<void>(
          context: context, barrierDismissible: false,
          builder: (_) => ThresholdDialog(repository: repository)) : null,
        child: const Text('Edit Thresholds'),
      ),
    ]);
  }
}

class ThresholdDialog extends StatefulWidget {
  final LabRepository repository;
  const ThresholdDialog({super.key, required this.repository});
  @override
  State<ThresholdDialog> createState() => _ThresholdDialogState();
}

class _ThresholdDialogState extends State<ThresholdDialog> {
  late final List<TextEditingController> controllers;
  bool saving = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    final settings = widget.repository.settings;
    controllers = [
      TextEditingController(text: '${settings.temperatureHigh}'),
      TextEditingController(text: '${settings.temperatureClear}'),
      TextEditingController(text: '${settings.gasHigh}'),
      TextEditingController(text: '${settings.gasClear}'),
    ];
  }

  @override
  void dispose() {
    for (final controller in controllers) { controller.dispose(); }
    super.dispose();
  }

  Future<void> save() async {
    final settings = LabSettings(
      temperatureHigh: double.tryParse(controllers[0].text) ?? -1,
      temperatureClear: double.tryParse(controllers[1].text) ?? -1,
      gasHigh: int.tryParse(controllers[2].text) ?? -1,
      gasClear: int.tryParse(controllers[3].text) ?? -1,
    );
    if (!settings.valid) {
      setState(() => error = 'Temperature ON: 30–60; clear: 20 to ON minus 1. Gas ON: 100–4000; clear: 0 to ON minus 1.');
      return;
    }
    setState(() { saving = true; error = ''; });
    try {
      await widget.repository.saveSettings(settings);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() { saving = false; error = 'Unable to confirm settings. Check the connection.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Temperature ON (°C)', 'Temperature clear (°C)', 'Gas ON (raw)', 'Gas clear (raw)'];
    return AlertDialog(
      title: const Text('Edit Thresholds'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (var index = 0; index < controllers.length; index++)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
            controller: controllers[index], enabled: !saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: labels[index], border: const OutlineInputBorder()),
          )),
        if (error.isNotEmpty) Text(error, style: const TextStyle(color: Colors.red)),
      ])),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: saving ? null : save, child: Text(saving ? 'Saving...' : 'Save')),
      ],
    );
  }
}
