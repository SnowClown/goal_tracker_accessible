#!/bin/bash
# Updates lib/version_a/app_a.dart to use GoalsListScreen as its home
# instead of the placeholder text.
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

if [ ! -f "lib/version_a/screens/goals_list_screen.dart" ]; then
  echo "Error: lib/version_a/screens/goals_list_screen.dart not found."
  echo "Run add_goals_list_screen.sh first."
  exit 1
fi

cat > lib/version_a/app_a.dart << 'EOF'
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
EOF

echo "Updated lib/version_a/app_a.dart to use GoalsListScreen as its home."
