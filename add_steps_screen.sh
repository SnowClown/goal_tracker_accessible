#!/bin/bash
# Adds a Step model + sample steps, a Version A Steps list screen with
# checkboxes, and rewires the Tasks screen so double-tapping a task
# navigates into its Steps (instead of toggling the task directly).
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

# --- 1. Extend shared model with Step + sample steps ---
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

class Step {
  final String id;
  final String taskId;
  final String title;
  final bool completed;

  const Step({
    required this.id,
    required this.taskId,
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

final List<Step> sampleSteps = [
  const Step(id: 's1', taskId: 't3', title: 'Review HSK1 word list part 1', completed: true),
  const Step(id: 's2', taskId: 't3', title: 'Review HSK1 word list part 2', completed: false),
  const Step(id: 's3', taskId: 't3', title: 'Self-test all 150 words', completed: false),

  const Step(id: 's4', taskId: 't4', title: 'Book a session with tutor', completed: false),
  const Step(id: 's5', taskId: 't4', title: 'Prepare topics to discuss', completed: false),

  const Step(id: 's6', taskId: 't7', title: 'Sand and clean sections', completed: true),
  const Step(id: 's7', taskId: 't7', title: 'Apply borax treatment', completed: false),
  const Step(id: 's8', taskId: 't7', title: 'Let cure for required time', completed: false),

  const Step(id: 's9', taskId: 't15', title: 'Read reviewer feedback notes', completed: false),
  const Step(id: 's10', taskId: 't15', title: 'Make requested changes', completed: false),
  const Step(id: 's11', taskId: 't15', title: 'Resubmit for review', completed: false),
];

List<Task> tasksForGoal(String goalId) =>
    sampleTasks.where((t) => t.goalId == goalId).toList();

List<Step> stepsForTask(String taskId) =>
    sampleSteps.where((s) => s.taskId == taskId).toList();
EOF

echo "Updated lib/shared/models.dart (added Step model + sample steps)"

# --- 2. Steps list screen (Version A) — checkboxes live here ---
cat > lib/version_a/screens/steps_list_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../shared/models.dart';

/// Version A Steps list — the bottom of the Goals > Tasks > Steps
/// hierarchy. Checkboxes for marking individual steps complete live
/// here (not on the Tasks screen).
/// Same accessibility approach as Goals/Tasks screens:
/// - Single Semantics label per row (includes checked/unchecked state)
/// - onTap attached directly to Semantics so double-tap toggles reliably
/// - Announcements via SemanticsService (single voice, no competing TTS)
/// - High-contrast theme, large touch targets, system text scaling
class StepsListScreen extends StatefulWidget {
  final Task task;

  const StepsListScreen({super.key, required this.task});

  @override
  State<StepsListScreen> createState() => _StepsListScreenState();
}

class _StepsListScreenState extends State<StepsListScreen> {
  late List<Step> _steps;

  @override
  void initState() {
    super.initState();
    _steps = stepsForTask(widget.task.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        '${widget.task.title} steps. ${_steps.length} steps listed.',
        TextDirection.ltr,
      );
    });
  }

  void _toggleStep(Step step) {
    setState(() {
      final index = _steps.indexWhere((s) => s.id == step.id);
      _steps[index] = Step(
        id: step.id,
        taskId: step.taskId,
        title: step.title,
        completed: !step.completed,
      );
    });
    final updated = _steps.firstWhere((s) => s.id == step.id);
    SemanticsService.announce(
      '${step.title}, ${updated.completed ? "checked" : "unchecked"}.',
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
          widget.task.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _steps.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No steps yet for this task.',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final step = _steps[index];
                final statusLabel = step.completed ? 'Checked' : 'Unchecked';

                return Semantics(
                  button: true,
                  checked: step.completed,
                  label: '${step.title}. $statusLabel.',
                  excludeSemantics: true,
                  onTap: () => _toggleStep(step),
                  child: Material(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _toggleStep(step),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 64),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Checkbox(
                              value: step.completed,
                              onChanged: (_) => _toggleStep(step),
                              activeColor: Colors.greenAccent,
                              checkColor: Colors.black,
                              side: const BorderSide(color: Colors.white70, width: 2),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  decoration: step.completed
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

echo "Created lib/version_a/screens/steps_list_screen.dart"

# --- 3. Rewire Tasks screen: double-tap now navigates to Steps ---
cat > lib/version_a/screens/tasks_list_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../shared/models.dart';
import 'steps_list_screen.dart';

/// Version A Tasks list — shows tasks belonging to a single Goal.
/// Double-tapping a task navigates into its Steps list (checkboxes
/// live there, not on this screen).
/// Same accessibility approach as Goals/Steps screens:
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

  void _openTask(Task task) {
    SemanticsService.announce('${task.title} selected.', TextDirection.ltr);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StepsListScreen(task: task)),
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

echo "Updated lib/version_a/screens/tasks_list_screen.dart (now navigates to StepsListScreen)"
echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
