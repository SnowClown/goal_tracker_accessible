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
            label: 'Add goal',
            excludeSemantics: true,
            onTap: _addGoal,
            child: InkWell(
              onTap: _addGoal,
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
      body: Column(
        children: [
          _buildGlobalActionBar(),
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
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: goalStepProgress(goal),
                                                  minHeight: 6,
                                                  backgroundColor: Colors.grey[800],
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${(goalStepProgress(goal) * 100).round()}%',
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
