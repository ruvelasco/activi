import 'package:flutter/material.dart';
import '../actividades/activity_pack_generator.dart';

class ActivityPackConfigDialog extends StatefulWidget {
  const ActivityPackConfigDialog({super.key});

  @override
  State<ActivityPackConfigDialog> createState() =>
      _ActivityPackConfigDialogState();
}

class _ActivityPackConfigDialogState extends State<ActivityPackConfigDialog> {
  final TextEditingController _titleController = TextEditingController(
    text: 'Pack de Actividades',
  );
  final Set<ActivityPackType> _selectedActivities = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Generar Pack de Actividades',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Título del Pack',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Vocabulario de Animales',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Selecciona las actividades a generar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Las actividades usarán las imágenes del canvas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...ActivityPackType.values.map((type) {
                      return _buildActivityCheckbox(type);
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedActivities.length} actividad${_selectedActivities.length != 1 ? 'es' : ''} seleccionada${_selectedActivities.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedActivities.isEmpty
                        ? null
                        : () {
                            final config = ActivityPackConfig(
                              title: _titleController.text.trim().isEmpty
                                  ? 'Pack de Actividades'
                                  : _titleController.text.trim(),
                              selectedActivities: _selectedActivities,
                            );
                            Navigator.of(context).pop(config);
                          },
                    icon: const Icon(Icons.check),
                    label: const Text('Generar Pack'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCheckbox(ActivityPackType type) {
    final isSelected = _selectedActivities.contains(type);
    final color = _getActivityColor(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedActivities.remove(type);
            } else {
              _selectedActivities.add(type);
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? color.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedActivities.add(type);
                    } else {
                      _selectedActivities.remove(type);
                    }
                  });
                },
                activeColor: color,
              ),
              const SizedBox(width: 8),
              Icon(
                ActivityPackGenerator.getActivityIcon(type),
                color: isSelected ? color : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ActivityPackGenerator.getActivityName(type),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected ? color : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ActivityPackGenerator.getActivityDescription(type),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActivityColor(ActivityPackType type) {
    switch (type) {
      case ActivityPackType.shadowMatching:
        return Colors.blue[700]!;
      case ActivityPackType.puzzle:
        return Colors.orange[700]!;
      case ActivityPackType.writingPractice:
        return Colors.green[700]!;
      case ActivityPackType.countingPractice:
        return Colors.purple[700]!;
      case ActivityPackType.series:
        return Colors.pink[700]!;
      case ActivityPackType.symmetry:
        return Colors.teal[700]!;
      case ActivityPackType.instructions:
        return Colors.red[700]!;
      case ActivityPackType.card:
        return Colors.deepOrange[700]!;
      case ActivityPackType.classification:
        return Colors.indigo[700]!;
      case ActivityPackType.phonologicalAwareness:
        return Colors.cyan[700]!;
      case ActivityPackType.phonologicalBoard:
        return Colors.blueGrey[700]!;
      case ActivityPackType.phonologicalSquares:
        return Colors.lightBlue[700]!;
      case ActivityPackType.semanticField:
        return Colors.amber[700]!;
      case ActivityPackType.syllableVocabulary:
        return Colors.lime[700]!;
      case ActivityPackType.crossword:
        return Colors.brown[700]!;
      case ActivityPackType.wordSearch:
        return Colors.deepPurple[700]!;
    }
  }
}
