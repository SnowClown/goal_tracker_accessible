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
