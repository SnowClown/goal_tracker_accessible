#!/bin/bash
# Removes all SemanticsService.announce() calls across Version A screens
# and dialogs. TalkBack already reads each widget's Semantics label
# automatically when focus lands on it (via swipe navigation) and
# announces new screen titles on route changes — manual announcements
# were redundant and could talk over TalkBack's own speech.
# Semantics labels themselves are UNCHANGED; only the imperative
# announce() calls are removed.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

# --- Goals list screen ---
cat > lib/version_a/screens/goals_list_screen.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;
import '../../shared/models.dart';
import '../widgets/accessible_dialogs.dart';
import 'tasks_list_screen.dart';

/// Version A Goals list. Supports Add, Edit, and Delete (with cascade
/// warning) in addition to navigation into a goal's Tasks.
/// Audible navigation is handled entirely by the system screen reader
/// (TalkBack / VoiceOver) reading each Semantics label as focus moves —
/// no app-driven TTS or manual announcements are used.
class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  void _selectGoal(Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TasksListScreen(goal: goal)),
    ).then((_) => setState(() {}));
  }

  Future<void> _addGoal() async {
    final title = await showAccessibleTextDialog(
      context,
      title: 'Add goal',
      label: 'Goal title',
    );
    if (title == null) return;
    setState(() => addGoal(title));
  }

  Future<void> _editGoal(Goal goal) async {
    final title = await showAccessibleTextDialog(
      context,
      title: 'Edit goal',
      label: 'Goal title',
      initialValue: goal.title,
    );
    if (title == null) return;
    setState(() => updateGoalTitle(goal, title));
  }

  Future<void> _deleteGoal(Goal goal) async {
    final impact = goalDeletionImpact(goal);
    final parts = <String>[];
    if (impact.taskCount > 0) parts.add('${impact.taskCount} tasks');
    if (impact.stepCount > 0) parts.add('${impact.stepCount} steps');
    final impactMessage = parts.isEmpty
        ? null
        : 'This will also delete ${parts.join(' and ')}.';

    final confirmed = await showAccessibleDeleteConfirmation(
      context,
      itemTitle: goal.title,
      impactMessage: impactMessage,
    );
    if (!confirmed) return;
    setState(() => deleteGoal(goal));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Your Goals', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Add goal',
        excludeSemantics: true,
        onTap: _addGoal,
        child: FloatingActionButton(
          onPressed: _addGoal,
          backgroundColor: Colors.greenAccent,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: sampleGoals.isEmpty
          ? const Center(
              child: Text('No goals yet. Use the Add button to create one.',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                  textAlign: TextAlign.center),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sampleGoals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = sampleGoals[index];
                final completed = isGoalCompleted(goal);
                final statusLabel = completed ? 'Completed' : 'Uncompleted';
                final progressLabel =
                    '${goal.completedTaskCount} of ${goal.taskCount} tasks complete';

                return Material(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: '${goal.title}. $statusLabel. $progressLabel.',
                          excludeSemantics: true,
                          onTap: () => _selectGoal(goal),
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
                                        text: goal.title,
                                        style: const TextStyle(
                                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(progressLabel, style: TextStyle(color: Colors.grey[300], fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Edit ${goal.title}',
                        excludeSemantics: true,
                        onTap: () => _editGoal(goal),
                        child: IconButton(
                          onPressed: () => _editGoal(goal),
                          icon: const Icon(Icons.edit, color: Colors.white70),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Delete ${goal.title}',
                        excludeSemantics: true,
                        onTap: () => _deleteGoal(goal),
                        child: IconButton(
                          onPressed: () => _deleteGoal(goal),
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
EOF

echo "Updated lib/version_a/screens/goals_list_screen.dart"

# --- Tasks list screen ---
cat > lib/version_a/screens/tasks_list_screen.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;
import '../../shared/models.dart';
import '../widgets/accessible_dialogs.dart';
import 'steps_list_screen.dart';

/// Version A Tasks list. Supports Add, Edit, and Delete (with cascade
/// warning) in addition to navigation into a task's Steps.
/// Audible navigation is handled entirely by the system screen reader.
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
    _refresh();
  }

  void _refresh() {
    _tasks = tasksForGoal(widget.goal.id);
  }

  void _openTask(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StepsListScreen(task: task)),
    ).then((_) => setState(_refresh));
  }

  Future<void> _addTask() async {
    final title = await showAccessibleTextDialog(
      context,
      title: 'Add task',
      label: 'Task title',
    );
    if (title == null) return;
    setState(() {
      addTask(widget.goal.id, title);
      _refresh();
    });
  }

  Future<void> _editTask(Task task) async {
    final title = await showAccessibleTextDialog(
      context,
      title: 'Edit task',
      label: 'Task title',
      initialValue: task.title,
    );
    if (title == null) return;
    setState(() {
      updateTaskTitle(task, title);
      _refresh();
    });
  }

  Future<void> _deleteTask(Task task) async {
    final stepCount = taskDeletionImpact(task);
    final impactMessage = stepCount > 0 ? 'This will also delete $stepCount steps.' : null;

    final confirmed = await showAccessibleDeleteConfirmation(
      context,
      itemTitle: task.title,
      impactMessage: impactMessage,
    );
    if (!confirmed) return;
    setState(() {
      deleteTask(task);
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.goal.title, style: const TextStyle(color: Colors.white)),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Add task',
        excludeSemantics: true,
        onTap: _addTask,
        child: FloatingActionButton(
          onPressed: _addTask,
          backgroundColor: Colors.greenAccent,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: _tasks.isEmpty
          ? const Center(
              child: Text('No tasks yet. Use the Add button to create one.',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                  textAlign: TextAlign.center),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final completed = isTaskCompleted(task);
                final statusLabel = completed ? 'Completed' : 'Uncompleted';

                return Material(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: '${task.title}. $statusLabel.',
                          excludeSemantics: true,
                          onTap: () => _openTask(task),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openTask(task),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 64),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: RichText(
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
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Edit ${task.title}',
                        excludeSemantics: true,
                        onTap: () => _editTask(task),
                        child: IconButton(
                          onPressed: () => _editTask(task),
                          icon: const Icon(Icons.edit, color: Colors.white70),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Delete ${task.title}',
                        excludeSemantics: true,
                        onTap: () => _deleteTask(task),
                        child: IconButton(
                          onPressed: () => _deleteTask(task),
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
EOF

echo "Updated lib/version_a/screens/tasks_list_screen.dart"

# --- Steps list screen ---
cat > lib/version_a/screens/steps_list_screen.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;
import '../../shared/models.dart';
import '../widgets/accessible_dialogs.dart';

/// Version A Steps list. Supports Add, Edit, and Delete of individual
/// Steps, plus double-tap toggle for completion state.
/// Audible navigation is handled entirely by the system screen reader.
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
    _refresh();
  }

  void _refresh() {
    _steps = stepsForTask(widget.task.id);
  }

  void _toggleCompletion(Step step) {
    final newCompleted = !step.completed;
    setState(() {
      final index = _steps.indexWhere((s) => s.id == step.id);
      _steps[index] = Step(id: step.id, taskId: step.taskId, title: step.title, completed: newCompleted);
      final globalIndex = sampleSteps.indexWhere((s) => s.id == step.id);
      if (globalIndex != -1) {
        sampleSteps[globalIndex] = _steps[index];
      }
    });
  }

  Future<void> _addStep() async {
    final title = await showAccessibleTextDialog(
      context,
      title: 'Add step',
      label: 'Step title',
    );
    if (title == null) return;
    setState(() {
      addStep(widget.task.id, title);
      _refresh();
    });
  }

  Future<void> _editStep(Step step) async {
    final title = await showAccessibleTextDialog(
      context,
      title: 'Edit step',
      label: 'Step title',
      initialValue: step.title,
    );
    if (title == null) return;
    setState(() {
      updateStepTitle(step, title);
      _refresh();
    });
  }

  Future<void> _deleteStep(Step step) async {
    final confirmed = await showAccessibleDeleteConfirmation(
      context,
      itemTitle: step.title,
    );
    if (!confirmed) return;
    setState(() {
      deleteStep(step);
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.task.title, style: const TextStyle(color: Colors.white)),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Add step',
        excludeSemantics: true,
        onTap: _addStep,
        child: FloatingActionButton(
          onPressed: _addStep,
          backgroundColor: Colors.greenAccent,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: _steps.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No steps yet. Use the Add button to create one.',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                    textAlign: TextAlign.center),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final step = _steps[index];
                final prefix = step.completed ? 'Completed: ' : 'Uncompleted: ';

                return Material(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: '$prefix${step.title}.',
                          excludeSemantics: true,
                          onTap: () => _toggleCompletion(step),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _toggleCompletion(step),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 64),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                      text: prefix,
                                      style: TextStyle(
                                        color: step.completed ? Colors.greenAccent : Colors.grey[400],
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: step.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Edit ${step.title}',
                        excludeSemantics: true,
                        onTap: () => _editStep(step),
                        child: IconButton(
                          onPressed: () => _editStep(step),
                          icon: const Icon(Icons.edit, color: Colors.white70),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Delete ${step.title}',
                        excludeSemantics: true,
                        onTap: () => _deleteStep(step),
                        child: IconButton(
                          onPressed: () => _deleteStep(step),
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
EOF

echo "Updated lib/version_a/screens/steps_list_screen.dart"

# --- Accessible dialogs (remove announce calls, keep everything else) ---
cat > lib/version_a/widgets/accessible_dialogs.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;

/// Shows an accessible text-entry dialog for adding or editing an item
/// title. Returns the entered text, or null if cancelled.
///
/// - Auto-focuses the text field so a screen reader user lands
///   directly on it without extra navigation
/// - Save button is disabled (and labeled as such) when the field
///   is empty, to avoid creating blank items
/// - The dialog's own title/labels are read by the system screen
///   reader automatically as focus lands on them; no manual TTS.
Future<String?> showAccessibleTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  final focusNode = FocusNode();

  WidgetsBinding.instance.addPostFrameCallback((_) {
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
/// it is included in the visible/Semantics text so the screen reader
/// reads the same warning a sighted user sees.
/// Returns true if the user confirmed deletion.
Future<bool> showAccessibleDeleteConfirmation(
  BuildContext context, {
  required String itemTitle,
  String? impactMessage,
}) async {
  final message = impactMessage == null
      ? 'Delete "$itemTitle"? This cannot be undone.'
      : 'Delete "$itemTitle"? $impactMessage This cannot be undone.';

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

echo "Updated lib/version_a/widgets/accessible_dialogs.dart"
echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
