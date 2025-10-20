import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const LogMateApp());
}

class LogMateApp extends StatelessWidget {
  const LogMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogMate',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
