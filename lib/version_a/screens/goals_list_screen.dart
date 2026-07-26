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
