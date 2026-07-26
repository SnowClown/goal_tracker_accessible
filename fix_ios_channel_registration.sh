#!/bin/bash
# Fixes MissingPluginException on iOS. Root cause: this Flutter/Xcode
# version has migrated toward Scene-based lifecycle, where
# window/rootViewController are NOT reliably set inside
# didFinishLaunchingWithOptions (Flutter's own deprecation warning
# confirms this). Reading controller.binaryMessenger from the window
# was therefore unreliable.
#
# Fix: use FlutterAppDelegate's own registrar(forPlugin:) API instead,
# which provides a binaryMessenger directly from the engine — no
# dependency on window/rootViewController at all.
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
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Uses the plugin registrar API (backed directly by the Flutter
    // engine) instead of window?.rootViewController, which is not
    // reliably available at this point under Scene-based lifecycle.
    if let registrar = self.registrar(forPlugin: "AccessibilityChannel") {
      let channel = FlutterMethodChannel(
        name: "goal_tracker_accessible/accessibility",
        binaryMessenger: registrar.messenger()
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

echo "Updated $APP_DELEGATE (channel now registered via registrar API, not window)"
echo ""
echo "Done. Run: flutter run"
