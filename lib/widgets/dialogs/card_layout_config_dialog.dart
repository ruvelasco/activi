import 'package:flutter/material.dart';
import '../../actividades/card_activity.dart' as card_activity;

class CardLayoutConfigDialog extends StatefulWidget {
  const CardLayoutConfigDialog({super.key});

  @override
  State<CardLayoutConfigDialog> createState() => CardLayoutConfigDialogState();
}

class CardLayoutConfigDialogState extends State<CardLayoutConfigDialog> {
  card_activity.CardLayout layout = card_activity.CardLayout.imageLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.credit_card, color: Colors.amber.shade700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarjeta Informativa',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Selecciona el diseño',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Card(
                elevation: 0,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.view_quilt, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Diseño de tarjeta',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<card_activity.CardLayout>(
                        title: const Text('Imagen arriba, título y texto debajo'),
                        value: card_activity.CardLayout.imageTop,
                        groupValue: layout,
                        activeColor: Colors.amber.shade700,
                        onChanged: (v) {
                          if (v != null) setState(() => layout = v);
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<card_activity.CardLayout>(
                        title: const Text('Imagen a la izquierda, texto a la derecha'),
                        value: card_activity.CardLayout.imageLeft,
                        groupValue: layout,
                        activeColor: Colors.amber.shade700,
                        onChanged: (v) {
                          if (v != null) setState(() => layout = v);
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<card_activity.CardLayout>(
                        title: const Text('Imagen a la derecha, texto a la izquierda'),
                        value: card_activity.CardLayout.imageRight,
                        groupValue: layout,
                        activeColor: Colors.amber.shade700,
                        onChanged: (v) {
                          if (v != null) setState(() => layout = v);
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<card_activity.CardLayout>(
                        title: const Text('Título y texto arriba, imagen abajo'),
                        value: card_activity.CardLayout.textThenImage,
                        groupValue: layout,
                        activeColor: Colors.amber.shade700,
                        onChanged: (v) {
                          if (v != null) setState(() => layout = v);
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(layout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text('Generar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
