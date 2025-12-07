import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import 'activity_result.dart';

GeneratedActivity generateCardActivity({
  required List<CanvasImage> images,
  required String title,
  required String body,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
}) {
  if (title.trim().isEmpty || body.trim().isEmpty) {
    return GeneratedActivity(elements: []);
  }

  final selectable = images.where((element) {
    return element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.localImage ||
        element.type == CanvasElementType.pictogramCard;
  }).toList();

  if (selectable.isEmpty) return GeneratedActivity(elements: []);

  final image = selectable.first;
  final result = <CanvasImage>[];

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final margin = 40.0;
  final cardWidth = canvasWidth - margin * 2;
  final cardHeight = 240.0;
  final cardTop = margin;

  // Fondo de tarjeta
  result.add(
    CanvasImage.shape(
      id: 'card_bg',
      shapeType: ShapeType.rectangle,
      position: Offset(margin, cardTop),
      shapeColor: Colors.grey[200]!,
      strokeWidth: 2.0,
    ).copyWith(width: cardWidth, height: cardHeight),
  );

  // Imagen a la izquierda
  const imgSize = 180.0;
  final imgX = margin + 16;
  final imgY = cardTop + (cardHeight - imgSize) / 2;
  if (image.type == CanvasElementType.localImage) {
    result.add(
      CanvasImage.localImage(
        id: 'card_img',
        imagePath: image.imagePath ?? '',
        position: Offset(imgX, imgY),
        scale: 1.0,
      ).copyWith(width: imgSize, height: imgSize),
    );
  } else {
    result.add(
      CanvasImage.networkImage(
        id: 'card_img',
        imageUrl: image.imageUrl ?? '',
        position: Offset(imgX, imgY),
        scale: 1.0,
      ).copyWith(width: imgSize, height: imgSize),
    );
  }

  // Título
  final textStartX = imgX + imgSize + 20;
  final textMaxWidth = cardWidth - (textStartX - margin) - 16;

  result.add(
    CanvasImage.text(
      id: 'card_title',
      text: title,
      position: Offset(textStartX, cardTop + 24),
      fontSize: 28,
      textColor: Colors.black,
      fontFamily: 'Roboto',
      scale: 1.0,
    ),
  );

  // Párrafo (simulado como texto multi-linea)
  result.add(
    CanvasImage.text(
      id: 'card_body',
      text: body,
      position: Offset(textStartX, cardTop + 70),
      fontSize: 16,
      textColor: Colors.black87,
      fontFamily: 'Roboto',
      scale: 1.0,
    ).copyWith(width: textMaxWidth),
  );

  return GeneratedActivity(
    elements: result,
    message: 'Tarjeta generada',
  );
}
