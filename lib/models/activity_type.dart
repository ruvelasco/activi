import 'package:flutter/material.dart';

/// Modelo para definir un tipo de actividad
class ActivityType {
  final String id; // ID único
  final String name; // Nombre interno (ej: "shadow_matching")
  final String title; // Título que se muestra (ej: "Relacionar Sombras")
  final String description; // Descripción breve
  final String infoTooltip; // Tooltip detallado
  final String iconName; // Nombre del icono de Material Icons
  final int colorValue; // Valor del color
  final int order; // Orden en el menú (menor = primero)
  final bool isNew; // Destacar como nueva
  final bool isHighlighted; // Destacar especialmente (ej: Pack de Actividades)
  final bool isEnabled; // Activar/desactivar
  final String? category; // Categoría opcional ("pack", "individual", etc.)
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivityType({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.infoTooltip,
    required this.iconName,
    required this.colorValue,
    required this.order,
    this.isNew = false,
    this.isHighlighted = false,
    this.isEnabled = true,
    this.category,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convertir a IconData
  IconData get icon {
    // Mapeo de nombres comunes de iconos
    final iconMap = {
      'auto_awesome': Icons.auto_awesome,
      'link': Icons.link,
      'extension': Icons.extension,
      'edit_note': Icons.edit_note,
      'calculate': Icons.calculate,
      'hearing': Icons.hearing,
      'view_column': Icons.view_column,
      'flip': Icons.flip,
      'forum_outlined': Icons.forum_outlined,
      'credit_card': Icons.credit_card,
      'abc': Icons.abc,
      'category': Icons.category,
      'radio_button_checked': Icons.radio_button_checked,
      'dashboard': Icons.dashboard,
      'grid_4x4': Icons.grid_4x4,
      'apps': Icons.apps,
      'search': Icons.search,
    };
    return iconMap[iconName] ?? Icons.help_outline;
  }

  // Convertir a Color
  Color get color => Color(colorValue);

  ActivityType copyWith({
    String? id,
    String? name,
    String? title,
    String? description,
    String? infoTooltip,
    String? iconName,
    int? colorValue,
    int? order,
    bool? isNew,
    bool? isHighlighted,
    bool? isEnabled,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityType(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      infoTooltip: infoTooltip ?? this.infoTooltip,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      order: order ?? this.order,
      isNew: isNew ?? this.isNew,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isEnabled: isEnabled ?? this.isEnabled,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'description': description,
      'infoTooltip': infoTooltip,
      'iconName': iconName,
      'colorValue': colorValue,
      'order': order,
      'isNew': isNew,
      'isHighlighted': isHighlighted,
      'isEnabled': isEnabled,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ActivityType.fromJson(Map<String, dynamic> json) {
    return ActivityType(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      infoTooltip: json['infoTooltip'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'help_outline',
      colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
      order: json['order'] as int? ?? 999,
      isNew: json['isNew'] as bool? ?? false,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
      category: json['category'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
