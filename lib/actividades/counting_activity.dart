import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import 'activity_result.dart';

GeneratedActivity generateCountingActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
}) {
  final selectable = images
      .where(
        (element) =>
            element.type == CanvasElementType.networkImage ||
            element.type == CanvasElementType.localImage ||
            element.type == CanvasElementType.pictogramCard,
      )
      .toList();

  if (selectable.isEmpty) return GeneratedActivity(elements: []);

  final result = <CanvasImage>[];
  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  // Siempre 6 rectángulos en layout 2x3
  const totalRectangles = 6;
  const cols = 2;
  const rows = 3;
  const margin = 40.0;
  final cellWidth = (canvasWidth - margin * 2) / cols;
  final cellHeight = (canvasHeight - margin * 2) / rows;

  // Distribuir las imágenes entre los 6 rectángulos
  for (int i = 0; i < totalRectangles; i++) {
    final col = i % cols;
    final row = i ~/ cols;

    final cellX = margin + col * cellWidth;
    final cellY = margin + row * cellHeight;

    // Seleccionar imagen de forma cíclica
    final originalImage = selectable[i % selectable.length];

    final random = DateTime.now().millisecondsSinceEpoch + i;
    final count = (random % 10) + 1;

    final boxWidth = cellWidth - 20;
    final boxHeight = cellHeight - 80;

    result.add(
      CanvasImage.shape(
        id: 'box_$i',
        shapeType: ShapeType.rectangle,
        position: Offset(cellX + 10, cellY + 10),
        shapeColor: Colors.grey[400]!,
        strokeWidth: 2.0,
      ).copyWith(width: boxWidth, height: boxHeight),
    );

    final imgCols = count <= 2 ? count : (count <= 6 ? 3 : 4);
    final imgRows = (count / imgCols).ceil();

    const imgSize = 40.0;
    final imgSpacingX = (boxWidth - 20) / imgCols;
    final imgSpacingY = (boxHeight - 20) / imgRows;

    for (int j = 0; j < count; j++) {
      final imgCol = j % imgCols;
      final imgRow = j ~/ imgCols;

      final imgX =
          cellX + 20 + imgCol * imgSpacingX + (imgSpacingX - imgSize) / 2;
      final imgY =
          cellY + 20 + imgRow * imgSpacingY + (imgSpacingY - imgSize) / 2;

      if (originalImage.type == CanvasElementType.pictogramCard ||
          originalImage.type == CanvasElementType.networkImage) {
        result.add(
          CanvasImage.networkImage(
            id: 'img_${i}_$j',
            imageUrl: originalImage.imageUrl!,
            position: Offset(imgX, imgY),
            scale: 1.0,
          ).copyWith(width: imgSize, height: imgSize),
        );
      } else if (originalImage.type == CanvasElementType.localImage) {
        result.add(
          CanvasImage.localImage(
            id: 'img_${i}_$j',
            imagePath: originalImage.imagePath!,
            position: Offset(imgX, imgY),
            scale: 1.0,
          ).copyWith(width: imgSize, height: imgSize),
        );
      }
    }

    final lineY = cellY + boxHeight + 20;
    final lineWidth = boxWidth;

    result.add(
      CanvasImage.shape(
        id: 'line1_$i',
        shapeType: ShapeType.line,
        position: Offset(cellX + 10, lineY),
        shapeColor: Colors.grey,
        strokeWidth: 1.0,
      ).copyWith(width: lineWidth, height: 0),
    );

    result.add(
      CanvasImage.shape(
        id: 'line2_$i',
        shapeType: ShapeType.line,
        position: Offset(cellX + 10, lineY + 15),
        shapeColor: Colors.grey,
        strokeWidth: 1.0,
      ).copyWith(width: lineWidth, height: 0),
    );

    result.add(
      CanvasImage.shape(
        id: 'line3_$i',
        shapeType: ShapeType.line,
        position: Offset(cellX + 10, lineY + 30),
        shapeColor: Colors.grey,
        strokeWidth: 1.0,
      ).copyWith(width: lineWidth, height: 0),
    );
  }

  return GeneratedActivity(
    elements: result,
    template: TemplateType.countingPractice,
    message: 'Actividad de conteo generada con 6 ejercicios',
  );
}
