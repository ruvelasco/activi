import 'package:flutter/material.dart';

class LabelSelectionDialog extends StatefulWidget {
  const LabelSelectionDialog({super.key});

  @override
  State<LabelSelectionDialog> createState() => _LabelSelectionDialogState();
}

class _LabelSelectionDialogState extends State<LabelSelectionDialog> {
  final List<String> _labels = List.generate(
    34,
    (index) => 'assets/etiquetasCajas/etiqueta_${index + 1}.png',
  );

  String? _selectedLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona una etiqueta para la caja'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.33, // Proporción 2000x600 = 10:3
          ),
          itemCount: _labels.length,
          itemBuilder: (context, index) {
            final label = _labels[index];
            final isSelected = _selectedLabel == label;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLabel = label;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(label, fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedLabel != null
              ? () => Navigator.of(context).pop(_selectedLabel)
              : null,
          child: const Text('Seleccionar'),
        ),
      ],
    );
  }
}
