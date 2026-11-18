import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/lab_repository.dart';
import 'dashboard_page.dart';
import 'sensors_page.dart';
import 'control_page.dart';
import 'history_page.dart';
import 'alerts_page.dart';

class HomePage extends StatefulWidget {
  final LabRepository repository;
  final String email;
  const HomePage({super.key, required this.repository, required this.email});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPage = 0;
  final titles = ['Dashboard', 'Sensors', 'Control', 'History', 'Alerts'];

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to log out.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.repository,
      builder: (context, _) {
        final repository = widget.repository;
        final screenSize = MediaQuery.sizeOf(context);
        final wideScreen = screenSize.width >= 800 && screenSize.height >= 600;
        final content = Column(children: [
          if (repository.error != null)
            Container(width: double.infinity, padding: const EdgeInsets.all(12),
              color: Colors.red.shade50, child: Text(repository.error!)),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: IndexedStack(index: selectedPage, children: [
                  DashboardPage(repository: repository, email: widget.email),
                  SensorsPage(repository: repository),
                  ControlPage(repository: repository),
                  HistoryPage(repository: repository),
                  AlertsPage(repository: repository),
                ]),
              ),
            ),
          ),
        ]);
        return Scaffold(
          appBar: AppBar(
            title: Text(titles[selectedPage]),
            actions: [IconButton(onPressed: logout, tooltip: 'Logout', icon: const Icon(Icons.logout))],
          ),
          body: SafeArea(
            child: wideScreen ? Row(children: [
              NavigationRail(
                selectedIndex: selectedPage,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (index) => setState(() => selectedPage = index),
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.home), label: Text('Dashboard')),
                  NavigationRailDestination(icon: Icon(Icons.sensors), label: Text('Sensors')),
                  NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Control')),
                  NavigationRailDestination(icon: Icon(Icons.history), label: Text('History')),
                  NavigationRailDestination(icon: Icon(Icons.notifications), label: Text('Alerts')),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ]) : content,
          ),
          bottomNavigationBar: wideScreen ? null : BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: selectedPage,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            onTap: (index) => setState(() => selectedPage = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'Sensors'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Control'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
            ],
          ),
        );
      },
    );
  }
}
