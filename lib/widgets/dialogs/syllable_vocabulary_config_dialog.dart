import 'package:flutter/material.dart';

class SyllableVocabularyConfig {
  final String syllable;
  final String position;
  final int numWords;
  final bool usePictograms;
  final bool useUppercase;

  SyllableVocabularyConfig({
    required this.syllable,
    required this.position,
    required this.numWords,
    required this.usePictograms,
    required this.useUppercase,
  });
}

class SyllableVocabularyConfigDialog extends StatefulWidget {
  const SyllableVocabularyConfigDialog({super.key});

  @override
  State<SyllableVocabularyConfigDialog> createState() =>
      SyllableVocabularyConfigDialogState();
}

class SyllableVocabularyConfigDialogState
    extends State<SyllableVocabularyConfigDialog> {
  final TextEditingController _syllableController = TextEditingController();
  String _syllablePosition = 'start';
  int _numWords = 9;
  bool _usePictograms = true;
  bool _useUppercase = true;

  @override
  void dispose() {
    _syllableController.dispose();
    super.dispose();
  }

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
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.spellcheck, color: Colors.teal.shade700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vocabulario por Sílaba',
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
                            'Introduce la sílaba (ej: pa, ma, sa, la)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _syllableController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'Sílaba',
                          hintText: 'pa',
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
                          ),
                        ),
                        textCapitalization: TextCapitalization.none,
                        autofocus: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                          Icon(Icons.location_on, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Posición de la sílaba',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<String>(
                        title: const Text('Empieza por'),
                        value: 'start',
                        groupValue: _syllablePosition,
                        activeColor: Colors.teal.shade700,
                        onChanged: (value) {
                          setState(() {
                            _syllablePosition = value!;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        title: const Text('Termina en'),
                        value: 'end',
                        groupValue: _syllablePosition,
                        activeColor: Colors.teal.shade700,
                        onChanged: (value) {
                          setState(() {
                            _syllablePosition = value!;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                          Icon(Icons.format_list_numbered, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Número de palabras',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _numWords.toDouble(),
                              min: 3,
                              max: 30,
                              divisions: 9,
                              activeColor: Colors.teal.shade700,
                              label: _numWords.toString(),
                              onChanged: (value) {
                                setState(() {
                                  _numWords = value.toInt();
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              _numWords.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                          Icon(Icons.image, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Tipo de imagen',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<bool>(
                        title: const Text('Pictogramas'),
                        value: true,
                        groupValue: _usePictograms,
                        activeColor: Colors.teal.shade700,
                        onChanged: (value) {
                          setState(() {
                            _usePictograms = value!;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        title: const Text('Dibujos'),
                        value: false,
                        groupValue: _usePictograms,
                        activeColor: Colors.teal.shade700,
                        onChanged: (value) {
                          setState(() {
                            _usePictograms = value!;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_usePictograms) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.format_size, size: 20, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Formato del texto',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RadioListTile<bool>(
                          title: const Text('Mayúsculas'),
                          value: true,
                          groupValue: _useUppercase,
                          activeColor: Colors.teal.shade700,
                          onChanged: (value) {
                            setState(() {
                              _useUppercase = value!;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<bool>(
                          title: const Text('Minúsculas'),
                          value: false,
                          groupValue: _useUppercase,
                          activeColor: Colors.teal.shade700,
                          onChanged: (value) {
                            setState(() {
                              _useUppercase = value!;
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
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
                    onPressed: () {
                      final text = _syllableController.text.trim().toLowerCase();
                      if (text.isNotEmpty && text.length <= 3) {
                        Navigator.of(context).pop(
                          SyllableVocabularyConfig(
                            syllable: text,
                            position: _syllablePosition,
                            numWords: _numWords,
                            usePictograms: _usePictograms,
                            useUppercase: _useUppercase,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
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
