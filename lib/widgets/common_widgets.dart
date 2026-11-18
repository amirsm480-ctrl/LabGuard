import 'package:flutter/material.dart';
import '../models/lab_models.dart';
import '../services/lab_repository.dart';
import '../utils/formatters.dart';

Widget sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );
}

Widget dataCard(String title, String value, IconData icon, {String? detail}) {
  return Card(
    child: ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: detail == null ? null : Text(detail),
      trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ),
  );
}

class PageContent extends StatelessWidget {
  final List<Widget> children;
  const PageContent({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}

class SensorReadings extends StatelessWidget {
  final LabReading? reading;
  const SensorReadings({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final value = reading;
    return Column(children: [
      dataCard('Temperature', temperatureText(value), Icons.thermostat,
        detail: value != null && !value.dhtOk ? 'Check DHT11 connection' : 'DHT11'),
      dataCard('Humidity', humidityText(value), Icons.water_drop, detail: 'DHT11'),
      dataCard('Gas level', value?.gas?.toString() ?? 'N/A', Icons.air,
        detail: value == null ? 'MQ-5 raw reading'
          : value.gasReady ? 'Raw reading: 0–4095' : 'Warming up: ${value.gasWarmupSeconds}s'),
      dataCard('Flame', value == null ? 'N/A' : value.flame ? 'Detected' : 'Clear',
        Icons.local_fire_department, detail: 'IR flame sensor'),
    ]);
  }
}

class StatusCard extends StatelessWidget {
  final LabRepository repository;
  const StatusCard({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    final reading = repository.reading;
    String title;
    String detail;
    MaterialColor color;
    if (reading == null) {
      title = 'Waiting for ESP32';
      detail = 'No sensor data received yet.';
      color = Colors.grey;
    } else if (!repository.online) {
      title = 'Device offline';
      detail = 'Showing last received data. Remote control is unavailable.';
      color = Colors.grey;
    } else if (reading.hazard) {
      title = 'Warning';
      detail = reasonLabel(reading.reason);
      color = Colors.red;
    } else if (!reading.dhtOk) {
      title = 'Sensor error';
      detail = 'Check the DHT11 connection.';
      color = Colors.orange;
    } else if (!reading.gasReady) {
      title = 'Gas sensor warming up';
      detail = 'Please wait ${reading.gasWarmupSeconds} seconds. Flame monitoring is active.';
      color = Colors.orange;
    } else if (reading.alarm) {
      title = 'Alarm test running';
      detail = 'The buzzer and warning light are ON.';
      color = Colors.blue;
    } else {
      title = 'Normal';
      detail = 'No hazard detected by the connected sensors.';
      color = Colors.green;
    }
    return Card(
      color: color.shade50,
      child: ListTile(
        leading: Icon(Icons.info, color: color.shade700),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.shade800)),
        subtitle: Text(detail),
      ),
    );
  }
}
