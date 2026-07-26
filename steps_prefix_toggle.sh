#!/bin/bash
# Replaces the checkbox UI on the Steps screen with a text prefix
# ("Completed: " / "Uncompleted: ") in front of each step's title.
# Double-tap still toggles the state, same as before — just the
# visual/announced representation changes.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

TARGET="lib/version_a/screens/steps_list_screen.dart"

if [ ! -f "$TARGET" ]; then
  echo "Error: $TARGET not found."
  exit 1
fi

cat > "$TARGET" << 'EOF'
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/semantics.dart';
import '../../shared/models.dart';

/// Version A Steps list — the bottom of the Goals > Tasks > Steps
/// hierarchy. Each step's completion state is shown as a text prefix
/// ("Completed: " / "Uncompleted: ") rather than a checkbox, toggled
/// by double-tapping the row.
/// Same accessibility approach as Goals/Tasks screens:
/// - Single Semantics label per row (includes completed/uncompleted state)
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
      '${step.title}, ${updated.completed ? "completed" : "uncompleted"}.',
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
                final prefix = step.completed ? 'Completed: ' : 'Uncompleted: ';

                return Semantics(
                  button: true,
                  checked: step.completed,
                  label: '$prefix${step.title}.',
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
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: prefix,
                                  style: TextStyle(
                                    color: step.completed
                                        ? Colors.greenAccent
                                        : Colors.grey[400],
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: step.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

echo "Updated $TARGET (checkbox replaced with toggleable text prefix)"
echo ""
echo "Done. Run: flutter run -d R5CY34G515E"
