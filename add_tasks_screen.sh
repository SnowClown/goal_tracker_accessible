#!/bin/bash
# Adds a Task model, sample task data, and the Version A Tasks list
# screen, then wires up navigation from the Goals list into it.
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

# --- 1. Extend the shared model with Task + sample tasks ---
cat > lib/shared/models.dart << 'EOF'
/// Shared data model used by both Version A and Version B.
/// Kept deliberately simple for now — extend as the app grows.
class Goal {
  final String id;
  final String title;
  final int taskCount;
  final int completedTaskCount;

  const Goal({
    required this.id,
    required this.title,
    this.taskCount = 0,
    this.completedTaskCount = 0,
  });
}

class Task {
  final String id;
  final String goalId;
  final String title;
  final bool completed;

  const Task({
    required this.id,
    required this.goalId,
    required this.title,
    this.completed = false,
  });
}

/// Temporary in-memory sample data so the UI has something to show
/// before real persistence/storage is wired up.
final List<Goal> sampleGoals = [
  const Goal(id: '1', title: 'Learn Mandarin', taskCount: 5, completedTaskCount: 2),
  const Goal(id: '2', title: 'Finish bamboo conduit project', taskCount: 3, completedTaskCount: 1),
  const Goal(id: '3', title: 'Release Goal Tracker on Play Store', taskCount: 8, completedTaskCount: 6),
];

final List<Task> sampleTasks = [
  const Task(id: 't1', goalId: '1', title: 'Learn the four tones', completed: true),
  const Task(id: 't2', goalId: '1', title: 'Memorize 100 basic characters', completed: true),
  const Task(id: 't3', goalId: '1', title: 'Complete HSK1 vocabulary list', completed: false),
  const Task(id: 't4', goalId: '1', title: 'Practice speaking with a tutor', completed: false),
  const Task(id: 't5', goalId: '1', title: 'Watch a beginner Mandarin show', completed: false),

  const Task(id: 't6', goalId: '2', title: 'Source large-diameter bamboo', completed: true),
  const Task(id: 't7', goalId: '2', title: 'Cure and treat the bamboo', completed: false),
  const Task(id: 't8', goalId: '2', title: 'Run cable through conduit', completed: false),

  const Task(id: 't9', goalId: '3', title: 'Fix release build crashes', completed: true),
  const Task(id: 't10', goalId: '3', title: 'Set up Play Console billing', completed: true),
  const Task(id: 't11', goalId: '3', title: 'Finish translation coverage', completed: true),
  const Task(id: 't12', goalId: '3', title: 'Add monetization tiers', completed: true),
  const Task(id: 't13', goalId: '3', title: 'Polish onboarding flow', completed: true),
  const Task(id: 't14', goalId: '3', title: 'Submit for review', completed: true),
  const Task(id: 't15', goalId: '3', title: 'Respond to review feedback', completed: false),
  const Task(id: 't16', goalId: '3', title: 'Public launch', completed: false),
];

List<Task> tasksForGoal(String goalId) =>
    sampleTasks.where((t) => t.goalId == goalId).toList();
EOF

echo "Updated lib/shared/models.dart"

# --- 2. Tasks list screen (Version A) ---
cat > lib/version_a/screens/tasks_list_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../shared/models.dart';

/// Version A Tasks list — shows tasks belonging to a single Goal.
/// Same accessibility approach as the Goals list:
/// - Single Semantics label per row, child text excluded from the tree
/// - onTap attached directly to Semantics so double-tap activates reliably
/// - Announcements via SemanticsService (single voice, no competing TTS)
/// - High-contrast theme, large touch targets, system text scaling
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

  void _toggleTask(Task task) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      _tasks[index] = Task(
        id: task.id,
        goalId: task.goalId,
        title: task.title,
        completed: !task.completed,
      );
    });
    final updated = _tasks.firstWhere((t) => t.id == task.id);
    SemanticsService.announce(
      '${task.title}, ${updated.completed ? "marked complete" : "marked incomplete"}.',
      TextDirection.ltr,
    );
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
          final statusLabel = task.completed ? 'Completed' : 'Not completed';

          return Semantics(
            button: true,
            label: '${task.title}. $statusLabel.',
            excludeSemantics: true,
            onTap: () => _toggleTask(task),
            child: Material(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleTask(task),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: task.completed ? Colors.greenAccent : Colors.grey[400],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: Colors.grey[400],
                          ),
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

echo "Created lib/version_a/screens/tasks_list_screen.dart"

# --- 3. Wire up navigation from Goals list ---
cat > lib/version_a/screens/goals_list_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../shared/models.dart';
import 'tasks_list_screen.dart';

/// Version A Goals list — vision-accessibility focused:
/// - Explicit Semantics labels on every interactive element, with
///   excludeSemantics on child widgets so TalkBack reads each goal
///   exactly once (not once for the label, once for the raw text).
/// - onTap attached directly to the Semantics node so TalkBack's
///   double-tap gesture reliably activates the row.
/// - Respects system text scaling (no fixed font sizes)
/// - High-contrast theme (near-black background, pure white text)
/// - Large touch targets (min 64dp height per row)
/// - Announcements use SemanticsService.announce(), which speaks
///   through TalkBack/VoiceOver's own voice — NOT a separate TTS
///   engine, which previously caused two voices talking over
///   each other.
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
    );
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
          final progressLabel =
              '${goal.completedTaskCount} of ${goal.taskCount} tasks complete';

          return Semantics(
            button: true,
            label: '${goal.title}. $progressLabel.',
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
                      Text(
                        goal.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
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

echo "Updated lib/version_a/screens/goals_list_screen.dart (now navigates to TasksListScreen)"
echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
