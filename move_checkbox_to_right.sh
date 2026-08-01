#!/bin/bash
# Moves each item's selection checkbox from the left of its row to
# the right side, after the row's main tappable content (and before
# the More button slot, which is hidden in Global controls mode anyway).
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
def move_checkbox(path, item_var):
    with open(path) as f:
        content = f.read()

    old_checkbox = f"""                            if (globalMode)
                              Semantics(
                                label: 'Select ${{{item_var}.title}}',
                                checked: isSelected,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.greenAccent,
                                  onChanged: (value) {{
                                    setState(() {{
                                      if (value == true) {{
                                        _selectedIds.add({item_var}.id);
                                      }} else {{
                                        _selectedIds.remove({item_var}.id);
                                      }}
                                    }});
                                  }},
                                ),
                              ),
                            Expanded("""

    count = content.count(old_checkbox)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 checkbox-block match in {path}, found {count}. Paste a fresh `cat` of this file.")

    # Step 1: remove the checkbox from before Expanded.
    content = content.replace(old_checkbox, "                            Expanded(", 1)

    # Step 2: re-insert the same checkbox (still guarded by
    # `if (globalMode)`) right before the "if (!globalMode)" marker
    # that precedes the More button slot — this sits immediately
    # after Expanded's closing in all three screens.
    anchor = "                            if (!globalMode)\n"
    anchor_count = content.count(anchor)
    if anchor_count != 1:
        raise SystemExit(f"Error: expected exactly 1 '(!globalMode)' anchor in {path}, found {anchor_count}.")

    new_checkbox = f"""                            if (globalMode)
                              Semantics(
                                label: 'Select ${{{item_var}.title}}',
                                checked: isSelected,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.greenAccent,
                                  onChanged: (value) {{
                                    setState(() {{
                                      if (value == true) {{
                                        _selectedIds.add({item_var}.id);
                                      }} else {{
                                        _selectedIds.remove({item_var}.id);
                                      }}
                                    }});
                                  }},
                                ),
                              ),
{anchor}"""

    content = content.replace(anchor, new_checkbox, 1)

    with open(path, "w") as f:
        f.write(content)

    print(f"Updated {path}: checkbox moved to the right of its row")


move_checkbox("lib/version_a/screens/goals_list_screen.dart", "goal")
move_checkbox("lib/version_a/screens/tasks_list_screen.dart", "task")
move_checkbox("lib/version_a/screens/steps_list_screen.dart", "step")
PYEOF

echo ""
echo "Done. Run: flutter run"
