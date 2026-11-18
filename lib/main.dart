import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'app.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? setupError;
  if (AppConfig.configured) {
    try {
      await Firebase.initializeApp(options: AppConfig.firebaseOptions);
      if (!kIsWeb) {
        FirebaseDatabase.instance.setPersistenceEnabled(false);
      }
    } catch (_) {
      setupError = 'Firebase could not start. Check AppConfig and your internet connection.';
    }
  }
  runApp(LabGuardApp(setupError: setupError));
}
