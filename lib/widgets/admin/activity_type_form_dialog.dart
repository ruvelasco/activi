import 'package:flutter/material.dart';
import '../../models/activity_type.dart';

class ActivityTypeFormDialog extends StatefulWidget {
  final ActivityType? activity;

  const ActivityTypeFormDialog({super.key, this.activity});

  @override
  State<ActivityTypeFormDialog> createState() => _ActivityTypeFormDialogState();
}

class _ActivityTypeFormDialogState extends State<ActivityTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _infoTooltipController;
  late TextEditingController _categoryController;
  late String _selectedIcon;
  late Color _selectedColor;
  late bool _isNew;
  late bool _isHighlighted;
  late bool _isEnabled;

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'auto_awesome', 'icon': Icons.auto_awesome},
    {'name': 'link', 'icon': Icons.link},
    {'name': 'extension', 'icon': Icons.extension},
    {'name': 'edit_note', 'icon': Icons.edit_note},
    {'name': 'calculate', 'icon': Icons.calculate},
    {'name': 'hearing', 'icon': Icons.hearing},
    {'name': 'view_column', 'icon': Icons.view_column},
    {'name': 'flip', 'icon': Icons.flip},
    {'name': 'forum_outlined', 'icon': Icons.forum_outlined},
    {'name': 'credit_card', 'icon': Icons.credit_card},
    {'name': 'abc', 'icon': Icons.abc},
    {'name': 'category', 'icon': Icons.category},
    {'name': 'radio_button_checked', 'icon': Icons.radio_button_checked},
    {'name': 'dashboard', 'icon': Icons.dashboard},
    {'name': 'grid_4x4', 'icon': Icons.grid_4x4},
    {'name': 'apps', 'icon': Icons.apps},
    {'name': 'search', 'icon': Icons.search},
  ];

  final List<Color> _availableColors = [
    const Color(0xFF1976D2), // blue[700]
    const Color(0xFFF57C00), // orange[700]
    const Color(0xFF388E3C), // green[700]
    const Color(0xFF7B1FA2), // purple[700]
    const Color(0xFF6A1B9A), // deepPurple[700]
    const Color(0xFFE64A19), // deepOrange[700]
    const Color(0xFFC2185B), // pink[700]
    const Color(0xFF00796B), // teal[700]
    const Color(0xFF455A64), // blueGrey[700]
    const Color(0xFF303F9F), // indigo[700]
    const Color(0xFFFFA000), // amber[700]
    const Color(0xFFD32F2F), // red[700]
    const Color(0xFF0097A7), // cyan[700]
    const Color(0xFF0288D1), // lightBlue[700]
    const Color(0xFF5D4037), // brown[700]
  ];

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;

    _nameController = TextEditingController(text: activity?.name ?? '');
    _titleController = TextEditingController(text: activity?.title ?? '');
    _descriptionController = TextEditingController(text: activity?.description ?? '');
    _infoTooltipController = TextEditingController(text: activity?.infoTooltip ?? '');
    _categoryController = TextEditingController(text: activity?.category ?? '');
    _selectedIcon = activity?.iconName ?? 'auto_awesome';
    _selectedColor = activity?.color ?? const Color(0xFF1976D2);
    _isNew = activity?.isNew ?? false;
    _isHighlighted = activity?.isHighlighted ?? false;
    _isEnabled = activity?.isEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _infoTooltipController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final activity = ActivityType(
        id: widget.activity?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        infoTooltip: _infoTooltipController.text.trim(),
        iconName: _selectedIcon,
        colorValue: _selectedColor.value,
        order: widget.activity?.order ?? 999,
        isNew: _isNew,
        isHighlighted: _isHighlighted,
        isEnabled: _isEnabled,
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        createdAt: widget.activity?.createdAt,
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, activity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.deepPurple,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.activity == null ? 'Nueva Actividad' : 'Editar Actividad',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre interno
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre interno *',
                          helperText: 'Identificador único (ej: shadow_matching)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Título
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Título *',
                          helperText: 'Nombre que se muestra en el menú',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El título es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descripción corta
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción corta *',
                          helperText: 'Descripción breve (1 línea)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La descripción es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tooltip informativo
                      TextFormField(
                        controller: _infoTooltipController,
                        decoration: const InputDecoration(
                          labelText: 'Tooltip informativo',
                          helperText: 'Información detallada al hacer hover',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Categoría
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          helperText: 'pack, individual, etc.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Icono
                      const Text(
                        'Icono *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableIcons.map((iconData) {
                          final isSelected = _selectedIcon == iconData['name'];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIcon = iconData['name'] as String;
                              });
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.deepPurple.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                border: Border.all(
                                  color: isSelected ? Colors.deepPurple : Colors.grey,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                iconData['icon'] as IconData,
                                color: isSelected ? Colors.deepPurple : Colors.grey[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Color
                      const Text(
                        'Color *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableColors.map((color) {
                          final isSelected = _selectedColor == color;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Opciones
                      const Text(
                        'Opciones',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Marcar como nueva'),
                        subtitle: const Text('Muestra badge "NUEVO"'),
                        value: _isNew,
                        onChanged: (value) {
                          setState(() {
                            _isNew = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Destacar'),
                        subtitle: const Text('Muestra con estilo destacado'),
                        value: _isHighlighted,
                        onChanged: (value) {
                          setState(() {
                            _isHighlighted = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Habilitada'),
                        subtitle: const Text('Mostrar en el menú de actividades'),
                        value: _isEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isEnabled = value ?? true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(widget.activity == null ? 'Crear' : 'Guardar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
