#!/bin/bash
# Removes a duplicate "More" button from each of the Goals, Tasks, and
# Steps screens. This happens if add_more_buttons_to_rows.sh got run
# twice, since the button block it inserts ends with the same closing
# pattern it searches for — running it again matches and duplicates it.
#
# This script detects exactly 2 copies of the More-button Semantics
# block per file and removes one, leaving exactly 1.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
def dedupe_more_button(path, item_var, edit_fn, delete_fn):
    with open(path) as f:
        content = f.read()

    block = f"""                      Semantics(
                        button: true,
                        label: 'More actions for ${{{item_var}.title}}',
                        excludeSemantics: true,
                        onTap: () => showMoreActionsSheet(
                          context,
                          itemTitle: {item_var}.title,
                          onEdit: () => {edit_fn}({item_var}),
                          onDelete: () => {delete_fn}({item_var}),
                        ),
                        child: IconButton(
                          onPressed: () => showMoreActionsSheet(
                            context,
                            itemTitle: {item_var}.title,
                            onEdit: () => {edit_fn}({item_var}),
                            onDelete: () => {delete_fn}({item_var}),
                          ),
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                        ),
                      ),
"""

    count = content.count(block)
    if count == 0:
        raise SystemExit(f"Error: More-button block not found at all in {path} — paste a fresh `cat` of this file.")
    if count == 1:
        print(f"{path}: only 1 copy found, nothing to remove.")
        return
    if count > 2:
        raise SystemExit(f"Error: found {count} copies in {path} — more than expected, needs manual review. Paste a fresh `cat`.")

    # Remove exactly one occurrence (the first), leaving exactly one behind.
    idx = content.find(block)
    content = content[:idx] + content[idx + len(block):]

    with open(path, "w") as f:
        f.write(content)

    print(f"{path}: removed 1 duplicate More button (2 -> 1)")


dedupe_more_button("lib/version_a/screens/goals_list_screen.dart", "goal", "_editGoal", "_deleteGoal")
dedupe_more_button("lib/version_a/screens/tasks_list_screen.dart", "task", "_editTask", "_deleteTask")
dedupe_more_button("lib/version_a/screens/steps_list_screen.dart", "step", "_editStep", "_deleteStep")
PYEOF

echo ""
echo "Done. Run: flutter run"
