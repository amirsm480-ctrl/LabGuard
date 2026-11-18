import 'package:flutter/material.dart';
import '../services/lab_repository.dart';
import '../widgets/common_widgets.dart';
import '../utils/formatters.dart';

class AlertsPage extends StatefulWidget {
  final LabRepository repository;
  const AlertsPage({super.key, required this.repository});
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    final alerts = widget.repository.alerts.where((alert) {
      if (filter == 'Cleared') return alert.state == 'clear';
      if (filter == 'Warnings') return alert.state == 'active' && alert.reason != 'manual_test';
      return true;
    }).toList();
    return PageContent(children: [
      StatusCard(repository: widget.repository),
      Row(children: [
        const Expanded(child: Text('Show events:')),
        DropdownButton<String>(value: filter,
          items: ['All', 'Warnings', 'Cleared'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (value) { if (value != null) setState(() => filter = value); }),
      ]),
      Text('${alerts.length} recorded events'),
      const SizedBox(height: 8),
      if (alerts.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No matching events recorded.'))),
      for (final alert in alerts)
        Card(child: ListTile(
          leading: Icon(alert.state == 'clear' ? Icons.check_circle : Icons.notifications,
            color: alert.state == 'clear' ? Colors.green : alert.reason == 'manual_test' ? Colors.blue : Colors.red),
          title: Text(alert.title),
          subtitle: Text('${alert.occurredAt > 0 ? 'Occurred: ${displayTime(alert.occurredAt)}' : 'Occurrence time unavailable'}\n'
            'Recorded: ${displayTime(alert.timestamp)}'),
          isThreeLine: true,
        )),
    ]);
  }
}
