#!/bin/bash
# Changes the default for Global controls from off to on.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

TARGET="lib/shared/interface_config.dart"

if [ ! -f "$TARGET" ]; then
  echo "Error: $TARGET not found. Run add_global_controls_mode.sh first."
  exit 1
fi

python3 << 'PYEOF'
path = "lib/shared/interface_config.dart"
with open(path) as f:
    content = f.read()

old = "  bool useGlobalControls = false;"
new = "  bool useGlobalControls = true;"

count = content.count(old)
if count != 1:
    raise SystemExit(f"Error: expected exactly 1 match, found {count} in {path}.")

content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)

print(f"Updated {path}: Global controls now defaults to on")
PYEOF

echo ""
echo "Done. Run: flutter run"
