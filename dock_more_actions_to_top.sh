#!/bin/bash
# Repositions the temporary per-item More-actions panel to the TOP of
# the screen (same location as the persistent Global controls panel),
# instead of floating in the vertical center. The highlighted item
# title and the 3x4 grid now sit together as one docked panel right
# below where the app bar is, and the whole thing disappears the
# moment an action is chosen — while the persistent Global controls
# panel (when that mode is on) stays put at that same top position.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

TARGET="lib/version_a/widgets/more_actions_sheet.dart"

if [ ! -f "$TARGET" ]; then
  echo "Error: $TARGET not found."
  exit 1
fi

cat > "$TARGET" << 'EOF'
import 'package:flutter/material.dart';

/// A single action in the More-actions panel.
class _MoreAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MoreAction({required this.label, required this.icon, required this.onTap});
}

/// Shows the More-actions panel for a Goal, Task, or Step, docked to
/// the TOP of the screen — the same position the persistent Global
/// controls panel occupies when that mode is on. Contains:
/// - The selected item's title, highlighted in REVERSED colours
///   (white background, black text).
/// - A temporary 3-row by 4-column grid of icon+label tiles, same
///   tile style as the Global controls action bar.
/// The whole panel disappears the moment any action is chosen.
///
/// [onEdit] and [onDelete] are wired to real behavior; the rest show
/// a "Coming soon" message until built out individually.
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
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'More actions for $itemTitle',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (dialogContext, anim1, anim2) {
      void comingSoon(String actionName) {
        Navigator.of(dialogContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$actionName: coming soon.')),
        );
      }

      final actions = <_MoreAction>[
        _MoreAction(
          label: 'Edit',
          icon: Icons.edit,
          onTap: () {
            Navigator.of(dialogContext).pop();
            onEdit();
          },
        ),
        _MoreAction(
          label: 'Delete',
          icon: Icons.delete,
          onTap: () {
            Navigator.of(dialogContext).pop();
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

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Tap anywhere below the docked panel to dismiss.
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Docked panel at the TOP of the screen — same position
            // the persistent Global controls panel occupies.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  color: Colors.grey[900],
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Selected item, highlighted in REVERSED colours
                      // (white background, black text) vs. the app's
                      // normal dark-background/light-text scheme.
                      Semantics(
                        header: true,
                        label: 'Selected: $itemTitle',
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            itemTitle,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Temporary 3x4 grid of icon+label tiles, same
                      // style as the Global controls action bar.
                      // Closes automatically as soon as any tile is
                      // tapped (each action's onTap pops this dialog
                      // before running its real logic).
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.1,
                        children: actions.map((action) {
                          return Semantics(
                            button: true,
                            label: action.label,
                            excludeSemantics: true,
                            onTap: action.onTap,
                            child: InkWell(
                              onTap: action.onTap,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
EOF

echo "Rewrote $TARGET (panel now docked at top of screen, same position as Global controls panel)"
echo ""
echo "Done. Run: flutter run"
