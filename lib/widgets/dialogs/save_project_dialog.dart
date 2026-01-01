import 'package:flutter/material.dart';

class SaveProjectDialog extends StatefulWidget {
  final String? initialName;

  const SaveProjectDialog({
    super.key,
    this.initialName,
  });

  @override
  State<SaveProjectDialog> createState() => _SaveProjectDialogState();
}

class _SaveProjectDialogState extends State<SaveProjectDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName ??
          'Proyecto ${DateTime.now().toLocal().toString().split(' ').first}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guardar proyecto'),
      content: TextField(
        controller: _nameController,
        decoration: const InputDecoration(labelText: 'Nombre'),
        autofocus: true,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.of(context).pop(value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop(name);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
