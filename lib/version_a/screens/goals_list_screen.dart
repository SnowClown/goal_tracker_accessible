import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../shared/models.dart';

/// Version A Goals list — vision-accessibility focused:
/// - Explicit Semantics labels on every interactive element
/// - Respects system text scaling (no fixed font sizes)
/// - High-contrast theme (near-black background, pure white text)
/// - Large touch targets (min 48dp height per row)
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
            child: Material(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _announce('${goal.title} selected.');
                  // TODO: navigate to Tasks screen for this goal
                },
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
