import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'config/app_config.dart';
import 'services/lab_repository.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/setup_page.dart';

class LabGuardApp extends StatelessWidget {
  final String? setupError;
  const LabGuardApp({super.key, this.setupError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab Safety Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade100),
      home: !AppConfig.configured || setupError != null
        ? SetupPage(message: setupError)
        : StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return const SetupPage(message: 'Unable to check your login. Restart the app and try again.');
            }
            final user = snapshot.data;
            return user == null ? const LoginPage() : SignedInApp(key: ValueKey(user.uid), user: user);
          },
        ),
    );
  }
}

class SignedInApp extends StatefulWidget {
  final User user;
  const SignedInApp({super.key, required this.user});
  @override
  State<SignedInApp> createState() => _SignedInAppState();
}

class _SignedInAppState extends State<SignedInApp> {
  late final FirebaseLabRepository repository;

  @override
  void initState() {
    super.initState();
    repository = FirebaseLabRepository(FirebaseDatabase.instance, widget.user.uid);
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(repository: repository, email: widget.user.email ?? 'Lab operator');
  }
}
