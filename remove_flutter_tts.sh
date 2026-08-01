#!/bin/bash
# Removes the unused flutter_tts dependency entirely. Nothing in the
# codebase calls it anymore (we switched to TalkBack/VoiceOver's own
# reading via Semantics labels), and it's the source of the recurring
# "does not support Swift Package Manager" warning on every iOS build.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

flutter pub remove flutter_tts

echo ""
echo "Removed flutter_tts from pubspec.yaml."
echo "Clearing the iOS Podfile.lock so the next build regenerates it"
echo "without the leftover flutter_tts pod reference (avoids a stale"
echo "CocoaPods lock causing confusing errors)."
rm -f ios/Podfile.lock

echo ""
echo "Done. Run: flutter clean && flutter pub get && flutter run"
