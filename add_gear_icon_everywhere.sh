#!/bin/bash
# Adds the Interface Configuration gear icon to the Tasks and Steps
# screens' AppBars too (it currently only appears on the Goals
# screen), so it's accessible from every level.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
def add_gear(path, import_anchor):
    with open(path) as f:
        content = f.read()

    # 1. Add the import if not already present.
    import_line = "import 'interface_configuration_screen.dart';\n"
    if import_line not in content:
        if import_anchor not in content:
            raise SystemExit(f"Error: import anchor not found in {path}")
        content = content.replace(import_anchor, import_anchor + import_line, 1)

    # 2. Add an `actions:` list with the gear icon to the AppBar.
    #    Both Tasks and Steps AppBars currently end their `leading:`
    #    Semantics/IconButton block with "        ),\n      ),\n" right
    #    before the closing of the AppBar itself.
    old_appbar_close = """          ),
        ),
      ),"""
    new_appbar_close = """          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Interface Configuration',
            excludeSemantics: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InterfaceConfigurationScreen()),
            ).then((_) => setState(() {})),
            child: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InterfaceConfigurationScreen()),
              ).then((_) => setState(() {})),
              icon: const Icon(Icons.settings, color: Colors.white70),
            ),
          ),
        ],
      ),"""

    count = content.count(old_appbar_close)
    if count != 1:
        raise SystemExit(f"Error: expected exactly 1 AppBar-close match in {path}, found {count}. Paste a fresh `cat` of this file.")

    content = content.replace(old_appbar_close, new_appbar_close, 1)

    with open(path, "w") as f:
        f.write(content)

    print(f"Updated {path}: gear icon added to AppBar")


add_gear("lib/version_a/screens/tasks_list_screen.dart", "import 'steps_list_screen.dart';\n")
add_gear("lib/version_a/screens/steps_list_screen.dart", "import '../widgets/action_types.dart';\n")
PYEOF

echo ""
echo "Done. Run: flutter run"
