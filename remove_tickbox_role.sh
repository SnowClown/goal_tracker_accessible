#!/bin/bash
# Removes the 'checked' property from the Steps screen's Semantics
# widget. That property was telling TalkBack this is a checkbox-style
# control, causing it to announce "tick box" on top of our own
# "Completed"/"Uncompleted" label. Removing it leaves just our label.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

TARGET="lib/version_a/screens/steps_list_screen.dart"

if [ ! -f "$TARGET" ]; then
  echo "Error: $TARGET not found."
  exit 1
fi

# Remove the "checked: step.completed," line specifically.
sed -i '/^\s*checked: step\.completed,\s*$/d' "$TARGET"

if grep -q "checked: step.completed" "$TARGET"; then
  echo "Warning: 'checked: step.completed' still present — check $TARGET manually."
  exit 1
else
  echo "Removed 'checked: step.completed' from $TARGET"
fi

echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
