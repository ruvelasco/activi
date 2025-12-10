import 'package:flutter/material.dart';

class ActivityAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool canUndo;
  final bool canRedo;
  final bool isPersisting;
  final bool sidebarCollapsed;
  final bool isLoggedIn;
  final String userLabel;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onToggleSidebar;
  final VoidCallback onSaveProject;
  final VoidCallback onLoadProject;
  final VoidCallback onGeneratePdf;
  final VoidCallback onAuthAction;

  const ActivityAppBar({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.isPersisting,
    required this.sidebarCollapsed,
    required this.isLoggedIn,
    required this.userLabel,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onToggleSidebar,
    required this.onSaveProject,
    required this.onLoadProject,
    required this.onGeneratePdf,
    required this.onAuthAction,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text('Creador de Actividades ARASAAC v2.1'),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: canUndo ? onUndo : null,
          tooltip: 'Deshacer',
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed: canRedo ? onRedo : null,
          tooltip: 'Rehacer',
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: onClear,
          tooltip: 'Limpiar página',
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: isPersisting ? null : onSaveProject,
          tooltip: 'Guardar proyecto',
        ),
        IconButton(
          icon: const Icon(Icons.folder_open),
          onPressed: onLoadProject,
          tooltip: 'Mis proyectos',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          onPressed: onGeneratePdf,
          tooltip: 'Generar PDF',
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: onAuthAction,
          icon: Icon(
            isLoggedIn ? Icons.logout : Icons.person_outline,
            color: Colors.white,
          ),
          label: Text(userLabel, style: const TextStyle(color: Colors.white)),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
