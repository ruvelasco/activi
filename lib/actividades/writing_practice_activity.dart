import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import 'activity_result.dart';

GeneratedActivity generateWritingPracticeActivity({
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

  const cols = 3;
  const margin = 30.0;
  const imageSize = 120.0;
  const writingHeight = 50.0;
  final cellWidth = (canvasWidth - margin * 2) / cols;
  final cellHeight = imageSize + writingHeight + 20;

  for (int i = 0; i < selectable.length; i++) {
    final col = i % cols;
    final row = i ~/ cols;

    final xPos = margin + col * cellWidth + (cellWidth - imageSize) / 2;
    final yPos = margin + row * cellHeight;

    final originalImage = selectable[i];

    if (originalImage.type == CanvasElementType.pictogramCard ||
        originalImage.type == CanvasElementType.networkImage) {
      result.add(
        CanvasImage.networkImage(
          id: 'img_$i',
          imageUrl: originalImage.imageUrl!,
          position: Offset(xPos, yPos),
          scale: 0.8,
        ),
      );
    } else if (originalImage.type == CanvasElementType.localImage) {
      result.add(
        CanvasImage.localImage(
          id: 'img_$i',
          imagePath: originalImage.imagePath!,
          position: Offset(xPos, yPos),
          scale: 0.8,
        ),
      );
    }

    final lineY = yPos + imageSize + 10;
    final lineWidth = imageSize;

    result.add(
      CanvasImage.shape(
        id: 'line1_$i',
        shapeType: ShapeType.line,
        position: Offset(xPos, lineY),
        shapeColor: Colors.grey[500]!,
        strokeWidth: 1.0,
      ).copyWith(width: lineWidth, height: 0),
    );

    result.add(
      CanvasImage.shape(
        id: 'line2_$i',
        shapeType: ShapeType.line,
        position: Offset(xPos, lineY + 15),
        shapeColor: Colors.grey,
        strokeWidth: 1.0,
      ).copyWith(width: lineWidth, height: 0),
    );

    result.add(
      CanvasImage.shape(
        id: 'line3_$i',
        shapeType: ShapeType.line,
        position: Offset(xPos, lineY + 30),
        shapeColor: Colors.grey[500]!,
        strokeWidth: 1.0,
      ).copyWith(width: lineWidth, height: 0),
    );
  }

  return GeneratedActivity(
    elements: result,
    template: TemplateType.writingPractice,
    message:
        'Actividad de escritura generada con ${selectable.length} imágenes',
  );
}
