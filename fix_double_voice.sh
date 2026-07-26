#!/bin/bash
# Fixes the "two voices speaking at once" issue: flutter_tts was running
# as an independent TTS engine, speaking at the same time as TalkBack's
# own voice reading the Semantics labels. Fix: use SemanticsService.announce()
# instead, which routes through TalkBack's own speech queue as a single voice.
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
import 'package:flutter/semantics.dart';
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
/// - Announcements use SemanticsService.announce(), which speaks
///   through TalkBack/VoiceOver's own voice — NOT a separate TTS
///   engine, which previously caused two voices talking over
///   each other.
class GoalsListScreen extends StatefulWidget {
  const GoalsListScreen({super.key});

  @override
  State<GoalsListScreen> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends State<GoalsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SemanticsService.announce(
        'Goals screen. ${sampleGoals.length} goals listed.',
        TextDirection.ltr,
      );
    });
  }

  void _selectGoal(Goal goal) {
    SemanticsService.announce('${goal.title} selected.', TextDirection.ltr);
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

echo "Updated $TARGET (removed flutter_tts usage, switched to SemanticsService.announce)"
echo "Run: flutter run -d R5CY34G515E and re-test with TalkBack"
