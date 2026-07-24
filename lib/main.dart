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
