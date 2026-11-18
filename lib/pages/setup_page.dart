import 'package:flutter/material.dart';

class SetupPage extends StatelessWidget {
  final String? message;
  const SetupPage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Safety Monitor')),
      body: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message ?? 'Fill in lib/config/app_config.dart using the Firebase setup guide, then restart the app.',
          textAlign: TextAlign.center),
      )),
    );
  }
}
