#!/bin/bash
# Changes the global action bar layout from a width-based Wrap (which
# fit roughly 3 per row) to a fixed 4-per-row grid, giving 3 rows of 4
# (11 actions: 2 full rows of 4, 1 row of 3) instead of ~4 rows of 3.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
old_block = """    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allItemActions.map((action) {
          return Semantics(
            button: true,
            label: action.label,
            excludeSemantics: true,
            onTap: () => _handleGlobalAction(action),
            child: InkWell(
              onTap: () => _handleGlobalAction(action),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 84,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, color: Colors.white, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      action.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );"""

new_block = """    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.1,
        children: allItemActions.map((action) {
          return Semantics(
            button: true,
            label: action.label,
            excludeSemantics: true,
            onTap: () => _handleGlobalAction(action),
            child: InkWell(
              onTap: () => _handleGlobalAction(action),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: Colors.white, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      action.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );"""

files = [
    "lib/version_a/screens/goals_list_screen.dart",
    "lib/version_a/screens/tasks_list_screen.dart",
    "lib/version_a/screens/steps_list_screen.dart",
]

for path in files:
    with open(path) as f:
        content = f.read()

    count = content.count(old_block)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 match in {path}, found {count}.")

    content = content.replace(old_block, new_block)

    with open(path, "w") as f:
        f.write(content)

    print(f"Updated {path}: action bar now 4-per-row grid")
PYEOF

echo ""
echo "Done. Run: flutter run"
