import 'package:flutter/material.dart';
import 'screens/emergency_chat_screen.dart';

void main() {
  runApp(const RapidAidApp());
}

class RapidAidApp extends StatelessWidget {
  const RapidAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RapidAid AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF991B1B)),
      ),
      home: const EmergencyChatScreen(),
    );
  }
}