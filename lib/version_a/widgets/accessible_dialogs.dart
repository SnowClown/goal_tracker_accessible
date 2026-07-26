import 'package:flutter/material.dart' hide Step;

/// Shows an accessible text-entry dialog for adding or editing an item
/// title. Returns the entered text, or null if cancelled.
///
/// - Auto-focuses the text field so a screen reader user lands
///   directly on it without extra navigation
/// - Save button is disabled (and labeled as such) when the field
///   is empty, to avoid creating blank items
/// - The dialog's own title/labels are read by the system screen
///   reader automatically as focus lands on them; no manual TTS.
Future<String?> showAccessibleTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  final focusNode = FocusNode();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    focusNode.requestFocus();
  });

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final canSave = controller.text.trim().isNotEmpty;
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 20),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.grey[300]),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop(value.trim());
                }
              },
            ),
            actions: [
              Semantics(
                button: true,
                label: 'Cancel',
                excludeSemantics: true,
                onTap: () => Navigator.of(context).pop(null),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
              ),
              Semantics(
                button: true,
                enabled: canSave,
                label: canSave ? 'Save' : 'Save. Disabled. Enter a title first.',
                excludeSemantics: true,
                onTap: canSave
                    ? () => Navigator.of(context).pop(controller.text.trim())
                    : null,
                child: TextButton(
                  onPressed: canSave
                      ? () => Navigator.of(context).pop(controller.text.trim())
                      : null,
                  child: const Text('Save'),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Shows an accessible delete-confirmation dialog. If [impactMessage]
/// is non-null (e.g. "This will also delete 3 tasks and 5 steps."),
/// it is included in the visible/Semantics text so the screen reader
/// reads the same warning a sighted user sees.
/// Returns true if the user confirmed deletion.
Future<bool> showAccessibleDeleteConfirmation(
  BuildContext context, {
  required String itemTitle,
  String? impactMessage,
}) async {
  final message = impactMessage == null
      ? 'Delete "$itemTitle"? This cannot be undone.'
      : 'Delete "$itemTitle"? $impactMessage This cannot be undone.';

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Confirm delete', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          Semantics(
            button: true,
            label: 'Cancel',
            excludeSemantics: true,
            onTap: () => Navigator.of(context).pop(false),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
          Semantics(
            button: true,
            label: 'Confirm delete',
            excludeSemantics: true,
            onTap: () => Navigator.of(context).pop(true),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
