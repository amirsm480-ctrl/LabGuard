import 'package:flutter/material.dart';
import '../services/lab_repository.dart';
import '../widgets/common_widgets.dart';
import '../utils/formatters.dart';

class SensorsPage extends StatelessWidget {
  final LabRepository repository;
  const SensorsPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    final reading = repository.reading;
    return PageContent(children: [
      Text(repository.online ? 'Live sensor data' : 'Device offline. Values may be old.',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SensorReadings(reading: reading),
      sectionTitle('Gas reading'),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          LinearProgressIndicator(value: ((reading?.gas ?? 0) / 4095).clamp(0.0, 1.0), minHeight: 10),
          const SizedBox(height: 8),
          const Text('Range: 0–4095 raw. This is not a calibrated ppm reading.'),
          Text('Alarm threshold: ${reading?.settings.gasHigh ?? repository.settings.gasHigh} raw'),
        ],
      ))),
      sectionTitle('Device information'),
      Card(child: Column(children: [
        ListTile(title: const Text('Firebase connection'),
          subtitle: Text(repository.connected ? 'Connected' : 'Disconnected')),
        ListTile(title: const Text('Last update'), subtitle: Text(displayTime(reading?.updatedAt ?? 0))),
        ListTile(title: const Text('Wi-Fi signal'), subtitle: Text(reading == null ? 'N/A' : '${reading.rssi} dBm')),
        ListTile(title: const Text('Device uptime'), subtitle: Text(reading == null ? 'N/A' : '${reading.uptime ~/ 60} minutes')),
      ])),
    ]);
  }
}
