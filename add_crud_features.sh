#!/bin/bash
# Adds Add/Edit/Delete functionality for Goals, Tasks, and Steps.
# - Add: a FAB on each list screen opens an accessible text-entry dialog
# - Edit: a dedicated "Edit" icon button per row opens the same dialog, pre-filled
# - Delete: a dedicated "Delete" icon button per row opens a confirmation
#   dialog that warns about and cascades to any child Tasks/Steps
# All dialogs use proper Semantics labels, focus, and SemanticsService
# announcements consistent with the rest of the app.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

# --- 1. Add CRUD + ID-generation helpers to the shared model ---
cat >> lib/shared/models.dart << 'EOF'

// --- CRUD operations -------------------------------------------------
// Simple in-memory mutation helpers. Cascading deletes remove children
// (and grandchildren) so the data never contains orphaned Tasks/Steps.

int _nextGoalIdSeed = 100;
int _nextTaskIdSeed = 100;
int _nextStepIdSeed = 100;

String _newGoalId() => 'g${_nextGoalIdSeed++}';
String _newTaskId() => 't${_nextTaskIdSeed++}';
String _newStepId() => 's${_nextStepIdSeed++}';

Goal addGoal(String title) {
  final goal = Goal(id: _newGoalId(), title: title);
  sampleGoals.add(goal);
  return goal;
}

void updateGoalTitle(Goal goal, String newTitle) {
  final index = sampleGoals.indexWhere((g) => g.id == goal.id);
  if (index == -1) return;
  sampleGoals[index] = Goal(
    id: goal.id,
    title: newTitle,
    taskCount: goal.taskCount,
    completedTaskCount: goal.completedTaskCount,
  );
}

/// Deletes a Goal and cascades to all its Tasks and their Steps.
/// Returns the number of tasks and steps that were removed, so the
/// caller can show an accurate warning before confirming.
({int taskCount, int stepCount}) goalDeletionImpact(Goal goal) {
  final tasks = tasksForGoal(goal.id);
  final stepCount = tasks.fold<int>(0, (sum, t) => sum + stepsForTask(t.id).length);
  return (taskCount: tasks.length, stepCount: stepCount);
}

void deleteGoal(Goal goal) {
  final tasks = tasksForGoal(goal.id);
  for (final task in tasks) {
    sampleSteps.removeWhere((s) => s.taskId == task.id);
  }
  sampleTasks.removeWhere((t) => t.goalId == goal.id);
  sampleGoals.removeWhere((g) => g.id == goal.id);
}

Task addTask(String goalId, String title) {
  final task = Task(id: _newTaskId(), goalId: goalId, title: title);
  sampleTasks.add(task);
  return task;
}

void updateTaskTitle(Task task, String newTitle) {
  final index = sampleTasks.indexWhere((t) => t.id == task.id);
  if (index == -1) return;
  sampleTasks[index] = Task(
    id: task.id,
    goalId: task.goalId,
    title: newTitle,
    completed: task.completed,
  );
}

/// Deletes a Task and cascades to all its Steps.
/// Returns the number of steps that were removed.
int taskDeletionImpact(Task task) => stepsForTask(task.id).length;

void deleteTask(Task task) {
  sampleSteps.removeWhere((s) => s.taskId == task.id);
  sampleTasks.removeWhere((t) => t.id == task.id);
}

Step addStep(String taskId, String title) {
  final step = Step(id: _newStepId(), taskId: taskId, title: title);
  sampleSteps.add(step);
  return step;
}

void updateStepTitle(Step step, String newTitle) {
  final index = sampleSteps.indexWhere((s) => s.id == step.id);
  if (index == -1) return;
  sampleSteps[index] = Step(
    id: step.id,
    taskId: step.taskId,
    title: newTitle,
    completed: step.completed,
  );
}

void deleteStep(Step step) {
  sampleSteps.removeWhere((s) => s.id == step.id);
}
EOF

echo "Appended CRUD helpers to lib/shared/models.dart"

# --- 2. Shared accessible dialogs (text entry + delete confirmation) ---
mkdir -p lib/version_a/widgets

cat > lib/version_a/widgets/accessible_dialogs.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/semantics.dart';

/// Shows an accessible text-entry dialog for adding or editing an item
/// title. Returns the entered text, or null if cancelled.
///
/// - Announces its purpose when opened
/// - Auto-focuses the text field so a screen reader user lands
///   directly on it without extra navigation
/// - Save button is disabled (and announced as such) when the field
///   is empty, to avoid creating blank items
Future<String?> showAccessibleTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  final focusNode = FocusNode();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    SemanticsService.announce(title, TextDirection.ltr);
    focusNode.requestFocus();
  });

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final canSave = controller.text.trim().isNotEmpty;
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.grey[300]),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop(value.trim());
                }
              },
            ),
            actions: [
              Semantics(
                button: true,
                label: 'Cancel',
                excludeSemantics: true,
                onTap: () => Navigator.of(context).pop(null),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
              ),
              Semantics(
                button: true,
                enabled: canSave,
                label: canSave ? 'Save' : 'Save. Disabled. Enter a title first.',
                excludeSemantics: true,
                onTap: canSave
                    ? () => Navigator.of(context).pop(controller.text.trim())
                    : null,
                child: TextButton(
                  onPressed: canSave
                      ? () => Navigator.of(context).pop(controller.text.trim())
                      : null,
                  child: const Text('Save'),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Shows an accessible delete-confirmation dialog. If [impactMessage]
/// is non-null (e.g. "This will also delete 3 tasks and 5 steps."),
/// it is included in both the visible text and the spoken announcement
/// so screen reader users get the same warning as sighted users.
/// Returns true if the user confirmed deletion.
Future<bool> showAccessibleDeleteConfirmation(
  BuildContext context, {
  required String itemTitle,
  String? impactMessage,
}) async {
  final message = impactMessage == null
      ? 'Delete "$itemTitle"? This cannot be undone.'
      : 'Delete "$itemTitle"? $impactMessage This cannot be undone.';

  WidgetsBinding.instance.addPostFrameCallback((_) {
    SemanticsService.announce(message, TextDirection.ltr);
  });

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Confirm delete', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          Semantics(
            button: true,
            label: 'Cancel',
            excludeSemantics: true,
            onTap: () => Navigator.of(context).pop(false),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          Semantics(
            button: true,
            label: 'Confirm delete',
            excludeSemantics: true,
            onTap: () => Navigator.of(context).pop(true),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
EOF

echo "Created lib/version_a/widgets/accessible_dialogs.dart"
echo ""
echo "Step 1 of 2 done. Now run add_crud_ui_screens.sh to wire these into"
echo "the Goals, Tasks, and Steps screens."
