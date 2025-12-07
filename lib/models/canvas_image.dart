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
  final ShapeType? shapeType; // Para shape
  Color shapeColor; // Para shape
  double strokeWidth; // Para shape (grosor de línea)
  Offset position;
  double scale;
  double? width;
  double? height;
  double rotation;
  bool flipHorizontal;
  bool flipVertical;
  String? groupId;

  CanvasImage({
    required this.id,
    required this.type,
    this.imageUrl,
    this.imagePath,
    this.text,
    this.fontSize = 24.0,
    this.textColor = Colors.black,
    this.fontFamily = 'Roboto',
    this.shapeType,
    this.shapeColor = Colors.black,
    this.strokeWidth = 2.0,
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
  }) {
    return CanvasImage(
      id: id,
      type: CanvasElementType.networkImage,
      imageUrl: imageUrl,
      position: position,
      scale: scale,
      width: 150,
      height: null, // Dejar null para respetar aspecto de imagen
    );
  }

  // Constructor para imágenes locales
  factory CanvasImage.localImage({
    required String id,
    required String imagePath,
    required Offset position,
    double scale = 1.0,
  }) {
    return CanvasImage(
      id: id,
      type: CanvasElementType.localImage,
      imagePath: imagePath,
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
    );
  }

  // Constructor para formas
  factory CanvasImage.shape({
    required String id,
    required ShapeType shapeType,
    required Offset position,
    Color shapeColor = Colors.black,
    double strokeWidth = 2.0,
    double scale = 1.0,
  }) {
    return CanvasImage(
      id: id,
      type: CanvasElementType.shape,
      shapeType: shapeType,
      shapeColor: shapeColor,
      strokeWidth: strokeWidth,
      position: position,
      scale: scale,
      width: 100,
      height: 100,
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
    String? text,
    double? fontSize,
    Color? textColor,
    String? fontFamily,
    ShapeType? shapeType,
    Color? shapeColor,
    double? strokeWidth,
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
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      fontFamily: fontFamily ?? this.fontFamily,
      shapeType: shapeType ?? this.shapeType,
      shapeColor: shapeColor ?? this.shapeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
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
      'text': text,
      'fontSize': fontSize,
      'textColor': textColor.value,
      'fontFamily': fontFamily,
      'shapeType': shapeType?.name,
      'shapeColor': shapeColor.value,
      'strokeWidth': strokeWidth,
      'position': {'dx': position.dx, 'dy': position.dy},
      'scale': scale,
      'width': width,
      'height': height,
      'rotation': rotation,
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'groupId': groupId,
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
      shapeType: json['shapeType'] != null
          ? ShapeType.values.firstWhere(
              (e) => e.name == json['shapeType'],
              orElse: () => ShapeType.rectangle,
            )
          : null,
      shapeColor: Color(json['shapeColor'] as int? ?? Colors.black.value),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
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
