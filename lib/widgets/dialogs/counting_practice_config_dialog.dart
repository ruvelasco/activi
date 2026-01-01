import 'package:flutter/material.dart';

class CountingPracticeConfig {
  final int boxesPerPage;
  final int minCount;
  final int maxCount;

  CountingPracticeConfig({
    required this.boxesPerPage,
    required this.minCount,
    required this.maxCount,
  });
}

class CountingPracticeConfigDialog extends StatefulWidget {
  const CountingPracticeConfigDialog({super.key});

  @override
  State<CountingPracticeConfigDialog> createState() =>
      CountingPracticeConfigDialogState();
}

class CountingPracticeConfigDialogState
    extends State<CountingPracticeConfigDialog> {
  int selectedBoxes = 6;
  RangeValues selectedRange = const RangeValues(1, 20);

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
                      color: Colors.cyan.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calculate, color: Colors.cyan.shade700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Práctica de Conteo',
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
                          Icon(Icons.grid_on, size: 20, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Cajas por página',
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
                        children: [2, 4, 6, 8]
                            .map(
                              (n) => ChoiceChip(
                                label: Text('$n'),
                                selected: selectedBoxes == n,
                                selectedColor: Colors.cyan.shade100,
                                onSelected: (_) => setState(() => selectedBoxes = n),
                              ),
                            )
                            .toList(),
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
                            'Rango de cantidades',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: selectedRange,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        activeColor: Colors.cyan.shade700,
                        labels: RangeLabels(
                          selectedRange.start.round().toString(),
                          selectedRange.end.round().toString(),
                        ),
                        onChanged: (values) {
                          if (values.end - values.start >= 1) {
                            setState(() => selectedRange = values);
                          }
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mín: ${selectedRange.start.round()}'),
                          Text('Máx: ${selectedRange.end.round()}'),
                        ],
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
                    onPressed: () => Navigator.of(context).pop(
                      CountingPracticeConfig(
                        boxesPerPage: selectedBoxes,
                        minCount: selectedRange.start.round(),
                        maxCount: selectedRange.end.round(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.shade700,
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
