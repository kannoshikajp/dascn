import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const JoppeEcomApp());
}

class JoppeEcomApp extends StatelessWidget {
  const JoppeEcomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joppe E-Commerce',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
