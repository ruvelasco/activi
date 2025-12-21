import 'package:flutter/material.dart';

/// Configuración de la plantilla de documento para PDFs
class DocumentTemplate {
  final bool enabled;
  final String title;
  final String instructions;
  final Color titleBackgroundColor;
  final Color instructionsBackgroundColor;
  final Color activityBackgroundColor;
  final Color titleTextColor;
  final Color instructionsTextColor;
  final double titleFontSize;
  final double instructionsFontSize;
  final double logoSize;
  final bool showLogo;
  final bool showTitle;
  final bool showInstructions;

  // Dimensiones de las áreas
  final double titleHeight;
  final double instructionsHeight;
  final double margin;

  const DocumentTemplate({
    this.enabled = false,
    this.title = 'TÍTULO',
    this.instructions = 'INSTRUCCIONES',
    this.titleBackgroundColor = const Color(0xFF1D6685),
    this.instructionsBackgroundColor = const Color(0xFF1D6685),
    this.activityBackgroundColor = const Color(0xFF1D6685),
    this.titleTextColor = Colors.white,
    this.instructionsTextColor = Colors.white,
    this.titleFontSize = 24.0,
    this.instructionsFontSize = 18.0,
    this.logoSize = 80.0,
    this.showLogo = true,
    this.showTitle = true,
    this.showInstructions = true,
    this.titleHeight = 60.0,
    this.instructionsHeight = 50.0,
    this.margin = 20.0,
  });

  DocumentTemplate copyWith({
    bool? enabled,
    String? title,
    String? instructions,
    Color? titleBackgroundColor,
    Color? instructionsBackgroundColor,
    Color? activityBackgroundColor,
    Color? titleTextColor,
    Color? instructionsTextColor,
    double? titleFontSize,
    double? instructionsFontSize,
    double? logoSize,
    bool? showLogo,
    bool? showTitle,
    bool? showInstructions,
    double? titleHeight,
    double? instructionsHeight,
    double? margin,
  }) {
    return DocumentTemplate(
      enabled: enabled ?? this.enabled,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      titleBackgroundColor: titleBackgroundColor ?? this.titleBackgroundColor,
      instructionsBackgroundColor: instructionsBackgroundColor ?? this.instructionsBackgroundColor,
      activityBackgroundColor: activityBackgroundColor ?? this.activityBackgroundColor,
      titleTextColor: titleTextColor ?? this.titleTextColor,
      instructionsTextColor: instructionsTextColor ?? this.instructionsTextColor,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      instructionsFontSize: instructionsFontSize ?? this.instructionsFontSize,
      logoSize: logoSize ?? this.logoSize,
      showLogo: showLogo ?? this.showLogo,
      showTitle: showTitle ?? this.showTitle,
      showInstructions: showInstructions ?? this.showInstructions,
      titleHeight: titleHeight ?? this.titleHeight,
      instructionsHeight: instructionsHeight ?? this.instructionsHeight,
      margin: margin ?? this.margin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'title': title,
      'instructions': instructions,
      'titleBackgroundColor': titleBackgroundColor.value,
      'instructionsBackgroundColor': instructionsBackgroundColor.value,
      'activityBackgroundColor': activityBackgroundColor.value,
      'titleTextColor': titleTextColor.value,
      'instructionsTextColor': instructionsTextColor.value,
      'titleFontSize': titleFontSize,
      'instructionsFontSize': instructionsFontSize,
      'logoSize': logoSize,
      'showLogo': showLogo,
      'showTitle': showTitle,
      'showInstructions': showInstructions,
      'titleHeight': titleHeight,
      'instructionsHeight': instructionsHeight,
      'margin': margin,
    };
  }

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) {
    return DocumentTemplate(
      enabled: json['enabled'] as bool? ?? false,
      title: json['title'] as String? ?? 'TÍTULO',
      instructions: json['instructions'] as String? ?? 'INSTRUCCIONES',
      titleBackgroundColor: Color(json['titleBackgroundColor'] as int? ?? 0xFF1D6685),
      instructionsBackgroundColor: Color(json['instructionsBackgroundColor'] as int? ?? 0xFF1D6685),
      activityBackgroundColor: Color(json['activityBackgroundColor'] as int? ?? 0xFF1D6685),
      titleTextColor: Color(json['titleTextColor'] as int? ?? 0xFFFFFFFF),
      instructionsTextColor: Color(json['instructionsTextColor'] as int? ?? 0xFFFFFFFF),
      titleFontSize: (json['titleFontSize'] as num?)?.toDouble() ?? 24.0,
      instructionsFontSize: (json['instructionsFontSize'] as num?)?.toDouble() ?? 18.0,
      logoSize: (json['logoSize'] as num?)?.toDouble() ?? 80.0,
      showLogo: json['showLogo'] as bool? ?? true,
      showTitle: json['showTitle'] as bool? ?? true,
      showInstructions: json['showInstructions'] as bool? ?? true,
      titleHeight: (json['titleHeight'] as num?)?.toDouble() ?? 60.0,
      instructionsHeight: (json['instructionsHeight'] as num?)?.toDouble() ?? 50.0,
      margin: (json['margin'] as num?)?.toDouble() ?? 20.0,
    );
  }
}
