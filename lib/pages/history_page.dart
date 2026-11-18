import 'package:flutter/material.dart';
import '../services/lab_repository.dart';
import '../widgets/common_widgets.dart';
import '../utils/formatters.dart';

class HistoryPage extends StatefulWidget {
  final LabRepository repository;
  const HistoryPage({super.key, required this.repository});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int hours = 1;
  int page = 0;
  final tableController = ScrollController();

  @override
  void dispose() {
    tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cutoff = widget.repository.now - hours * 3600000;
    final readings = widget.repository.history.reversed.where((reading) => reading.updatedAt >= cutoff).toList();
    final lastPage = readings.isEmpty ? 0 : (readings.length - 1) ~/ 10;
    final currentPage = page > lastPage ? lastPage : page;
    final visibleReadings = readings.skip(currentPage * 10).take(10).toList();
    return PageContent(children: [
      const Text('Recorded Sensor Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('New samples are saved about every 30 seconds while the ESP32 is connected.'),
      Row(children: [
        const Expanded(child: Text('Show readings from:')),
        DropdownButton<int>(
          value: hours,
          items: [1, 6, 24].map((value) => DropdownMenuItem(value: value, child: Text('Last $value hours'))).toList(),
          onChanged: (value) { if (value != null) setState(() { hours = value; page = 0; }); },
        ),
      ]),
      if (readings.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No recorded readings in this time range.')))
      else ...[
        Text('${readings.length} saved readings. Scroll the table sideways to see all columns.'),
        const SizedBox(height: 8),
        Card(child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Scrollbar(
            controller: tableController,
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: tableController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: DataTable(columnSpacing: 20, columns: const [
                DataColumn(label: Text('Date / Time')),
                DataColumn(label: Text('Temp °C')),
                DataColumn(label: Text('Humidity %')),
                DataColumn(label: Text('Gas raw')),
                DataColumn(label: Text('Flame')),
                DataColumn(label: Text('Alarm')),
              ], rows: visibleReadings.map((reading) => DataRow(cells: [
                DataCell(Text(displayTime(reading.updatedAt))),
                DataCell(Text(reading.dhtOk ? reading.temperature?.toStringAsFixed(1) ?? 'N/A' : 'N/A')),
                DataCell(Text(reading.dhtOk ? reading.humidity?.toStringAsFixed(0) ?? 'N/A' : 'N/A')),
                DataCell(Text(reading.gasReady ? reading.gas?.toString() ?? 'N/A' : 'Warm-up')),
                DataCell(Text(reading.flame ? 'Detected' : 'Clear')),
                DataCell(Text(reading.alarm ? 'ON' : 'OFF')),
              ])).toList()),
            ),
          ),
        )),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton(onPressed: currentPage > 0 ? () => setState(() => page = currentPage - 1) : null,
            child: const Text('Previous')),
          Text('${currentPage + 1} / ${lastPage + 1}'),
          TextButton(onPressed: currentPage < lastPage ? () => setState(() => page = currentPage + 1) : null,
            child: const Text('Next')),
        ]),
      ],
      const SizedBox(height: 12),
      const Text('Up to 24 hours of samples are stored. Missing or invalid readings are not treated as normal measurements.'),
    ]);
  }
}
