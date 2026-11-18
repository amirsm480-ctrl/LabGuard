import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/lab_repository.dart';
import '../widgets/common_widgets.dart';
import '../utils/formatters.dart';

class DashboardPage extends StatelessWidget {
  final LabRepository repository;
  final String email;
  const DashboardPage({super.key, required this.repository, required this.email});

  @override
  Widget build(BuildContext context) {
    final reading = repository.reading;
    final alarmState = reading == null ? 'N/A' : reading.alarm ? 'ON' : 'OFF';
    return PageContent(children: [
      const Text(AppConfig.labName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('User: $email'),
      Text('ESP32: ${repository.online ? 'Online' : 'Offline'}'),
      Text('Last update: ${displayTime(reading?.updatedAt ?? 0)}'),
      const SizedBox(height: 12),
      StatusCard(repository: repository),
      sectionTitle(repository.online ? 'Sensor readings' : 'Last received readings'),
      SensorReadings(reading: reading),
      sectionTitle('Actuator status'),
      dataCard('Buzzer', alarmState, Icons.volume_up),
      dataCard('Warning light', alarmState, Icons.lightbulb),
      const Padding(padding: EdgeInsets.all(8),
        child: Text('Both devices use relay channel 1 and switch together.')),
    ]);
  }
}
