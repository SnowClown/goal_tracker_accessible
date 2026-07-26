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
