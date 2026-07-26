#!/bin/bash
# Fixes a crash on launch: "Swift runtime failure: force unwrapped a
# nil value" in AppDelegate.swift. The bug was reading
# window?.rootViewController BEFORE calling super.application(...),
# which is what actually sets up the window/rootViewController.
# Fix: call super first, then set up the method channel.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

APP_DELEGATE="ios/Runner/AppDelegate.swift"

if [ ! -f "$APP_DELEGATE" ]; then
  echo "Error: $APP_DELEGATE not found."
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
    // Call super FIRST — this is what actually sets up self.window
    // and its rootViewController. Reading them before this point
    // means window is still nil, which previously crashed the app
    // with a force-unwrap failure.
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
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
    }

    return result
  }
}
EOF

echo "Updated $APP_DELEGATE (fixed launch crash, super.application() now called first)"
echo ""
echo "Done. Run: flutter run"
