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
