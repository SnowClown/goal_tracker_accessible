import 'package:flutter/material.dart';
import 'screens/goals_list_screen.dart';

/// Version A: the accessible interface, loaded when system
/// accessibility (TalkBack/VoiceOver) is detected as enabled.
class VersionAApp extends StatelessWidget {
  const VersionAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goal Tracker Accessible — Version A',
      home: const GoalsListScreen(),
    );
  }
}
