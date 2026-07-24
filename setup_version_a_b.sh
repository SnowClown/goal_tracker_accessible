#!/bin/bash
# Sets up the initial Version A / Version B accessibility-routing skeleton
# for goal_tracker_accessible. Run this from inside the project root
# (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

mkdir -p lib/version_a lib/version_b lib/shared

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
    final bool accessibilityEnabled = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.accessibleNavigation;

    return accessibilityEnabled ? const VersionAApp() : const VersionBApp();
  }
}
EOF

cat > lib/version_a/app_a.dart << 'EOF'
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
EOF

cat > lib/version_b/app_b.dart << 'EOF'
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
EOF

echo "Done. Created:"
echo "  lib/main.dart"
echo "  lib/version_a/app_a.dart"
echo "  lib/version_b/app_b.dart"
echo "  lib/shared/ (empty, for shared data/logic)"
echo ""
echo "Next steps:"
echo "  flutter run -d R5CY34G515E"
