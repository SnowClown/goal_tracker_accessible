#!/bin/bash
# Adds a native platform channel to reliably detect screen reader state:
# - Android: checks AccessibilityManager.isTouchExplorationEnabled() (true when TalkBack-style screen reader is on)
# - iOS: checks UIAccessibility.isVoiceOverRunning
# Then updates lib/main.dart to call this channel instead of Flutter's
# built-in accessibleNavigation flag, which proved unreliable.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

# --- Find the Android MainActivity.kt (path includes the package name) ---
MAIN_ACTIVITY=$(find android/app/src/main/kotlin -name "MainActivity.kt" 2>/dev/null | head -n 1)

if [ -z "$MAIN_ACTIVITY" ]; then
  echo "Error: could not find android/app/src/main/kotlin/**/MainActivity.kt"
  echo "This script expects a standard Flutter Kotlin project layout."
  exit 1
fi

echo "Found Android MainActivity at: $MAIN_ACTIVITY"

# Extract the package declaration line so we keep it intact
PACKAGE_LINE=$(grep "^package " "$MAIN_ACTIVITY")

cat > "$MAIN_ACTIVITY" << EOF
$PACKAGE_LINE

import android.content.Context
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "goal_tracker_accessible/accessibility"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isScreenReaderEnabled") {
                val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
                result.success(am.isEnabled && am.isTouchExplorationEnabled)
            } else {
                result.notImplemented()
            }
        }
    }
}
EOF

echo "Updated $MAIN_ACTIVITY"

# --- iOS: AppDelegate.swift ---
APP_DELEGATE="ios/Runner/AppDelegate.swift"

if [ ! -f "$APP_DELEGATE" ]; then
  echo "Error: $APP_DELEGATE not found. This script expects a standard Flutter iOS project layout."
  exit 1
fi

cat > "$APP_DELEGATE" << 'EOF'
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "goal_tracker_accessible/accessibility",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { (call, result) in
      if call.method == "isScreenReaderEnabled" {
        result(UIAccessibility.isVoiceOverRunning)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
EOF

echo "Updated $APP_DELEGATE"

# --- Dart side: lib/main.dart ---
cat > lib/main.dart << 'EOF'
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
EOF

echo "Updated lib/main.dart"
echo ""
echo "Done. Run: flutter clean && flutter pub get && flutter run -d R5CY34G515E"
