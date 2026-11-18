import '../models/lab_models.dart';

String displayTime(int timestamp) {
  if (timestamp <= 0) return 'Not available';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute:$second';
}

String temperatureText(LabReading? reading) {
  if (reading == null || !reading.dhtOk || reading.temperature == null) {
    return 'N/A';
  }
  return '${reading.temperature!.toStringAsFixed(1)} °C';
}

String humidityText(LabReading? reading) {
  if (reading == null || !reading.dhtOk || reading.humidity == null) {
    return 'N/A';
  }
  return '${reading.humidity!.toStringAsFixed(0)} %';
}
