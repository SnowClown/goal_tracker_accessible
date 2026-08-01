#!/bin/bash
# Fixes "sandbox is not in sync with the Podfile.lock" after removing
# flutter_tts. Since no remaining plugins need CocoaPods, Flutter's
# tooling removed the Podfile itself — but Xcode's build sandbox still
# has stale CocoaPods-linked settings/cache from before. This clears
# all of that out so the next build regenerates cleanly (with or
# without CocoaPods, whichever this project now actually needs).
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

flutter clean

echo ""
echo "Removing stale CocoaPods artifacts under ios/ ..."
rm -rf ios/Pods
rm -f ios/Podfile.lock
rm -rf ios/.symlinks
rm -f ios/Flutter/Flutter.podspec

echo ""
echo "Running flutter pub get to regenerate whatever's actually needed..."
flutter pub get

echo ""
echo "Done. Run: flutter run"
