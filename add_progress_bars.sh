#!/bin/bash
# Adds a progress bar under each Goal and Task, based on the
# percentage of Steps completed:
# - Task progress: completed steps / total steps for that task
#   (falls back to the task's own completed flag if it has no steps)
# - Goal progress: completed steps / total steps across ALL of that
#   goal's tasks combined (falls back to the goal's completed flag
#   if none of its tasks have any steps yet)
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

# --- 1. Add progress-calculation helpers to the shared model ---
cat >> lib/shared/models.dart << 'EOF'

/// Fraction (0.0 - 1.0) of a Task's Steps that are completed.
/// Falls back to the Task's own completed flag if it has no Steps.
double taskStepProgress(Task task) {
  final steps = stepsForTask(task.id);
  if (steps.isEmpty) return isTaskCompleted(task) ? 1.0 : 0.0;
  final completedCount = steps.where((s) => s.completed).length;
  return completedCount / steps.length;
}

/// Fraction (0.0 - 1.0) of a Goal's Steps (across ALL its Tasks) that
/// are completed. Falls back to the Goal's own completed flag if none
/// of its Tasks have any Steps yet.
double goalStepProgress(Goal goal) {
  final tasks = tasksForGoal(goal.id);
  final allSteps = tasks.expand((t) => stepsForTask(t.id)).toList();
  if (allSteps.isEmpty) return isGoalCompleted(goal) ? 1.0 : 0.0;
  final completedCount = allSteps.where((s) => s.completed).length;
  return completedCount / allSteps.length;
}
EOF
echo "Appended taskStepProgress() / goalStepProgress() to lib/shared/models.dart"

# --- 2. Add progress bar under each Goal row ---
python3 << 'PYEOF'
path = "lib/version_a/screens/goals_list_screen.dart"
with open(path) as f:
    content = f.read()

old = """                                        const SizedBox(height: 4),
                                        Text(progressLabel, style: TextStyle(color: Colors.grey[300], fontSize: 16)),
                                      ],
                                    ),"""

new = """                                        const SizedBox(height: 4),
                                        Text(progressLabel, style: TextStyle(color: Colors.grey[300], fontSize: 16)),
                                        const SizedBox(height: 6),
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

count = content.count(old)
if count != 1:
    raise SystemExit(f"Error: expected exactly 1 match in {path}, found {count}. Paste a fresh `cat` of this file.")

content = content.replace(old, new, 1)

with open(path, "w") as f:
    f.write(content)

print(f"Updated {path}: progress bar added under each goal")
PYEOF

# --- 3. Add progress bar under each Task row (wrap RichText in a Column) ---
python3 << 'PYEOF'
path = "lib/version_a/screens/tasks_list_screen.dart"
with open(path) as f:
    content = f.read()

old = """                                    child: RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text: '$statusLabel: ',
                                          style: TextStyle(
                                            color: completed ? Colors.greenAccent : Colors.grey[400],
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(
                                          text: task.title,
                                          style: const TextStyle(
                                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ]),
                                    ),"""

new = """                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        RichText(
                                          text: TextSpan(children: [
                                            TextSpan(
                                              text: '$statusLabel: ',
                                              style: TextStyle(
                                                color: completed ? Colors.greenAccent : Colors.grey[400],
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            TextSpan(
                                              text: task.title,
                                              style: const TextStyle(
                                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ]),
                                        ),
                                        const SizedBox(height: 6),
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

count = content.count(old)
if count != 1:
    raise SystemExit(f"Error: expected exactly 1 match in {path}, found {count}. Paste a fresh `cat` of this file.")

content = content.replace(old, new, 1)

with open(path, "w") as f:
    f.write(content)

print(f"Updated {path}: progress bar added under each task")
PYEOF

echo ""
echo "Done. Run: flutter run"
