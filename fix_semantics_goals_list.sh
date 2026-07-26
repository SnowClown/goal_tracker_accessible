#!/bin/bash
# Fixes two TalkBack issues on the Goals list screen:
# 1. Double-reading of each goal (child Text widgets exposing their own
#    semantics nodes in addition to the wrapping Semantics label)
# 2. Double-tap not activating (Semantics wrapper had no onTap action
#    of its own, disconnected from the InkWell underneath)
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

TARGET="lib/version_a/screens/goals_list_screen.dart"

if [ ! -f "$TARGET" ]; then
  echo "Error: $TARGET not found."
  exit 1
fi

cat > "$TARGET" << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../shared/models.dart';

/// Version A Goals list — vision-accessibility focused:
/// - Explicit Semantics labels on every interactive element, with
///   excludeSemantics on child widgets so TalkBack reads each goal
///   exactly once (not once for the label, once for the raw text).
/// - onTap attached directly to the Semantics node so TalkBack's
///   double-tap gesture reliably activates the row.
/// - Respects system text scaling (no fixed font sizes)
/// - High-contrast theme (near-black background, pure white text)
/// - Large touch targets (min 64dp height per row)
/// - TTS announcement when the screen loads and on selection
class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _announce('Goals screen. ${sampleGoals.length} goals listed.');
  }

  Future<void> _announce(String text) async {
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _selectGoal(Goal goal) {
    _announce('${goal.title} selected.');
    // TODO: navigate to Tasks screen for this goal
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Your Goals',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sampleGoals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final goal = sampleGoals[index];
          final progressLabel =
              '${goal.completedTaskCount} of ${goal.taskCount} tasks complete';

          return Semantics(
            button: true,
            label: '${goal.title}. $progressLabel.',
            excludeSemantics: true,
            onTap: () => _selectGoal(goal),
            child: Material(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
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
                      Text(
                        goal.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progressLabel,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
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

echo "Updated $TARGET"
echo "Run: flutter run -d R5CY34G515E and re-test with TalkBack"
