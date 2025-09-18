import 'package:flutter/material.dart';
import 'package:fyp/pages/Home.dart';

import 'package:fyp/pages/environmental_monitoring.dart';
import 'package:fyp/pages/historical_page.dart';
import 'package:fyp/pages/infrastructure_monitoring.dart';
import 'package:fyp/pages/login.dart';
import 'package:fyp/pages/network_monitoring.dart';

import 'package:fyp/services/auth_service.dart';
import 'package:fyp/theme/theme_provider.dart';
import 'package:fyp/widgets/custom_drawer.dart';
import 'package:fyp/widgets/app_bar_widget.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zskthrdrsryhheitwpaz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpza3RocmRyc3J5aGhlaXR3cGF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1MTU0MDIsImV4cCI6MjA2NzA5MTQwMn0.ixvnf6inPwYVF_y9Qs9e8yG0N-9NGnG8o9EFMlUO4yo',
  );

  runApp(
    ChangeNotifierProvider(create: (_) => ThemeProvider(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Real-Time Dashboard',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: AuthCheckPage(),
    );
  }
}

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({Key? key}) : super(key: key);

  @override
  _AuthCheckPageState createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return MainDashboard();
        } else {
          return const LoginRegisterPage();
        }
      },
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  MainDashboardState createState() => MainDashboardState();
}

class MainDashboardState extends State<MainDashboard> {
  int selectedIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    NetworkMonitoringPage(),
    InfrastructureMonitoringPage(),
    EnvironmentalMonitoringPage(onTemperatureAlert: (double) {}),
    HistoricalPage(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      body: _pages[selectedIndex],
    );
  }
}
