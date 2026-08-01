#!/bin/bash
# Rewrites the Goals, Tasks, and Steps screens to support both
# interaction modes (Global controls / Dynamically displayed controls).
# Run add_global_controls_mode.sh FIRST, then this script.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

if [ ! -f "lib/shared/interface_config.dart" ]; then
  echo "Error: interface_config.dart not found. Run add_global_controls_mode.sh first."
  exit 1
fi

# --- Goals screen ---
cat > lib/version_a/screens/goals_list_screen.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;
import '../../shared/models.dart';
import '../../shared/interface_config.dart';
import '../widgets/accessible_dialogs.dart';
import '../widgets/more_actions_sheet.dart';
import '../widgets/action_types.dart';
import 'tasks_list_screen.dart';
import 'interface_configuration_screen.dart';

class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    interfaceConfig.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    interfaceConfig.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    if (mounted) setState(() => _selectedIds.clear());
  }

  void _selectGoal(Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TasksListScreen(goal: goal)),
    ).then((_) => setState(() {}));
  }

  Future<void> _addGoal() async {
    final title = await showAccessibleTextDialog(context, title: 'Add goal', label: 'Goal title');
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
    final impactMessage = parts.isEmpty ? null : 'This will also delete ${parts.join(' and ')}.';

    final confirmed = await showAccessibleDeleteConfirmation(
      context,
      itemTitle: goal.title,
      impactMessage: impactMessage,
    );
    if (!confirmed) return;
    setState(() => deleteGoal(goal));
  }

  Future<void> _handleGlobalAction(ActionDef action) async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one goal first.')),
      );
      return;
    }
    if (action.singleItemOnly && _selectedIds.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${action.label} only works on one goal at a time.')),
      );
      return;
    }

    final selected = sampleGoals.where((g) => _selectedIds.contains(g.id)).toList();

    if (action.label == 'Edit') {
      await _editGoal(selected.first);
    } else if (action.label == 'Delete') {
      if (selected.length == 1) {
        await _deleteGoal(selected.first);
      } else {
        final confirmed = await showAccessibleDeleteConfirmation(
          context,
          itemTitle: '${selected.length} goals',
          impactMessage: 'Any tasks and steps under them will also be deleted.',
        );
        if (confirmed) {
          setState(() {
            for (final g in selected) {
              deleteGoal(g);
            }
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${action.label}: coming soon.')),
      );
    }

    setState(() => _selectedIds.clear());
  }

  Widget _buildGlobalActionBar() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allItemActions.map((action) {
          return Semantics(
            button: true,
            label: action.label,
            excludeSemantics: true,
            onTap: () => _handleGlobalAction(action),
            child: InkWell(
              onTap: () => _handleGlobalAction(action),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 84,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, color: Colors.white, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      action.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalMode = interfaceConfig.useGlobalControls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Your Goals', style: TextStyle(color: Colors.white)),
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
      body: Column(
        children: [
          if (globalMode) _buildGlobalActionBar(),
          Expanded(
            child: sampleGoals.isEmpty
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
                      final progressLabel = '${goal.completedTaskCount} of ${goal.taskCount} tasks complete';
                      final isSelected = _selectedIds.contains(goal.id);

                      return Material(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            if (globalMode)
                              Semantics(
                                label: 'Select ${goal.title}',
                                checked: isSelected,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.greenAccent,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedIds.add(goal.id);
                                      } else {
                                        _selectedIds.remove(goal.id);
                                      }
                                    });
                                  },
                                ),
                              ),
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
                            if (!globalMode)
                              Semantics(
                                button: true,
                                label: 'More actions for ${goal.title}',
                                excludeSemantics: true,
                                onTap: () => showMoreActionsSheet(
                                  context,
                                  itemTitle: goal.title,
                                  onEdit: () => _editGoal(goal),
                                  onDelete: () => _deleteGoal(goal),
                                ),
                                child: IconButton(
                                  onPressed: () => showMoreActionsSheet(
                                    context,
                                    itemTitle: goal.title,
                                    onEdit: () => _editGoal(goal),
                                    onDelete: () => _deleteGoal(goal),
                                  ),
                                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
EOF
echo "Rewrote lib/version_a/screens/goals_list_screen.dart"

# --- Tasks screen ---
cat > lib/version_a/screens/tasks_list_screen.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;
import '../../shared/models.dart';
import '../../shared/interface_config.dart';
import '../widgets/accessible_dialogs.dart';
import '../widgets/more_actions_sheet.dart';
import '../widgets/action_types.dart';
import 'steps_list_screen.dart';

class TasksListScreen extends StatefulWidget {
  final Goal goal;

  const TasksListScreen({super.key, required this.goal});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  late List<Task> _tasks;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _refresh();
    interfaceConfig.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    interfaceConfig.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    if (mounted) setState(() => _selectedIds.clear());
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
    final title = await showAccessibleTextDialog(context, title: 'Add task', label: 'Task title');
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

  Future<void> _handleGlobalAction(ActionDef action) async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one task first.')),
      );
      return;
    }
    if (action.singleItemOnly && _selectedIds.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${action.label} only works on one task at a time.')),
      );
      return;
    }

    final selected = _tasks.where((t) => _selectedIds.contains(t.id)).toList();

    if (action.label == 'Edit') {
      await _editTask(selected.first);
    } else if (action.label == 'Delete') {
      if (selected.length == 1) {
        await _deleteTask(selected.first);
      } else {
        final confirmed = await showAccessibleDeleteConfirmation(
          context,
          itemTitle: '${selected.length} tasks',
          impactMessage: 'Any steps under them will also be deleted.',
        );
        if (confirmed) {
          setState(() {
            for (final t in selected) {
              deleteTask(t);
            }
            _refresh();
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${action.label}: coming soon.')),
      );
    }

    setState(() => _selectedIds.clear());
  }

  Widget _buildGlobalActionBar() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allItemActions.map((action) {
          return Semantics(
            button: true,
            label: action.label,
            excludeSemantics: true,
            onTap: () => _handleGlobalAction(action),
            child: InkWell(
              onTap: () => _handleGlobalAction(action),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 84,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, color: Colors.white, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      action.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalMode = interfaceConfig.useGlobalControls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.goal.title, style: const TextStyle(color: Colors.white)),
        leading: Semantics(
          button: true,
          label: 'Back to Goals',
          excludeSemantics: true,
          onTap: () => Navigator.of(context).pop(),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.green, size: 30),
          ),
        ),
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
      body: Column(
        children: [
          if (globalMode) _buildGlobalActionBar(),
          Expanded(
            child: _tasks.isEmpty
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
                      final isSelected = _selectedIds.contains(task.id);

                      return Material(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            if (globalMode)
                              Semantics(
                                label: 'Select ${task.title}',
                                checked: isSelected,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.greenAccent,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedIds.add(task.id);
                                      } else {
                                        _selectedIds.remove(task.id);
                                      }
                                    });
                                  },
                                ),
                              ),
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
                            if (!globalMode)
                              Semantics(
                                button: true,
                                label: 'More actions for ${task.title}',
                                excludeSemantics: true,
                                onTap: () => showMoreActionsSheet(
                                  context,
                                  itemTitle: task.title,
                                  onEdit: () => _editTask(task),
                                  onDelete: () => _deleteTask(task),
                                ),
                                child: IconButton(
                                  onPressed: () => showMoreActionsSheet(
                                    context,
                                    itemTitle: task.title,
                                    onEdit: () => _editTask(task),
                                    onDelete: () => _deleteTask(task),
                                  ),
                                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                                ),
                              ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
EOF
echo "Rewrote lib/version_a/screens/tasks_list_screen.dart"

# --- Steps screen ---
cat > lib/version_a/screens/steps_list_screen.dart << 'EOF'
import 'package:flutter/material.dart' hide Step;
import '../../shared/models.dart';
import '../../shared/interface_config.dart';
import '../widgets/accessible_dialogs.dart';
import '../widgets/more_actions_sheet.dart';
import '../widgets/action_types.dart';

class StepsListScreen extends StatefulWidget {
  final Task task;

  const StepsListScreen({super.key, required this.task});

  @override
  State<StepsListScreen> createState() => _StepsListScreenState();
}

class _StepsListScreenState extends State<StepsListScreen> {
  late List<Step> _steps;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _refresh();
    interfaceConfig.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    interfaceConfig.removeListener(_onConfigChanged);
    super.dispose();
  }

  void _onConfigChanged() {
    if (mounted) setState(() => _selectedIds.clear());
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
    final title = await showAccessibleTextDialog(context, title: 'Add step', label: 'Step title');
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
    final confirmed = await showAccessibleDeleteConfirmation(context, itemTitle: step.title);
    if (!confirmed) return;
    setState(() {
      deleteStep(step);
      _refresh();
    });
  }

  Future<void> _handleGlobalAction(ActionDef action) async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one step first.')),
      );
      return;
    }
    if (action.singleItemOnly && _selectedIds.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${action.label} only works on one step at a time.')),
      );
      return;
    }

    final selected = _steps.where((s) => _selectedIds.contains(s.id)).toList();

    if (action.label == 'Edit') {
      await _editStep(selected.first);
    } else if (action.label == 'Delete') {
      if (selected.length == 1) {
        await _deleteStep(selected.first);
      } else {
        final confirmed = await showAccessibleDeleteConfirmation(
          context,
          itemTitle: '${selected.length} steps',
        );
        if (confirmed) {
          setState(() {
            for (final s in selected) {
              deleteStep(s);
            }
            _refresh();
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${action.label}: coming soon.')),
      );
    }

    setState(() => _selectedIds.clear());
  }

  Widget _buildGlobalActionBar() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allItemActions.map((action) {
          return Semantics(
            button: true,
            label: action.label,
            excludeSemantics: true,
            onTap: () => _handleGlobalAction(action),
            child: InkWell(
              onTap: () => _handleGlobalAction(action),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 84,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, color: Colors.white, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      action.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalMode = interfaceConfig.useGlobalControls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.task.title, style: const TextStyle(color: Colors.white)),
        leading: Semantics(
          button: true,
          label: 'Back to Tasks',
          excludeSemantics: true,
          onTap: () => Navigator.of(context).pop(),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.green, size: 30),
          ),
        ),
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
      body: Column(
        children: [
          if (globalMode) _buildGlobalActionBar(),
          Expanded(
            child: _steps.isEmpty
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
                      final isSelected = _selectedIds.contains(step.id);

                      return Material(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            if (globalMode)
                              Semantics(
                                label: 'Select ${step.title}',
                                checked: isSelected,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.greenAccent,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedIds.add(step.id);
                                      } else {
                                        _selectedIds.remove(step.id);
                                      }
                                    });
                                  },
                                ),
                              ),
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
                            if (!globalMode)
                              Semantics(
                                button: true,
                                label: 'More actions for ${step.title}',
                                excludeSemantics: true,
                                onTap: () => showMoreActionsSheet(
                                  context,
                                  itemTitle: step.title,
                                  onEdit: () => _editStep(step),
                                  onDelete: () => _deleteStep(step),
                                ),
                                child: IconButton(
                                  onPressed: () => showMoreActionsSheet(
                                    context,
                                    itemTitle: step.title,
                                    onEdit: () => _editStep(step),
                                    onDelete: () => _deleteStep(step),
                                  ),
                                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
EOF
echo "Rewrote lib/version_a/screens/steps_list_screen.dart"

echo ""
echo "Done. Run: flutter run"
