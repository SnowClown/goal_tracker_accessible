#!/bin/bash
# Fully removes CocoaPods integration per Flutter's own instructions,
# since all remaining plugins are Swift Packages and none need
# CocoaPods anymore. This goes further than the previous cleanup —
# it also strips the xcconfig references that were still pointing at
# now-nonexistent Pods build files, which is what caused the
# "sandbox not in sync" error to persist.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

if [ ! -d "ios" ]; then
  echo "Error: ios/ directory not found."
  exit 1
fi

cd ios

if command -v pod >/dev/null 2>&1; then
  echo "Running pod deintegrate..."
  pod deintegrate || echo "pod deintegrate reported an issue (continuing anyway, since Podfile may already be gone)"
else
  echo "CocoaPods (pod command) not found — skipping pod deintegrate, proceeding with manual cleanup."
fi

rm -f Podfile
rm -f Podfile.lock
rm -rf Pods
rm -rf .symlinks

cd ..

echo ""
echo "Removing CocoaPods xcconfig includes from Debug.xcconfig and Release.xcconfig..."

python3 << 'PYEOF'
import re

for fname in ["ios/Flutter/Debug.xcconfig", "ios/Flutter/Release.xcconfig"]:
    try:
        with open(fname) as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"  {fname} not found, skipping.")
        continue

    new_lines = [
        line for line in lines
        if "Pods-Runner" not in line
    ]

    removed = len(lines) - len(new_lines)
    with open(fname, "w") as f:
        f.writelines(new_lines)

    print(f"  {fname}: removed {removed} CocoaPods include line(s)")
PYEOF

echo ""
echo "Running flutter clean and flutter pub get to finish..."
flutter clean
flutter pub get

echo ""
echo "Done. Run: flutter run"
