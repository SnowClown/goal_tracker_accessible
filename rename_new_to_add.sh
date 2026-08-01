#!/bin/bash
# Renames the panel's "New" tile to "Add" (and its Semantics label
# from "New Goal/Task/Step" to "Add Goal/Task/Step") across all three
# screens, for consistency.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
def patch_file(path, item_noun):
    with open(path) as f:
        content = f.read()

    old_label = f"label: 'New {item_noun}',"
    new_label = f"label: 'Add {item_noun}',"
    count = content.count(old_label)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 label match in {path}, found {count}.")
    content = content.replace(old_label, new_label, 1)

    old_text = "                    Text(\n                      'New',"
    new_text = "                    Text(\n                      'Add',"
    count = content.count(old_text)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 Text('New') match in {path}, found {count}.")
    content = content.replace(old_text, new_text, 1)

    with open(path, "w") as f:
        f.write(content)

    print(f"Updated {path}: tile now reads 'Add {item_noun}'")


patch_file("lib/version_a/screens/goals_list_screen.dart", "goal")
patch_file("lib/version_a/screens/tasks_list_screen.dart", "task")
patch_file("lib/version_a/screens/steps_list_screen.dart", "step")
PYEOF

echo ""
echo "Done. Run: flutter run"
