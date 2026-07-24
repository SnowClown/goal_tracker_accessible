import 'package:flutter/material.dart';

/// Version A: the accessible interface, loaded when system
/// accessibility (TalkBack/VoiceOver) is detected as enabled.
class VersionAApp extends StatelessWidget {
  const VersionAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goal Tracker Accessible — Version A',
      home: Scaffold(
        appBar: AppBar(title: const Text('Version A — Accessible')),
        body: const Center(
          child: Text(
            'Version A placeholder\n(Accessibility mode detected)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
