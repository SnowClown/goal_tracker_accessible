import 'package:flutter/material.dart' hide Step;
import '../../shared/models.dart';
import '../../shared/interface_config.dart';
import '../widgets/accessible_dialogs.dart';
import '../widgets/more_actions_sheet.dart';
import '../widgets/action_types.dart';
import 'steps_list_screen.dart';
import 'interface_configuration_screen.dart';

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
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.1,
        children: [
          Semantics(
            button: true,
            label: 'Add task',
            excludeSemantics: true,
            onTap: _addTask,
            child: InkWell(
              onTap: _addTask,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.greenAccent, size: 22),
                    SizedBox(height: 4),
                    Text(
                      'Add',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (interfaceConfig.useGlobalControls) ...allItemActions.map((action) {
          return Semantics(
            button: true,
            label: action.label,
            excludeSemantics: true,
            onTap: () => _handleGlobalAction(action),
            child: InkWell(
              onTap: () => _handleGlobalAction(action),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
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
        ],
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
      body: Column(
        children: [
          _buildGlobalActionBar(),
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
                                              text: task.title,
                                              style: const TextStyle(
                                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ]),
                                        ),
                                        const SizedBox(height: 6),
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
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
