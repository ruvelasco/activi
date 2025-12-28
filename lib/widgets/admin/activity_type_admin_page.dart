import 'package:flutter/material.dart';
import '../../models/activity_type.dart';
import '../../services/activity_type_service.dart';
import 'activity_type_form_dialog.dart';

class ActivityTypeAdminPage extends StatefulWidget {
  const ActivityTypeAdminPage({super.key});

  @override
  State<ActivityTypeAdminPage> createState() => _ActivityTypeAdminPageState();
}

class _ActivityTypeAdminPageState extends State<ActivityTypeAdminPage> {
  final ActivityTypeService _service = ActivityTypeService();
  List<ActivityType> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final activities = await _service.getAll();
    setState(() {
      _activities = activities;
      _isLoading = false;
    });
  }

  Future<void> _createActivity() async {
    final newActivity = await showDialog<ActivityType>(
      context: context,
      builder: (context) => const ActivityTypeFormDialog(),
    );

    if (newActivity != null) {
      debugPrint('=== DEBUG ADMIN: Creando actividad: ${newActivity.name}');
      debugPrint('=== DEBUG ADMIN: activityPictogramUrl: ${newActivity.activityPictogramUrl}');
      debugPrint('=== DEBUG ADMIN: materialPictogramUrls: ${newActivity.materialPictogramUrls}');

      final created = await _service.create(newActivity);
      if (created != null) {
        debugPrint('=== DEBUG ADMIN: Actividad creada con éxito');
        debugPrint('=== DEBUG ADMIN: created.activityPictogramUrl: ${created.activityPictogramUrl}');
        debugPrint('=== DEBUG ADMIN: created.materialPictogramUrls: ${created.materialPictogramUrls}');
        _showSnackBar('Actividad creada exitosamente', isError: false);
        _loadActivities();
      } else {
        debugPrint('=== DEBUG ADMIN: Error al crear: ${_service.lastError}');
        _showSnackBar('Error: ${_service.lastError}', isError: true);
      }
    }
  }

  Future<void> _editActivity(ActivityType activity) async {
    final updated = await showDialog<ActivityType>(
      context: context,
      builder: (context) => ActivityTypeFormDialog(activity: activity),
    );

    if (updated != null) {
      debugPrint('=== DEBUG ADMIN: Actualizando actividad: ${updated.name}');
      debugPrint('=== DEBUG ADMIN: activityPictogramUrl: ${updated.activityPictogramUrl}');
      debugPrint('=== DEBUG ADMIN: materialPictogramUrls: ${updated.materialPictogramUrls}');

      final success = await _service.update(updated);
      if (success) {
        debugPrint('=== DEBUG ADMIN: Actividad actualizada con éxito');
        _showSnackBar('Actividad actualizada exitosamente', isError: false);
        _loadActivities();
      } else {
        debugPrint('=== DEBUG ADMIN: Error al actualizar: ${_service.lastError}');
        _showSnackBar('Error: ${_service.lastError}', isError: true);
      }
    }
  }

  Future<void> _deleteActivity(ActivityType activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar "${activity.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _service.delete(activity.id);
      if (success) {
        _showSnackBar('Actividad eliminada', isError: false);
        _loadActivities();
      } else {
        _showSnackBar('Error: ${_service.lastError}', isError: true);
      }
    }
  }

  Future<void> _toggleEnabled(ActivityType activity) async {
    final updated = activity.copyWith(isEnabled: !activity.isEnabled);
    final success = await _service.update(updated);
    if (success) {
      _loadActivities();
    } else {
      _showSnackBar('Error: ${_service.lastError}', isError: true);
    }
  }

  Future<void> _toggleNew(ActivityType activity) async {
    final updated = activity.copyWith(isNew: !activity.isNew);
    final success = await _service.update(updated);
    if (success) {
      _loadActivities();
    } else {
      _showSnackBar('Error: ${_service.lastError}', isError: true);
    }
  }

  Future<void> _reorderActivities(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _activities.removeAt(oldIndex);
      _activities.insert(newIndex, item);

      // Actualizar el orden
      for (var i = 0; i < _activities.length; i++) {
        _activities[i] = _activities[i].copyWith(order: i);
      }
    });

    final success = await _service.updateOrder(_activities);
    if (!success) {
      _showSnackBar('Error al reordenar: ${_service.lastError}', isError: true);
      _loadActivities(); // Recargar si falla
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Actividades'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadActivities,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _activities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No hay actividades'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _createActivity,
                            icon: const Icon(Icons.add),
                            label: const Text('Crear primera actividad'),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      onReorder: _reorderActivities,
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final activity = _activities[index];
                        return Card(
                          key: ValueKey(activity.id),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.drag_handle, color: Colors.grey[400]),
                                const SizedBox(width: 8),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: activity.color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    activity.icon,
                                    color: activity.color,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(activity.title)),
                                if (activity.isNew)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'NUEVO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (activity.isHighlighted)
                                  const SizedBox(width: 8),
                                if (activity.isHighlighted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'DESTACADO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(activity.description),
                                const SizedBox(height: 4),
                                Text(
                                  'Orden: ${activity.order} • ${activity.category ?? "Sin categoría"}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    activity.isNew
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.orange,
                                  ),
                                  tooltip: 'Marcar como nueva',
                                  onPressed: () => _toggleNew(activity),
                                ),
                                Switch(
                                  value: activity.isEnabled,
                                  onChanged: (_) => _toggleEnabled(activity),
                                  activeTrackColor: Colors.green,
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editActivity(activity);
                                    } else if (value == 'delete') {
                                      _deleteActivity(activity);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createActivity,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Actividad'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
    );
  }
}
