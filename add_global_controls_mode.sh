#!/bin/bash
# Adds a second interaction mode ("Global controls") alongside the
# existing per-item "More" button ("Dynamically displayed controls"):
# - Global controls: 2-3 rows of icon+label buttons at the top of each
#   screen; a checkbox appears next to each Goal/Task/Step; pressing a
#   button acts on whichever items are checked. Some actions (Edit,
#   Start Time, Deadline, Repeat, Notes) only work on exactly one
#   selected item at a time.
# - A new "Interface Configuration" screen (gear icon on the Goals
#   screen) lets you toggle between the two modes. The setting is
#   shared app-wide (Tasks/Steps screens read the same toggle).
#
# This does a FULL rewrite of the three screen files (safer than
# patching, given how much changes) plus two new shared files.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

mkdir -p lib/version_a/widgets lib/version_a/screens

# --- 1. Shared interface config (global toggle) ---
cat > lib/shared/interface_config.dart << 'EOF'
import 'package:flutter/foundation.dart';

/// App-wide setting toggling between the two ways of acting on Goals,
/// Tasks, and Steps:
/// - Global controls: action buttons shown at the top of each screen,
///   with checkboxes on each item to select what they act on.
/// - Dynamically displayed controls: the existing per-item "More"
///   button, showing actions for just that one item.
class InterfaceConfig extends ChangeNotifier {
  bool useGlobalControls = false;

  void setUseGlobalControls(bool value) {
    if (useGlobalControls != value) {
      useGlobalControls = value;
      notifyListeners();
    }
  }
}

final InterfaceConfig interfaceConfig = InterfaceConfig();
EOF
echo "Created lib/shared/interface_config.dart"

# --- 2. Shared action definitions ---
cat > lib/version_a/widgets/action_types.dart << 'EOF'
import 'package:flutter/material.dart';

/// Definition of one action available on a Goal, Task, or Step, shared
/// between the per-item More-actions panel and the global controls bar.
class ActionDef {
  final String label;
  final IconData icon;
  /// True for actions that only make sense applied to exactly one
  /// item at a time (e.g. Edit) rather than a multi-selection.
  final bool singleItemOnly;

  const ActionDef({required this.label, required this.icon, this.singleItemOnly = false});
}

const List<ActionDef> allItemActions = [
  ActionDef(label: 'Edit', icon: Icons.edit, singleItemOnly: true),
  ActionDef(label: 'Delete', icon: Icons.delete),
  ActionDef(label: 'Sort', icon: Icons.sort),
  ActionDef(label: 'Move', icon: Icons.drive_file_move),
  ActionDef(label: 'Flag', icon: Icons.flag),
  ActionDef(label: 'Start Time', icon: Icons.schedule, singleItemOnly: true),
  ActionDef(label: 'Deadline', icon: Icons.event, singleItemOnly: true),
  ActionDef(label: 'Repeat', icon: Icons.repeat, singleItemOnly: true),
  ActionDef(label: 'Notes', icon: Icons.notes, singleItemOnly: true),
  ActionDef(label: 'Archive', icon: Icons.archive),
  ActionDef(label: 'Duplicate', icon: Icons.copy),
];
EOF
echo "Created lib/version_a/widgets/action_types.dart"

# --- 3. Interface Configuration screen ---
cat > lib/version_a/screens/interface_configuration_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import '../../shared/interface_config.dart';

/// Lets the user toggle between Global controls and Dynamically
/// displayed controls for acting on Goals, Tasks, and Steps. The
/// setting is app-wide (shared across all three screens).
class InterfaceConfigurationScreen extends StatefulWidget {
  const InterfaceConfigurationScreen({super.key});

  @override
  State<InterfaceConfigurationScreen> createState() => _InterfaceConfigurationScreenState();
}

class _InterfaceConfigurationScreenState extends State<InterfaceConfigurationScreen> {
  @override
  Widget build(BuildContext context) {
    final isGlobal = interfaceConfig.useGlobalControls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Interface Configuration', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Item action controls',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Semantics(
              toggled: isGlobal,
              label: isGlobal
                  ? 'Global controls. On. Double tap to switch to dynamically displayed controls.'
                  : 'Global controls. Off, using dynamically displayed controls. Double tap to switch to global controls.',
              excludeSemantics: true,
              child: SwitchListTile(
                value: isGlobal,
                activeColor: Colors.greenAccent,
                tileColor: Colors.grey[900],
                onChanged: (value) {
                  setState(() => interfaceConfig.setUseGlobalControls(value));
                },
                title: const Text('Global controls', style: TextStyle(color: Colors.white, fontSize: 18)),
                subtitle: Text(
                  isGlobal
                      ? 'Action buttons at the top of each screen; select items with checkboxes.'
                      : 'Dynamically displayed controls: tap More on an item to see its actions.',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF
echo "Created lib/version_a/screens/interface_configuration_screen.dart"

echo ""
echo "Step 1 of 2 done. Now run add_global_controls_screens.sh to rewrite"
echo "the Goals, Tasks, and Steps screens with both interaction modes."
