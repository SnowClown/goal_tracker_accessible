#!/bin/bash
# Switches the back arrow icons from Colors.greenAccent (pale/washed
# out) to Colors.green (more saturated, brighter-reading against black).
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
files = [
    "lib/version_a/screens/tasks_list_screen.dart",
    "lib/version_a/screens/steps_list_screen.dart",
]

old = "icon: const Icon(Icons.arrow_back, color: Colors.greenAccent),"
new = "icon: const Icon(Icons.arrow_back, color: Colors.green, size: 30),"

for path in files:
    with open(path) as f:
        content = f.read()

    if old not in content:
        raise SystemExit(f"Error: expected back-arrow Icon line not found in {path}")

    content = content.replace(old, new)

    with open(path, "w") as f:
        f.write(content)

    print(f"Updated {path} — back arrow is now a brighter, larger green")
PYEOF

echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
