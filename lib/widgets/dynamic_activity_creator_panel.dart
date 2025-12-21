import 'package:flutter/material.dart';
import '../models/activity_type.dart';
import '../services/activity_type_service.dart';

/// Panel de creación de actividades que carga dinámicamente
/// desde el backend y respeta el orden configurado
class DynamicActivityCreatorPanel extends StatefulWidget {
  final Function(String activityName) onActivitySelected;

  const DynamicActivityCreatorPanel({
    super.key,
    required this.onActivitySelected,
  });

  @override
  State<DynamicActivityCreatorPanel> createState() =>
      _DynamicActivityCreatorPanelState();
}

class _DynamicActivityCreatorPanelState
    extends State<DynamicActivityCreatorPanel> {
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

    try {
      // Obtener solo las actividades habilitadas, ordenadas
      final activities = await _service.getEnabled();
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _service.lastError ?? 'Error al cargar actividades';
        _isLoading = false;
        // Usar actividades por defecto como fallback
        _activities = _getDefaultActivities();
      });
    }
  }

  /// Actividades por defecto como fallback si el backend falla
  List<ActivityType> _getDefaultActivities() {
    return [
      ActivityType(
        id: 'pack',
        name: 'activity_pack',
        title: 'Pack de Actividades',
        description: 'Genera múltiples actividades de forma automática',
        infoTooltip:
            'Genera múltiples actividades de forma automática. Selecciona qué tipos de actividades quieres crear y se generarán todas usando las imágenes del canvas.',
        iconName: 'auto_awesome',
        colorValue: 0xFF6A1B9A,
        order: 0,
        isHighlighted: true,
        category: 'pack',
      ),
      ActivityType(
        id: 'shadow_matching',
        name: 'shadow_matching',
        title: 'Relacionar Sombras',
        description: 'Une cada imagen con su sombra',
        infoTooltip:
            'Crea una actividad con imágenes y sombras en 3 columnas con puntos de unión.',
        iconName: 'link',
        colorValue: 0xFF1976D2,
        order: 1,
        category: 'individual',
      ),
      // Agregar más actividades por defecto según sea necesario
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generador de Actividades',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Crea actividades automáticamente',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadActivities,
                  tooltip: 'Recargar actividades',
                ),
              ],
            ),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Usando actividades por defecto',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ..._buildActivityButtons(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityButtons() {
    if (_activities.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No hay actividades disponibles'),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    ActivityType? packActivity;
    final individualActivities = <ActivityType>[];

    // Separar pack de actividades individuales
    for (final activity in _activities) {
      if (activity.category == 'pack') {
        packActivity = activity;
      } else {
        individualActivities.add(activity);
      }
    }

    // Agregar Pack de Actividades primero si existe
    if (packActivity != null) {
      widgets.add(_buildActivityButton(packActivity, isHighlighted: true));
      widgets.add(const SizedBox(height: 12));
      widgets.add(Divider(color: Colors.grey[300], thickness: 1));
      widgets.add(const SizedBox(height: 12));
      widgets.add(
        Text(
          'Actividades Individuales',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    // Agregar actividades individuales ordenadas
    for (final activity in individualActivities) {
      widgets.add(_buildActivityButton(activity));
    }

    return widgets;
  }

  Widget _buildActivityButton(
    ActivityType activity, {
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => widget.onActivitySelected(activity.name),
          style: ElevatedButton.styleFrom(
            backgroundColor: activity.isHighlighted || isHighlighted
                ? activity.color
                : Colors.white,
            foregroundColor: activity.isHighlighted || isHighlighted
                ? Colors.white
                : activity.color,
            elevation: activity.isHighlighted || isHighlighted ? 4 : 1,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: activity.color,
                width: activity.isHighlighted || isHighlighted ? 0 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                activity.icon,
                size: 24,
                color: activity.isHighlighted || isHighlighted
                    ? Colors.white
                    : activity.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: activity.isHighlighted || isHighlighted
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (activity.isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: activity.isHighlighted || isHighlighted
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NUEVA',
                              style: TextStyle(
                                color: activity.isHighlighted || isHighlighted
                                    ? Colors.white
                                    : Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (activity.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        activity.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: activity.isHighlighted || isHighlighted
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (activity.infoTooltip.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: activity.isHighlighted || isHighlighted
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[600],
                  ),
                  onPressed: () => _showActivityInfo(activity),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showActivityInfo(ActivityType activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(activity.icon, color: activity.color),
            const SizedBox(width: 8),
            Expanded(child: Text(activity.title)),
          ],
        ),
        content: Text(activity.infoTooltip),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
