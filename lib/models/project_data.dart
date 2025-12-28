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
  final List<String> pageTitles; // Título de cada página
  final List<String> pageInstructions; // Instrucciones de cada página
  final String? documentFooter; // Pie de página del documento (autor, licencia, etc)
  final String? headerText; // DEPRECATED: Mantener para compatibilidad
  final String? footerText; // DEPRECATED: Mantener para compatibilidad
  final HeaderFooterScope headerScope;
  final HeaderFooterScope footerScope;
  final bool showPageNumbers;
  final String? logoPath;
  final Offset logoPosition;
  final double logoSize;
  final CanvasImage? coverImage; // Imagen de portada del proyecto

  ProjectData({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.pages,
    required this.templates,
    required this.backgrounds,
    required this.orientations,
    List<String>? pageTitles,
    List<String>? pageInstructions,
    this.documentFooter,
    this.headerText, // DEPRECATED
    this.footerText, // DEPRECATED
    required this.headerScope,
    required this.footerScope,
    required this.showPageNumbers,
    required this.logoPath,
    required this.logoPosition,
    required this.logoSize,
    this.coverImage,
  })  : pageTitles = pageTitles ?? [],
        pageInstructions = pageInstructions ?? [];

  ProjectData copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
    List<List<CanvasImage>>? pages,
    List<TemplateType>? templates,
    List<Color>? backgrounds,
    List<bool>? orientations,
    List<String>? pageTitles,
    List<String>? pageInstructions,
    String? documentFooter,
    String? headerText,
    String? footerText,
    HeaderFooterScope? headerScope,
    HeaderFooterScope? footerScope,
    bool? showPageNumbers,
    String? logoPath,
    Offset? logoPosition,
    double? logoSize,
    CanvasImage? coverImage,
  }) {
    return ProjectData(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      pages: pages ?? this.pages,
      templates: templates ?? this.templates,
      backgrounds: backgrounds ?? this.backgrounds,
      orientations: orientations ?? this.orientations,
      pageTitles: pageTitles ?? this.pageTitles,
      pageInstructions: pageInstructions ?? this.pageInstructions,
      documentFooter: documentFooter ?? this.documentFooter,
      headerText: headerText ?? this.headerText,
      footerText: footerText ?? this.footerText,
      headerScope: headerScope ?? this.headerScope,
      footerScope: footerScope ?? this.footerScope,
      showPageNumbers: showPageNumbers ?? this.showPageNumbers,
      logoPath: logoPath ?? this.logoPath,
      logoPosition: logoPosition ?? this.logoPosition,
      logoSize: logoSize ?? this.logoSize,
      coverImage: coverImage ?? this.coverImage,
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
      'pageTitles': pageTitles,
      'pageInstructions': pageInstructions,
      'documentFooter': documentFooter,
      // Deprecated fields - guardar para compatibilidad
      'headerText': headerText,
      'footerText': footerText,
      'headerScope': headerScope.name,
      'footerScope': footerScope.name,
      'showPageNumbers': showPageNumbers,
      'logoPath': logoPath,
      'logoPosition': {'dx': logoPosition.dx, 'dy': logoPosition.dy},
      'logoSize': logoSize,
      'coverImage': coverImage?.toJson(),
    };
  }

  factory ProjectData.fromJson(Map<String, dynamic> json) {
    // Compatibilidad hacia atrás: si existen pageTitles/pageInstructions usarlos,
    // sino usar headerText/footerText para la primera página
    List<String> pageTitles;
    List<String> pageInstructions;

    if (json['pageTitles'] != null) {
      pageTitles = (json['pageTitles'] as List<dynamic>).cast<String>().toList();
      pageInstructions = (json['pageInstructions'] as List<dynamic>?)?.cast<String>().toList() ?? [];
    } else {
      // Migración desde el formato antiguo
      final headerText = json['headerText'] as String?;
      final footerText = json['footerText'] as String?;
      pageTitles = headerText != null ? [headerText] : [];
      pageInstructions = footerText != null ? [footerText] : [];
    }

    return ProjectData(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Proyecto',
      updatedAt: DateTime.tryParse(
            (json['updatedAt'] ?? json['updated_at']) as String? ?? '',
          ) ??
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
      pageTitles: pageTitles,
      pageInstructions: pageInstructions,
      documentFooter: json['documentFooter'] as String?,
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
      coverImage: json['coverImage'] != null
          ? CanvasImage.fromJson(json['coverImage'] as Map<String, dynamic>)
          : null,
    );
  }
}
