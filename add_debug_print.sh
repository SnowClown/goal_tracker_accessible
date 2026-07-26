#!/bin/bash
# Adds a temporary debug print to lib/main.dart to confirm what value
# Flutter's accessibleNavigation flag actually reports at launch.
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

if [ ! -f "lib/main.dart" ]; then
  echo "Error: lib/main.dart not found."
  exit 1
fi

cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'version_a/app_a.dart';
import 'version_b/app_b.dart';

void main() {
  runApp(const RootApp());
}

/// Root widget — decides which interface version to load based on
/// whether system accessibility (TalkBack / VoiceOver) is active.
class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MediaQuery reflects the OS-level "screen reader enabled" flag
    // on both Android (TalkBack) and iOS (VoiceOver).
    final bool accessibilityEnabled =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.accessibleNavigation;

    // TEMPORARY DEBUG LINE — remove once detection is confirmed working.
    debugPrint('DEBUG: accessibleNavigation = $accessibilityEnabled');

    return accessibilityEnabled ? const VersionAApp() : const VersionBApp();
  }
}
EOF

echo "Updated lib/main.dart with a temporary debug print."
echo "Run: flutter run -d R5CY34G515E"
echo "and watch the terminal for: DEBUG: accessibleNavigation = true/false"
