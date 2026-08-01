#!/bin/bash
# Adds a shared "More actions" bottom sheet (Edit, Delete, Sort, Move,
# Flag, Start Time, Deadline, Repeat, Notes, Archive, Duplicate) and a
# "More" icon button on each Goal/Task/Step row that opens it.
# Edit and Delete are wired to the existing _editX()/_deleteX() methods
# already present in each screen (previously used by the now-removed
# individual buttons). The rest show a "Coming soon" message for now,
# since they're not built yet — easy to wire up for real one at a time
# later without touching this sheet's structure.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

mkdir -p lib/version_a/widgets

# --- 1. Shared "More actions" bottom sheet ---
cat > lib/version_a/widgets/more_actions_sheet.dart << 'EOF'
import 'package:flutter/material.dart';

/// A single action row in the More-actions sheet.
class _MoreAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MoreAction({required this.label, required this.icon, required this.onTap});
}

/// Shows an accessible "More actions" bottom sheet for a Goal, Task,
/// or Step. [onEdit] and [onDelete] are wired to real behavior; the
/// remaining actions are placeholders for now and show a "Coming soon"
/// message when tapped, until each is built out individually.
///
/// - Each action is a full-width, large-touch-target row with its own
///   Semantics label (icon + text) so TalkBack/VoiceOver reads exactly
///   one clear label per action.
/// - The sheet itself gets a Semantics label announcing which item
///   it's for, read automatically as focus lands on it.
Future<void> showMoreActionsSheet(
  BuildContext context, {
  required String itemTitle,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  VoidCallback? onSort,
  VoidCallback? onMove,
  VoidCallback? onFlag,
  VoidCallback? onStartTime,
  VoidCallback? onDeadline,
  VoidCallback? onRepeat,
  VoidCallback? onNotes,
  VoidCallback? onArchive,
  VoidCallback? onDuplicate,
}) {
  void comingSoon(String actionName) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$actionName: coming soon.')),
    );
  }

  final actions = <_MoreAction>[
    _MoreAction(
      label: 'Edit',
      icon: Icons.edit,
      onTap: () {
        Navigator.of(context).pop();
        onEdit();
      },
    ),
    _MoreAction(
      label: 'Delete',
      icon: Icons.delete,
      onTap: () {
        Navigator.of(context).pop();
        onDelete();
      },
    ),
    _MoreAction(label: 'Sort', icon: Icons.sort, onTap: onSort ?? () => comingSoon('Sort')),
    _MoreAction(label: 'Move', icon: Icons.drive_file_move, onTap: onMove ?? () => comingSoon('Move')),
    _MoreAction(label: 'Flag', icon: Icons.flag, onTap: onFlag ?? () => comingSoon('Flag')),
    _MoreAction(label: 'Start Time', icon: Icons.schedule, onTap: onStartTime ?? () => comingSoon('Start Time')),
    _MoreAction(label: 'Deadline', icon: Icons.event, onTap: onDeadline ?? () => comingSoon('Deadline')),
    _MoreAction(label: 'Repeat', icon: Icons.repeat, onTap: onRepeat ?? () => comingSoon('Repeat')),
    _MoreAction(label: 'Notes', icon: Icons.notes, onTap: onNotes ?? () => comingSoon('Notes')),
    _MoreAction(label: 'Archive', icon: Icons.archive, onTap: onArchive ?? () => comingSoon('Archive')),
    _MoreAction(label: 'Duplicate', icon: Icons.copy, onTap: onDuplicate ?? () => comingSoon('Duplicate')),
  ];

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey[900],
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                header: true,
                label: 'More actions for $itemTitle',
                child: Text(
                  itemTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return Semantics(
                    button: true,
                    label: action.label,
                    excludeSemantics: true,
                    onTap: action.onTap,
                    child: InkWell(
                      onTap: action.onTap,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Icon(action.icon, color: Colors.white70, size: 26),
                            const SizedBox(width: 20),
                            Text(
                              action.label,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
EOF

echo "Created lib/version_a/widgets/more_actions_sheet.dart"
echo ""
echo "Step 1 of 2 done. Now run add_more_buttons_to_rows.sh to add the"
echo "'More' icon button to each Goal/Task/Step row."
