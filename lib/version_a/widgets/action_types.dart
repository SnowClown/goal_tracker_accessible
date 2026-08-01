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
