#!/bin/bash
# Removes the floating Add button entirely, and always shows the top
# panel with "New" as its first item — at every level (Goals, Tasks,
# Steps), in both Global controls mode (full 3x4 grid) and
# Dynamically displayed controls mode (panel shows just "New").
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
def patch_file(path):
    with open(path) as f:
        content = f.read()

    # 1. Remove the FAB entirely.
    old_fab_block = """      floatingActionButton: globalMode ? null : Semantics(
        button: true,
        label: 'Add"""
    if old_fab_block not in content:
        raise SystemExit(f"Error: FAB block anchor not found in {path}. Paste a fresh `cat` of this file.")

    # Find the full FAB property (from "floatingActionButton:" up to
    # the matching close before "body:") and remove it entirely.
    start = content.find("      floatingActionButton: globalMode ? null : Semantics(")
    body_marker = "      body: Column("
    end = content.find(body_marker, start)
    if start == -1 or end == -1:
        raise SystemExit(f"Error: could not locate FAB block bounds in {path}.")
    content = content[:start] + content[end:]

    # 2. Always show the panel (drop the `if (globalMode)` guard on it).
    old_panel_call = "          if (globalMode) _buildGlobalActionBar(),"
    new_panel_call = "          _buildGlobalActionBar(),"
    count = content.count(old_panel_call)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 panel-call match in {path}, found {count}.")
    content = content.replace(old_panel_call, new_panel_call, 1)

    # 3. Make the grid's action list conditional: New tile always
    #    first, followed by the rest of allItemActions only in
    #    Global controls mode.
    old_map_open = "          ...allItemActions.map((action) {"
    new_map_open = "          if (globalMode) ...allItemActions.map((action) {"
    count = content.count(old_map_open)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 map-open match in {path}, found {count}.")
    content = content.replace(old_map_open, new_map_open, 1)

    # (No change needed to the grid's closing — `if (globalMode)
    # ...spread` on the opening line above is valid Dart on its own;
    # when false, nothing is added to the list.)

    with open(path, "w") as f:
        f.write(content)

    print(f"Updated {path}: FAB removed, panel always visible with New first")


patch_file("lib/version_a/screens/goals_list_screen.dart")
patch_file("lib/version_a/screens/tasks_list_screen.dart")
patch_file("lib/version_a/screens/steps_list_screen.dart")
PYEOF

echo ""
echo "Done. Run: flutter run"
