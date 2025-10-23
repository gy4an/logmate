import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:main/screens/login_screen.dart';
import 'package:main/screens/user_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? loggedInUser;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('loggedInUser');
    setState(() {
      loggedInUser = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash-like loading screen first
    if (loggedInUser == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      );
    } else {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: UserDashboardScreen(username: loggedInUser!),
      );
    }
  }
}
