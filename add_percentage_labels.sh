#!/bin/bash
# Adds a percentage label to the right of each Goal and Task progress
# bar (e.g. "60%"), reflecting the same value already computed by
# goalStepProgress() / taskStepProgress().
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

# --- Goals: wrap progress bar + label in a Row ---
python3 << 'PYEOF'
path = "lib/version_a/screens/goals_list_screen.dart"
with open(path) as f:
    content = f.read()

old = """                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: goalStepProgress(goal),
                                            minHeight: 6,
                                            backgroundColor: Colors.grey[800],
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                          ),
                                        ),
                                      ],
                                    ),"""

new = """                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: goalStepProgress(goal),
                                                  minHeight: 6,
                                                  backgroundColor: Colors.grey[800],
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${(goalStepProgress(goal) * 100).round()}%',
                                              style: TextStyle(color: Colors.grey[300], fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),"""

count = content.count(old)
if count != 1:
    raise SystemExit(f"Error: expected exactly 1 match in {path}, found {count}. Paste a fresh `cat` of this file.")

content = content.replace(old, new, 1)

with open(path, "w") as f:
    f.write(content)

print(f"Updated {path}: percentage label added next to goal progress bar")
PYEOF

# --- Tasks: wrap progress bar + label in a Row ---
python3 << 'PYEOF'
path = "lib/version_a/screens/tasks_list_screen.dart"
with open(path) as f:
    content = f.read()

old = """                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: taskStepProgress(task),
                                            minHeight: 6,
                                            backgroundColor: Colors.grey[800],
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                          ),
                                        ),
                                      ],
                                    ),"""

new = """                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: taskStepProgress(task),
                                                  minHeight: 6,
                                                  backgroundColor: Colors.grey[800],
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${(taskStepProgress(task) * 100).round()}%',
                                              style: TextStyle(color: Colors.grey[300], fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),"""

count = content.count(old)
if count != 1:
    raise SystemExit(f"Error: expected exactly 1 match in {path}, found {count}. Paste a fresh `cat` of this file.")

content = content.replace(old, new, 1)

with open(path, "w") as f:
    f.write(content)

print(f"Updated {path}: percentage label added next to task progress bar")
PYEOF

echo ""
echo "Done. Run: flutter run"
