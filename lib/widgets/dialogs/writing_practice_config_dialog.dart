import 'package:flutter/material.dart';

class WritingPracticeConfig {
  final int itemsPerPage;
  final bool showModel;
  final String fontFamily;
  final bool uppercase;

  WritingPracticeConfig({
    required this.itemsPerPage,
    required this.showModel,
    required this.fontFamily,
    required this.uppercase,
  });
}

class WritingPracticeConfigDialog extends StatefulWidget {
  const WritingPracticeConfigDialog({super.key});

  @override
  WritingPracticeConfigDialogState createState() =>
      WritingPracticeConfigDialogState();
}

class WritingPracticeConfigDialogState
    extends State<WritingPracticeConfigDialog> {
  int selectedItems = 6;
  bool showModel = false;
  String fontFamily = 'ColeCarreira';
  bool uppercase = true;

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
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit, color: Colors.purple.shade700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Práctica de Escritura',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Configura la actividad',
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

              // Dibujos por página
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
                          Icon(Icons.grid_on, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Dibujos/repeticiones por página',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [4, 6, 8, 10, 12]
                            .map(
                              (n) => ChoiceChip(
                                label: Text('$n'),
                                selected: selectedItems == n,
                                selectedColor: Colors.purple.shade100,
                                onSelected: (_) => setState(() => selectedItems = n),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: showModel,
                        onChanged: (v) => setState(() => showModel = v ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.purple,
                        title: const Text('Mostrar modelo de palabra (si la hay)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tipo de letra
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
                          Icon(Icons.font_download, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Tipo de letra',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: fontFamily,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            items: const [
                              DropdownMenuItem(
                                value: 'ColeCarreira',
                                child: Text(
                                  'Cole Carreira',
                                  style: TextStyle(fontFamily: 'ColeCarreira'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'EscolarG',
                                child: Text(
                                  'Escolar G',
                                  style: TextStyle(fontFamily: 'EscolarG'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'EscolarP',
                                child: Text(
                                  'Escolar P',
                                  style: TextStyle(fontFamily: 'EscolarP'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Trace',
                                child: Text(
                                  'Trace',
                                  style: TextStyle(fontFamily: 'Trace'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Massallera',
                                child: Text(
                                  'Massallera',
                                  style: TextStyle(fontFamily: 'Massallera'),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Roboto',
                                child: Text(
                                  'Roboto (Normal)',
                                  style: TextStyle(fontFamily: 'Roboto'),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => fontFamily = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Formato de texto
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
                          Icon(Icons.text_fields, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Formato de texto',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<bool>(
                        title: const Text('MAYÚSCULAS'),
                        value: true,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        groupValue: uppercase,
                        activeColor: Colors.purple,
                        onChanged: (v) {
                          if (v != null) setState(() => uppercase = v);
                        },
                      ),
                      RadioListTile<bool>(
                        title: const Text('minúsculas'),
                        value: false,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        groupValue: uppercase,
                        activeColor: Colors.purple,
                        onChanged: (v) {
                          if (v != null) setState(() => uppercase = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones
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
                    onPressed: () => Navigator.of(context).pop(
                      WritingPracticeConfig(
                        itemsPerPage: selectedItems,
                        showModel: showModel,
                        fontFamily: fontFamily,
                        uppercase: uppercase,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
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
