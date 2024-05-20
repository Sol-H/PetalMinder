import 'package:flutter/material.dart';
import 'auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetalMinder',
      theme: ThemeData(
        useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 18, 44, 19),
        background: const Color.fromARGB(255, 207, 255, 210), // light green
        surface: const Color.fromARGB(255, 249, 255, 232),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 207, 255, 210),
      ),
      ),
      home: const AuthGate(),
    );
  }
}
