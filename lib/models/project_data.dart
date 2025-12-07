import 'package:flutter/material.dart';

import 'canvas_image.dart';

enum HeaderFooterScope { all, first, last }

class ProjectData {
  final String id;
  final String name;
  final DateTime updatedAt;
  final List<List<CanvasImage>> pages;
  final List<TemplateType> templates;
  final List<Color> backgrounds;
  final List<bool> orientations;
  final String? headerText;
  final String? footerText;
  final HeaderFooterScope headerScope;
  final HeaderFooterScope footerScope;
  final bool showPageNumbers;
  final String? logoPath;
  final Offset logoPosition;
  final double logoSize;

  ProjectData({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.pages,
    required this.templates,
    required this.backgrounds,
    required this.orientations,
    required this.headerText,
    required this.footerText,
    required this.headerScope,
    required this.footerScope,
    required this.showPageNumbers,
    required this.logoPath,
    required this.logoPosition,
    required this.logoSize,
  });

  ProjectData copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
    List<List<CanvasImage>>? pages,
    List<TemplateType>? templates,
    List<Color>? backgrounds,
    List<bool>? orientations,
    String? headerText,
    String? footerText,
    HeaderFooterScope? headerScope,
    HeaderFooterScope? footerScope,
    bool? showPageNumbers,
    String? logoPath,
    Offset? logoPosition,
    double? logoSize,
  }) {
    return ProjectData(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      pages: pages ?? this.pages,
      templates: templates ?? this.templates,
      backgrounds: backgrounds ?? this.backgrounds,
      orientations: orientations ?? this.orientations,
      headerText: headerText ?? this.headerText,
      footerText: footerText ?? this.footerText,
      headerScope: headerScope ?? this.headerScope,
      footerScope: footerScope ?? this.footerScope,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      logoPath: logoPath ?? this.logoPath,
      logoPosition: logoPosition ?? this.logoPosition,
      logoSize: logoSize ?? this.logoSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'updatedAt': updatedAt.toIso8601String(),
      'pages': pages
          .map((page) => page.map((img) => img.toJson()).toList())
          .toList(),
      'templates': templates.map((t) => t.name).toList(),
      'backgrounds': backgrounds.map((c) => c.value).toList(),
      'orientations': orientations,
      'headerText': headerText,
      'footerText': footerText,
      'headerScope': headerScope.name,
      'footerScope': footerScope.name,
      'showPageNumbers': showPageNumbers,
      'logoPath': logoPath,
      'logoPosition': {'dx': logoPosition.dx, 'dy': logoPosition.dy},
      'logoSize': logoSize,
    };
  }

  factory ProjectData.fromJson(Map<String, dynamic> json) {
    return ProjectData(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Proyecto',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      pages: (json['pages'] as List<dynamic>? ?? [])
          .map((page) => (page as List<dynamic>)
              .map((img) => CanvasImage.fromJson(img))
              .toList())
          .toList(),
      templates: (json['templates'] as List<dynamic>? ?? [])
          .map((t) => TemplateType.values.firstWhere(
                (value) => value.name == t,
                orElse: () => TemplateType.blank,
              ))
          .toList(),
      backgrounds: (json['backgrounds'] as List<dynamic>? ?? [])
          .map((c) => Color(c as int))
          .toList(),
      orientations:
          (json['orientations'] as List<dynamic>? ?? []).cast<bool>().toList(),
      headerText: json['headerText'] as String?,
      footerText: json['footerText'] as String?,
      headerScope: HeaderFooterScope.values.firstWhere(
        (e) => e.name == json['headerScope'],
        orElse: () => HeaderFooterScope.all,
      ),
      footerScope: HeaderFooterScope.values.firstWhere(
        (e) => e.name == json['footerScope'],
        orElse: () => HeaderFooterScope.all,
      ),
      showPageNumbers: json['showPageNumbers'] as bool? ?? false,
      logoPath: json['logoPath'] as String?,
      logoPosition: Offset(
        (json['logoPosition']?['dx'] as num?)?.toDouble() ?? 20,
        (json['logoPosition']?['dy'] as num?)?.toDouble() ?? 20,
      ),
      logoSize: (json['logoSize'] as num?)?.toDouble() ?? 50.0,
    );
  }
}
