#!/bin/bash
# Fixes "The getter 'globalMode' isn't defined" build errors.
# _buildGlobalActionBar() is a separate method from build() and
# doesn't have access to build()'s local `globalMode` variable —
# fix: reference interfaceConfig.useGlobalControls directly there.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
old_line = "          if (globalMode) ...allItemActions.map((action) {"
new_line = "          if (interfaceConfig.useGlobalControls) ...allItemActions.map((action) {"

files = [
    "lib/version_a/screens/goals_list_screen.dart",
    "lib/version_a/screens/tasks_list_screen.dart",
    "lib/version_a/screens/steps_list_screen.dart",
]

for path in files:
    with open(path) as f:
        content = f.read()

    count = content.count(old_line)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 match in {path}, found {count}.")

    content = content.replace(old_line, new_line, 1)

    with open(path, "w") as f:
        f.write(content)

    print(f"Fixed {path}")
PYEOF

echo ""
echo "Done. Run: flutter run"
