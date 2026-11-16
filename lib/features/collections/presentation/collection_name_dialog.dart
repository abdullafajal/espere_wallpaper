import 'package:flutter/material.dart';

/// Asks for a collection name. Returns the trimmed name, or null if cancelled.
Future<String?> showCollectionNameDialog(
  BuildContext context, {
  String title = 'New collection',
  String confirmLabel = 'Create',
  String initialValue = '',
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      void submit() {
        final name = controller.text.trim();
        if (name.isNotEmpty) Navigator.pop(ctx, name);
      }

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => submit(),
          decoration: const InputDecoration(hintText: 'e.g. Calm mountains'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: submit, child: Text(confirmLabel)),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}
