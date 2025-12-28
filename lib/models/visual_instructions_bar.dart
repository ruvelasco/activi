/// Modelo para la barra de instrucciones visuales con pictogramas
class VisualInstructionsBar {
  final String? activityPictogramUrl; // URL del pictograma de la actividad (ej: puzzle, sumar, leer)
  final List<String> materialPictogramUrls; // URLs de pictogramas de materiales (lápiz, goma, tijeras, etc)
  final bool enabled; // Si se muestra o no
  final BarPosition position; // Posición de la barra

  const VisualInstructionsBar({
    this.activityPictogramUrl,
    this.materialPictogramUrls = const [],
    this.enabled = false,
    this.position = BarPosition.top,
  });

  VisualInstructionsBar copyWith({
    String? activityPictogramUrl,
    List<String>? materialPictogramUrls,
    bool? enabled,
    BarPosition? position,
  }) {
    return VisualInstructionsBar(
      activityPictogramUrl: activityPictogramUrl ?? this.activityPictogramUrl,
      materialPictogramUrls: materialPictogramUrls ?? this.materialPictogramUrls,
      enabled: enabled ?? this.enabled,
      position: position ?? this.position,
    );
  }

  bool get hasContent => activityPictogramUrl != null || materialPictogramUrls.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'activityPictogramUrl': activityPictogramUrl,
      'materialPictogramUrls': materialPictogramUrls,
      'enabled': enabled,
      'position': position.name,
    };
  }

  factory VisualInstructionsBar.fromJson(Map<String, dynamic> json) {
    return VisualInstructionsBar(
      activityPictogramUrl: json['activityPictogramUrl'] as String?,
      materialPictogramUrls: (json['materialPictogramUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      enabled: json['enabled'] as bool? ?? false,
      position: BarPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => BarPosition.top,
      ),
    );
  }
}

enum BarPosition {
  top, // Arriba, después del título/instrucciones
  bottom, // Abajo de la página
}
