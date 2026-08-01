#!/bin/bash
# Moves the "New" (Add) button into the global action panel as the
# first tile, instead of being a separate floating action button.
# The FAB is hidden when Global controls is on (since New is now in
# the panel) and still shows normally in Dynamically displayed mode.
# 11 existing actions + New = 12, filling the 4-per-row grid exactly
# (3 full rows, no partial row).
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
def patch_file(path, add_fn_name, item_noun):
    with open(path) as f:
        content = f.read()

    # 1. Insert a "New" tile as the first grid child, before the
    #    allItemActions.map(...) children.
    old_grid_open = """        childAspectRatio: 1.1,
        children: allItemActions.map((action) {"""
    new_grid_open = f"""        childAspectRatio: 1.1,
        children: [
          Semantics(
            button: true,
            label: 'New {item_noun}',
            excludeSemantics: true,
            onTap: {add_fn_name},
            child: InkWell(
              onTap: {add_fn_name},
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.greenAccent, size: 22),
                    SizedBox(height: 4),
                    Text(
                      'New',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...allItemActions.map((action) {{"""

    count = content.count(old_grid_open)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 match for grid-open anchor in {path}, found {count}.")
    content = content.replace(old_grid_open, new_grid_open)

    # 2. Close the extra list literal we opened above (the grid's
    #    children now needs the .map(...).toList() output spread into
    #    a surrounding [...] list — close that list after .toList()).
    old_grid_close = """        }).toList(),
      ),
    );
  }"""
    new_grid_close = """        }).toList(),
        ],
      ),
    );
  }"""
    count = content.count(old_grid_close)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 match for grid-close anchor in {path}, found {count}.")
    content = content.replace(old_grid_close, new_grid_close)

    # 3. Hide the FAB when Global controls is on.
    old_fab = """      floatingActionButton: Semantics(
        button: true,"""
    new_fab = """      floatingActionButton: globalMode ? null : Semantics(
        button: true,"""
    count = content.count(old_fab)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 match for FAB anchor in {path}, found {count}.")
    content = content.replace(old_fab, new_fab)

    with open(path, "w") as f:
        f.write(content)

    print(f"Updated {path}")


patch_file("lib/version_a/screens/goals_list_screen.dart", "_addGoal", "goal")
patch_file("lib/version_a/screens/tasks_list_screen.dart", "_addTask", "task")
patch_file("lib/version_a/screens/steps_list_screen.dart", "_addStep", "step")
PYEOF

echo ""
echo "Done. Run: flutter run"
