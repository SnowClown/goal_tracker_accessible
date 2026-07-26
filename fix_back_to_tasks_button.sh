#!/bin/bash
# Adds the "Back to Tasks" button to the Steps screen's AppBar.
# This targets the file's ACTUAL current content (confirmed via cat).
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

python3 << 'PYEOF'
path = "lib/version_a/screens/steps_list_screen.dart"
with open(path) as f:
    content = f.read()

old_appbar = """      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.task.title, style: const TextStyle(color: Colors.white)),
      ),"""

new_appbar = """      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.task.title, style: const TextStyle(color: Colors.white)),
        leading: Semantics(
          button: true,
          label: 'Back to Tasks',
          excludeSemantics: true,
          onTap: () => Navigator.of(context).pop(),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.green, size: 30),
          ),
        ),
      ),"""

count = content.count(old_appbar)
if count == 0:
    raise SystemExit("Error: expected AppBar block not found — paste `cat` output again.")
if count > 1:
    raise SystemExit(f"Error: found {count} matches, expected exactly 1.")

content = content.replace(old_appbar, new_appbar)

with open(path, "w") as f:
    f.write(content)

print(f"Updated {path} with 'Back to Tasks' button (green arrow, size 30)")
PYEOF

echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
