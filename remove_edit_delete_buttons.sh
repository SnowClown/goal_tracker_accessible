#!/bin/bash
# Removes the Edit and Delete icon buttons from the Goals, Tasks, and
# Steps screens. Leaves the row's own tap action (navigate for
# Goals/Tasks, toggle completion for Steps) and the Add FAB untouched.
# The underlying _editX()/_deleteX() methods and CRUD helpers are left
# in place (harmless, unused) rather than also stripped, to keep this
# change minimal and easy to reverse if you want the buttons back later.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

python3 << 'PYEOF'
def strip_block(path, edit_block, delete_block):
    with open(path) as f:
        content = f.read()

    edit_count = content.count(edit_block)
    delete_count = content.count(delete_block)

    if edit_count != 1:
        raise SystemExit(f"Error: expected exactly 1 Edit block in {path}, found {edit_count}.")
    if delete_count != 1:
        raise SystemExit(f"Error: expected exactly 1 Delete block in {path}, found {delete_count}.")

    content = content.replace(edit_block, "")
    content = content.replace(delete_block, "")

    with open(path, "w") as f:
        f.write(content)

    print(f"Removed Edit and Delete buttons from {path}")


# --- Goals screen ---
goals_edit = """                      Semantics(
                        button: true,
                        label: 'Edit ${goal.title}',
                        excludeSemantics: true,
                        onTap: () => _editGoal(goal),
                        child: IconButton(
                          onPressed: () => _editGoal(goal),
                          icon: const Icon(Icons.edit, color: Colors.white70),
                        ),
                      ),
"""
goals_delete = """                      Semantics(
                        button: true,
                        label: 'Delete ${goal.title}',
                        excludeSemantics: true,
                        onTap: () => _deleteGoal(goal),
                        child: IconButton(
                          onPressed: () => _deleteGoal(goal),
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                      ),
"""
strip_block("lib/version_a/screens/goals_list_screen.dart", goals_edit, goals_delete)

# --- Tasks screen ---
tasks_edit = """                      Semantics(
                        button: true,
                        label: 'Edit ${task.title}',
                        excludeSemantics: true,
                        onTap: () => _editTask(task),
                        child: IconButton(
                          onPressed: () => _editTask(task),
                          icon: const Icon(Icons.edit, color: Colors.white70),
                        ),
                      ),
"""
tasks_delete = """                      Semantics(
                        button: true,
                        label: 'Delete ${task.title}',
                        excludeSemantics: true,
                        onTap: () => _deleteTask(task),
                        child: IconButton(
                          onPressed: () => _deleteTask(task),
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                      ),
"""
strip_block("lib/version_a/screens/tasks_list_screen.dart", tasks_edit, tasks_delete)

# --- Steps screen ---
steps_edit = """                      Semantics(
                        button: true,
                        label: 'Edit ${step.title}',
                        excludeSemantics: true,
                        onTap: () => _editStep(step),
                        child: IconButton(
                          onPressed: () => _editStep(step),
                          icon: const Icon(Icons.edit, color: Colors.white70),
                        ),
                      ),
"""
steps_delete = """                      Semantics(
                        button: true,
                        label: 'Delete ${step.title}',
                        excludeSemantics: true,
                        onTap: () => _deleteStep(step),
                        child: IconButton(
                          onPressed: () => _deleteStep(step),
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                      ),
"""
strip_block("lib/version_a/screens/steps_list_screen.dart", steps_edit, steps_delete)
PYEOF

echo ""
echo "Done. Run: flutter run"
