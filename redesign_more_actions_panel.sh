#!/bin/bash
# Replaces the More-actions bottom sheet with a full-screen overlay:
# - The selected item's title is shown highlighted in REVERSED colours
#   (white background, black text) instead of the app's normal
#   dark-background/light-text scheme.
# - A vertical strip of ICON-ONLY buttons (no text labels) runs down
#   the right edge of the screen, using the same reversed scheme
#   (white background, black icons) by default.
# - Each icon has a "hover" state (on touch-press or accessibility
#   focus) that flips it to the opposite of the reversed scheme
#   (black background, white icon) as a clear active/focus indicator —
#   using the same two-colour high-contrast palette, not a new colour.
#
# The public function name/signature (showMoreActionsSheet) is
# UNCHANGED, so the three screens that already call it need no edits.
#
# Run this from inside the project root (~/goal_tracker_accessible).

set -e

if [ ! -f "pubspec.yaml" ]; then
  echo "Error: run this from inside the goal_tracker_accessible project root (pubspec.yaml not found here)."
  exit 1
fi

TARGET="lib/version_a/widgets/more_actions_sheet.dart"

if [ ! -f "$TARGET" ]; then
  echo "Error: $TARGET not found. Run add_more_actions_sheet.sh first."
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

/// Shows the More-actions panel for a Goal, Task, or Step:
/// - The item's title is highlighted in REVERSED colours (white
///   background, black text) instead of the app's normal dark scheme.
/// - Icon-only buttons (Sort, Move, Flag, Start Time, Deadline,
///   Repeat, Notes, Archive, Duplicate, Edit, Delete) run down a
///   strip on the right edge, in the same reversed colour scheme.
/// - Each icon flips to the opposite colours (black background,
///   white icon) while pressed or accessibility-focused, as a hover
///   indicator using the same two-colour high-contrast palette.
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

      return _MoreActionsPanel(itemTitle: itemTitle, actions: actions);
    },
  );
}

class _MoreActionsPanel extends StatefulWidget {
  final String itemTitle;
  final List<_MoreAction> actions;

  const _MoreActionsPanel({required this.itemTitle, required this.actions});

  @override
  State<_MoreActionsPanel> createState() => _MoreActionsPanelState();
}

class _MoreActionsPanelState extends State<_MoreActionsPanel> {
  static const double _stripWidth = 64;

  int? _activeIndex;

  void _setActive(int? index) {
    if (_activeIndex != index) {
      setState(() => _activeIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tap anywhere outside the strip/title to dismiss.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Selected item, highlighted in REVERSED colours
          // (white background, black text) vs. the app's normal
          // dark-background/light-text scheme.
          Positioned(
            top: 60,
            left: 16,
            right: _stripWidth + 16,
            child: Semantics(
              header: true,
              label: 'Selected: ${widget.itemTitle}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.itemTitle,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          // Icon-only strip down the right edge, reversed colour
          // scheme (white background, black icons); each icon flips
          // to black background / white icon while pressed or
          // accessibility-focused, as a hover indicator.
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: Container(
              width: _stripWidth,
              color: Colors.white,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: widget.actions.length,
                itemBuilder: (context, index) {
                  final action = widget.actions[index];
                  final isActive = _activeIndex == index;

                  return Semantics(
                    button: true,
                    label: action.label,
                    excludeSemantics: true,
                    onTap: action.onTap,
                    child: Focus(
                      onFocusChange: (hasFocus) => _setActive(hasFocus ? index : null),
                      child: GestureDetector(
                        onTapDown: (_) => _setActive(index),
                        onTapCancel: () => _setActive(null),
                        onTap: () {
                          _setActive(null);
                          action.onTap();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          height: _stripWidth,
                          width: _stripWidth,
                          alignment: Alignment.center,
                          color: isActive ? Colors.black : Colors.white,
                          child: Icon(
                            action.icon,
                            color: isActive ? Colors.white : Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
EOF

echo "Rewrote $TARGET (icon-only strip, reversed colours, hover/focus highlight)"
echo ""
echo "Done. Run: flutter run"
