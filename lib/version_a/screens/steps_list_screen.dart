import 'package:flutter/material.dart' hide Step;
import '../../shared/models.dart';
import '../../shared/interface_config.dart';
import '../widgets/accessible_dialogs.dart';
import '../widgets/more_actions_sheet.dart';
import '../widgets/action_types.dart';
import 'interface_configuration_screen.dart';

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
            label: 'Add step',
            excludeSemantics: true,
            onTap: _addStep,
            child: InkWell(
              onTap: _addStep,
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
