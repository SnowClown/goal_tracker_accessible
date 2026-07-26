#!/bin/bash
# Adds derived completion logic:
# - A Task is only "Completed" if ALL of its Steps are completed
#   (tasks with no steps yet fall back to their own stored completed flag)
# - A Goal is only "Completed" if ALL of its Tasks are derived-completed
# Updates the Tasks and Goals screens to show this derived state
# instead of trusting the raw stored 'completed' field directly.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

# --- 1. Add derived-completion helper functions to the shared model ---
cat >> lib/shared/models.dart << 'EOF'

/// A Task is only considered completed if ALL of its Steps are completed.
/// If a Task has no Steps yet, its own stored 'completed' flag is used
/// as a fallback (nothing to derive from).
bool isTaskCompleted(Task task) {
  final steps = stepsForTask(task.id);
  if (steps.isEmpty) return task.completed;
  return steps.every((s) => s.completed);
}

/// A Goal is only considered completed if ALL of its Tasks are
/// derived-completed (per isTaskCompleted above).
bool isGoalCompleted(Goal goal) {
  final tasks = tasksForGoal(goal.id);
  if (tasks.isEmpty) return false;
  return tasks.every((t) => isTaskCompleted(t));
}
EOF

echo "Appended isTaskCompleted() / isGoalCompleted() to lib/shared/models.dart"

# --- 2. Update Tasks screen to show derived completion, not the raw field ---
cat > lib/version_a/screens/tasks_list_screen.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/semantics.dart';
import '../../shared/models.dart';
import 'steps_list_screen.dart';

/// Version A Tasks list — shows tasks belonging to a single Goal.
/// A task's completed/uncompleted state shown here is DERIVED from
/// its Steps (isTaskCompleted), not read directly from the stored
/// Task.completed field, per the Goals > Tasks > Steps completion rule.
/// Double-tapping a task navigates into its Steps list (checkboxes
/// live there, not on this screen).
class TasksListScreen extends StatefulWidget {
  final Goal goal;

  const TasksListScreen({super.key, required this.goal});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  late List<Task> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = tasksForGoal(widget.goal.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        '${widget.goal.title} tasks. ${_tasks.length} tasks listed.',
        TextDirection.ltr,
      );
    });
  }

  void _openTask(Task task) {
    SemanticsService.announce('${task.title} selected.', TextDirection.ltr);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StepsListScreen(task: task)),
    ).then((_) {
      // Steps may have changed completion state while on that screen;
      // refresh so this screen's derived task status stays accurate.
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.goal.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final completed = isTaskCompleted(task);
          final statusLabel = completed ? 'Completed' : 'Uncompleted';

          return Semantics(
            button: true,
            label: '${task.title}. $statusLabel.',
            excludeSemantics: true,
            onTap: () => _openTask(task),
            child: Material(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openTask(task),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
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
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
EOF

echo "Updated lib/version_a/screens/tasks_list_screen.dart (now shows derived completion)"

# --- 3. Update Goals screen to show derived completion too ---
cat > lib/version_a/screens/goals_list_screen.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/semantics.dart';
import '../../shared/models.dart';
import 'tasks_list_screen.dart';

/// Version A Goals list — vision-accessibility focused.
/// A goal's completed/uncompleted state shown here is DERIVED from
/// its Tasks (isGoalCompleted), which is itself derived from each
/// task's Steps, per the Goals > Tasks > Steps completion rule.
class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'Goals screen. ${sampleGoals.length} goals listed.',
        TextDirection.ltr,
      );
    });
  }

  void _selectGoal(Goal goal) {
    SemanticsService.announce('${goal.title} selected.', TextDirection.ltr);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TasksListScreen(goal: goal)),
    ).then((_) {
      // Tasks may have changed completion state while on that screen;
      // refresh so this screen's derived goal status stays accurate.
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Your Goals',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sampleGoals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final goal = sampleGoals[index];
          final completed = isGoalCompleted(goal);
          final statusLabel = completed ? 'Completed' : 'Uncompleted';
          final progressLabel =
              '${goal.completedTaskCount} of ${goal.taskCount} tasks complete';

          return Semantics(
            button: true,
            label: '${goal.title}. $statusLabel. $progressLabel.',
            excludeSemantics: true,
            onTap: () => _selectGoal(goal),
            child: Material(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _selectGoal(goal),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$statusLabel: ',
                              style: TextStyle(
                                color: completed ? Colors.greenAccent : Colors.grey[400],
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: goal.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progressLabel,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
EOF

echo "Updated lib/version_a/screens/goals_list_screen.dart (now shows derived completion)"
echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
