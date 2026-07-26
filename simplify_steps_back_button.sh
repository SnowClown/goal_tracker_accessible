#!/bin/bash
# Simplifies the Steps screen back navigation to a single button:
# "Back to Tasks" only. Removes the "Back to Goals" action added
# previously.
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
        leading: Semantics(
          button: true,
          label: 'Back to Tasks',
          excludeSemantics: true,
          onTap: () => Navigator.of(context).pop(),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Back to Goals',
            excludeSemantics: true,
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: IconButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              icon: const Icon(Icons.home, color: Colors.white),
            ),
          ),
        ],
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
      ),"""

if old_appbar not in content:
    raise SystemExit("Error: expected AppBar block (with Back to Goals) not found in steps_list_screen.dart")

content = content.replace(old_appbar, new_appbar)

with open(path, "w") as f:
    f.write(content)

print(f"Updated {path} - removed 'Back to Goals', kept only 'Back to Tasks'")
PYEOF

echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
