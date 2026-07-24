import 'package:flutter/material.dart';

/// Version B: the standard interface, loaded when no system
/// accessibility service is detected.
class VersionBApp extends StatelessWidget {
  const VersionBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goal Tracker Accessible — Version B',
      home: Scaffold(
        appBar: AppBar(title: const Text('Version B — Standard')),
        body: const Center(
          child: Text(
            'Version B placeholder\n(Standard mode)',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
