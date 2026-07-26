import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'version_a/app_a.dart';
import 'version_b/app_b.dart';

const _accessibilityChannel = MethodChannel('goal_tracker_accessible/accessibility');

/// Queries the native platform (Android AccessibilityManager /
/// iOS UIAccessibility) directly, rather than relying on Flutter's
/// built-in accessibleNavigation flag, which proved unreliable on
/// this Samsung device with TalkBack running.
Future<bool> isScreenReaderEnabled() async {
  try {
    final bool? result = await _accessibilityChannel.invokeMethod<bool>('isScreenReaderEnabled');
    return result ?? false;
  } on PlatformException {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool accessibilityEnabled = await isScreenReaderEnabled();
  debugPrint('DEBUG: isScreenReaderEnabled (native) = $accessibilityEnabled');
  runApp(accessibilityEnabled ? const VersionAApp() : const VersionBApp());
}
