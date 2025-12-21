import 'package:flutter/material.dart';
import 'admin/activity_type_admin_page.dart';

class ActivityAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool canUndo;
  final bool canRedo;
  final bool isPersisting;
  final bool sidebarCollapsed;
  final bool isLoggedIn;
  final String userLabel;
  final String? userEmail;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onToggleSidebar;
  final VoidCallback onNewProject;
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
    this.userEmail,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onToggleSidebar,
    required this.onNewProject,
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
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFF8E24AA),
            ],
          ),
        ),
      ),
      foregroundColor: Colors.white,
      title: const Text('Mis Actividades ARASAAC v2.2.2'),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo, color: Colors.white),
          onPressed: canUndo ? onUndo : null,
          tooltip: 'Deshacer',
        ),
        IconButton(
          icon: const Icon(Icons.redo, color: Colors.white),
          onPressed: canRedo ? onRedo : null,
          tooltip: 'Rehacer',
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: onClear,
          tooltip: 'Limpiar página',
        ),
        if (isLoggedIn) ...[
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: onNewProject,
            tooltip: 'Nuevo proyecto',
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
        ],
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          onPressed: onGeneratePdf,
          tooltip: 'Generar PDF',
        ),
        // Botón de administración solo visible para ruvelasco@gmail.com
        if (userEmail == 'ruvelasco@gmail.com')
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ActivityTypeAdminPage(),
                ),
              );
            },
            tooltip: 'Administrar tipos de actividad',
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
