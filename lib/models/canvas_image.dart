import 'dart:typed_data';
import 'package:flutter/material.dart';

enum CanvasElementType { networkImage, localImage, text, shape, pictogramCard, shadow }

enum ShapeType { line, circle, rectangle, arrow, triangle }

enum TemplateType {
  blank,          // Sin plantilla
  lined,          // Folio rayado
  grid,           // Cuadrícula
  comic4,         // Cómic 4 viñetas
  comic6,         // Cómic 6 viñetas
  twoColumns,     // Dos columnas
  threeColumns,   // Tres columnas
  shadowMatching, // Relacionar sombras con imágenes
  puzzle,         // Puzle para recortar
  writingPractice, // Práctica de escritura con doble pauta
  countingPractice, // Práctica de conteo
}

class CanvasImage {
  final String id;
  final CanvasElementType type;
  final String? imageUrl; // Para networkImage
  final String? imagePath; // Para localImage
  final String? text; // Para text
  double fontSize; // Para text
  Color textColor; // Para text
  String fontFamily; // Para text
  bool isBold; // Para text
  bool isItalic; // Para text
  bool isUnderline; // Para text
  final ShapeType? shapeType; // Para shape
  Color shapeColor; // Para shape
  double strokeWidth; // Para shape (grosor de línea)
  bool isDashed; // Para shape (línea discontinua)
  Offset position;
  double scale;
  double? width;
  double? height;
  double rotation;
  bool flipHorizontal;
  bool flipVertical;
  String? groupId;
  Uint8List? webBytes; // Para web/locales en web
  Uint8List? cachedImageBytes; // Caché de bytes de imágenes de red para PDF

  CanvasImage({
    required this.id,
    required this.type,
    this.imageUrl,
    this.imagePath,
    this.webBytes,
    this.cachedImageBytes,
    this.text,
    this.fontSize = 24.0,
    this.textColor = Colors.black,
    this.fontFamily = 'Roboto',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.shapeType,
    this.shapeColor = Colors.black,
    this.strokeWidth = 2.0,
    this.isDashed = false,
    required this.position,
    this.scale = 1.0,
    this.width,
    this.height,
    this.rotation = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
    this.groupId,
  });

  // Constructor para imágenes de red (ARASAAC)
  factory CanvasImage.networkImage({
    required String id,
    required String imageUrl,
    required Offset position,
    double scale = 1.0,
    double? width,
    double? height,
  }) {
    return CanvasImage(
      id: id,
      type: CanvasElementType.networkImage,
      imageUrl: imageUrl,
      position: position,
      scale: scale,
      width: width ?? 150,
      height: height, // Dejar null para respetar aspecto de imagen
    );
  }

  // Constructor para imágenes locales
  factory CanvasImage.localImage({
    required String id,
    required String imagePath,
    required Offset position,
    double scale = 1.0,
    Uint8List? webBytes,
  }) {
    return CanvasImage(
      id: id,
      type: CanvasElementType.localImage,
      imagePath: imagePath,
      webBytes: webBytes,
      position: position,
      scale: scale,
      width: 150,
      height: 150,
    );
  }

  // Constructor para texto
  factory CanvasImage.text({
    required String id,
    required String text,
    required Offset position,
    double fontSize = 24.0,
    Color textColor = Colors.black,
    String fontFamily = 'Roboto',
    double scale = 1.0,
    double? width,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
  }) {
    return CanvasImage(
      id: id,
      type: CanvasElementType.text,
      text: text,
      fontSize: fontSize,
      textColor: textColor,
      fontFamily: fontFamily,
      position: position,
      scale: scale,
      width: width ?? 300,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
    );
  }

  // Constructor para formas
  factory CanvasImage.shape({
    required String id,
    required ShapeType shapeType,
    required Offset position,
    Color shapeColor = Colors.black,
    double strokeWidth = 2.0,
    bool isDashed = false,
    double scale = 1.0,
    double? width,
    double? height,
  }) {
    return CanvasImage(
      id: id,
      type: CanvasElementType.shape,
      shapeType: shapeType,
      shapeColor: shapeColor,
      strokeWidth: strokeWidth,
      isDashed: isDashed,
      position: position,
      scale: scale,
      width: width ?? 100,
      height: height ?? 100,
    );
  }

  // Constructor para tarjeta de pictograma (imagen + texto)
  factory CanvasImage.pictogramCard({
    required String id,
    required String imageUrl,
    required String text,
    required Offset position,
    double scale = 1.0,
    double fontSize = 18.0,
    Color textColor = Colors.black,
  }) {
    return CanvasImage(
      id: id,
      type: CanvasElementType.pictogramCard,
      imageUrl: imageUrl,
      text: text,
      fontSize: fontSize,
      textColor: textColor,
      position: position,
      scale: scale,
      width: 150,
      height: 190, // 150 para imagen + 40 para texto
    );
  }

  // Constructor para sombra (imagen en negro)
  factory CanvasImage.shadow({
    required String id,
    required String imageUrl,
    required Offset position,
    double scale = 1.0,
  }) {
    return CanvasImage(
      id: id,
      type: CanvasElementType.shadow,
      imageUrl: imageUrl,
      position: position,
      scale: scale,
      width: 150,
      height: 150,
    );
  }

  CanvasImage copyWith({
    String? id,
    CanvasElementType? type,
    String? imageUrl,
    String? imagePath,
    Uint8List? webBytes,
    Uint8List? cachedImageBytes,
    String? text,
    double? fontSize,
    Color? textColor,
    String? fontFamily,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    ShapeType? shapeType,
    Color? shapeColor,
    double? strokeWidth,
    bool? isDashed,
    Offset? position,
    double? scale,
    double? width,
    double? height,
    double? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
    String? groupId,
  }) {
    return CanvasImage(
      id: id ?? this.id,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      webBytes: webBytes ?? this.webBytes,
      cachedImageBytes: cachedImageBytes ?? this.cachedImageBytes,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      shapeType: shapeType ?? this.shapeType,
      shapeColor: shapeColor ?? this.shapeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isDashed: isDashed ?? this.isDashed,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
      groupId: groupId ?? this.groupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      // webBytes se omiten en persistencia para no inflar el JSON
      'text': text,
      'fontSize': fontSize,
      'textColor': textColor.value,
      'fontFamily': fontFamily,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'shapeType': shapeType?.name,
      'shapeColor': shapeColor.value,
      'strokeWidth': strokeWidth,
      'isDashed': isDashed,
      'position': {'dx': position.dx, 'dy': position.dy},
      'scale': scale,
      'width': width,
      'height': height,
      'rotation': rotation,
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'groupId': groupId,
      // webBytes se omiten en persistencia para no inflar el JSON
    };
  }

  factory CanvasImage.fromJson(Map<String, dynamic> json) {
    return CanvasImage(
      id: json['id'] as String,
      type: CanvasElementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CanvasElementType.networkImage,
      ),
      imageUrl: json['imageUrl'] as String?,
      imagePath: json['imagePath'] as String?,
      text: json['text'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
      textColor: Color(json['textColor'] as int? ?? Colors.black.value),
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      shapeType: json['shapeType'] != null
          ? ShapeType.values.firstWhere(
              (e) => e.name == json['shapeType'],
              orElse: () => ShapeType.rectangle,
            )
          : null,
      shapeColor: Color(json['shapeColor'] as int? ?? Colors.black.value),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      isDashed: json['isDashed'] as bool? ?? false,
      position: Offset(
        (json['position']?['dx'] as num?)?.toDouble() ?? 0.0,
        (json['position']?['dy'] as num?)?.toDouble() ?? 0.0,
      ),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      flipHorizontal: json['flipHorizontal'] as bool? ?? false,
      flipVertical: json['flipVertical'] as bool? ?? false,
      groupId: json['groupId'] as String?,
    );
  }
}
