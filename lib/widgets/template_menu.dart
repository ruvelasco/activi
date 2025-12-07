import 'package:flutter/material.dart';

import '../models/canvas_image.dart';

class TemplateMenuPanel extends StatelessWidget {
  final TemplateType currentTemplate;
  final ValueChanged<TemplateType> onSelected;

  const TemplateMenuPanel({
    super.key,
    required this.currentTemplate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
            children: [
              _buildTemplateButton(
                label: 'Blanco',
                template: TemplateType.blank,
                icon: Icons.article_outlined,
              ),
              _buildTemplateButton(
                label: 'Rayado',
                template: TemplateType.lined,
                icon: Icons.view_headline,
              ),
              _buildTemplateButton(
                label: 'Cuadrícula',
                template: TemplateType.grid,
                icon: Icons.grid_4x4,
              ),
              _buildTemplateButton(
                label: 'Cómic 4',
                template: TemplateType.comic4,
                icon: Icons.grid_on,
              ),
              _buildTemplateButton(
                label: 'Cómic 6',
                template: TemplateType.comic6,
                icon: Icons.view_module,
              ),
              _buildTemplateButton(
                label: '2 Columnas',
                template: TemplateType.twoColumns,
                icon: Icons.view_column,
              ),
              _buildTemplateButton(
                label: '3 Columnas',
                template: TemplateType.threeColumns,
                icon: Icons.view_week,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateButton({
    required String label,
    required TemplateType template,
    required IconData icon,
  }) {
    final isSelected = currentTemplate == template;
    return ElevatedButton(
      onPressed: () => onSelected(template),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: isSelected ? Colors.blue[100] : null,
        side: isSelected
            ? BorderSide(color: Colors.blue[700]!, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
          if (isSelected)
            const Icon(Icons.check_circle, color: Colors.blue, size: 20),
        ],
      ),
    );
  }
}
