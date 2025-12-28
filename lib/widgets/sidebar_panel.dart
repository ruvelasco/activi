import 'package:flutter/material.dart';

class SidebarPanel extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onSelectText;
  final VoidCallback onAddPhoto;
  final VoidCallback onSelectShapes;
  final VoidCallback onSelectArasaac;
  final VoidCallback onSelectSoyVisual;
  final VoidCallback onSelectTemplates;
  final VoidCallback onSelectCreator;
  final VoidCallback onSelectConfig;
  final VoidCallback onSelectVisualInstructions;
  final bool isTextSelected;
  final bool isShapesSelected;
  final bool isArasaacSelected;
  final bool isSoyVisualSelected;
  final bool isTemplatesSelected;
  final bool isCreatorSelected;
  final bool isConfigSelected;
  final bool isVisualInstructionsSelected;
  final Widget panel;

  const SidebarPanel({
    super.key,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onSelectText,
    required this.onAddPhoto,
    required this.onSelectShapes,
    required this.onSelectArasaac,
    required this.onSelectSoyVisual,
    required this.onSelectTemplates,
    required this.onSelectCreator,
    required this.onSelectConfig,
    required this.onSelectVisualInstructions,
    required this.isTextSelected,
    required this.isShapesSelected,
    required this.isArasaacSelected,
    required this.isSoyVisualSelected,
    required this.isTemplatesSelected,
    required this.isCreatorSelected,
    required this.isConfigSelected,
    required this.isVisualInstructionsSelected,
    required this.panel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: collapsed ? 48 : 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Stack(
        children: [
          if (!collapsed)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSelectText,
                              icon: const Icon(Icons.text_fields),
                              label: const Text(
                                'Texto',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isTextSelected
                                    ? const Color(0xFF6A1B9A)
                                    : null,
                                foregroundColor: isTextSelected
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onAddPhoto,
                              icon: const Icon(Icons.image),
                              label: const Text(
                                'Foto',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSelectShapes,
                              icon: const Icon(Icons.square_outlined),
                              label: const Text(
                                'Formas',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isShapesSelected
                                    ? const Color(0xFF6A1B9A)
                                    : null,
                                foregroundColor: isShapesSelected
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSelectArasaac,
                              icon: const Icon(Icons.apps),
                              label: const Text(
                                'ARASAAC',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isArasaacSelected
                                    ? const Color(0xFF6A1B9A)
                                    : null,
                                foregroundColor: isArasaacSelected
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSelectSoyVisual,
                              icon: const Icon(Icons.photo_library),
                              label: const Text(
                                'SoyVisual',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSoyVisualSelected
                                    ? const Color(0xFF6A1B9A)
                                    : null,
                                foregroundColor: isSoyVisualSelected
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSelectTemplates,
                              icon: const Icon(Icons.dashboard_outlined),
                              label: const Text(
                                'Plantillas',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isTemplatesSelected
                                    ? const Color(0xFF6A1B9A)
                                    : null,
                                foregroundColor: isTemplatesSelected
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSelectCreator,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text(
                                'Creador',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCreatorSelected
                                    ? const Color(0xFF6A1B9A)
                                    : null,
                                foregroundColor: isCreatorSelected
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSelectVisualInstructions,
                              icon: const Icon(Icons.view_carousel),
                              label: const Text(
                                'Instr.',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isVisualInstructionsSelected
                                    ? const Color(0xFF6A1B9A)
                                    : null,
                                foregroundColor: isVisualInstructionsSelected
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSelectConfig,
                              icon: const Icon(Icons.settings),
                              label: const Text(
                                'Ajustes',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isConfigSelected
                                    ? const Color(0xFF6A1B9A)
                                    : null,
                                foregroundColor: isConfigSelected
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: panel),
              ],
            ),
          Positioned(
            right: 0,
            bottom: 16,
            child: Container(
              margin: const EdgeInsets.only(right: 0),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left),
                tooltip: collapsed ? 'Mostrar panel' : 'Ocultar panel',
                onPressed: onToggleCollapsed,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
