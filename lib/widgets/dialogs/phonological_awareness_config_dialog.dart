import 'package:flutter/material.dart';

class PhonologicalAwarenessConfig {
  final String fontFamily;
  final bool uppercase;

  PhonologicalAwarenessConfig({
    required this.fontFamily,
    required this.uppercase,
  });
}

class PhonologicalAwarenessConfigDialog extends StatefulWidget {
  const PhonologicalAwarenessConfigDialog({super.key});

  @override
  PhonologicalAwarenessConfigDialogState createState() =>
      PhonologicalAwarenessConfigDialogState();
}

class PhonologicalAwarenessConfigDialogState
    extends State<PhonologicalAwarenessConfigDialog> {
  String _selectedFont = 'ColeCarreira';
  bool _uppercase = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.psychology, color: Colors.blue.shade700, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conciencia Fonológica',
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
                          value: _selectedFont,
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
                              child: Text('Trace', style: TextStyle(fontFamily: 'Trace')),
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
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedFont = value);
                            }
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
                      groupValue: _uppercase,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _uppercase = value);
                        }
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('minúsculas'),
                      value: false,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      groupValue: _uppercase,
                      activeColor: Colors.blue,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _uppercase = value);
                        }
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
                  onPressed: () {
                    Navigator.of(context).pop(
                      PhonologicalAwarenessConfig(
                        fontFamily: _selectedFont,
                        uppercase: _uppercase,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
    );
  }
}
