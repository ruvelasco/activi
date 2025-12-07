import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import 'activity_result.dart';

GeneratedActivity generateSeriesActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  int modelLength = 4,
  int blanksToFill = 3,
}) {
  final items = images.where((element) {
    return element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.localImage ||
        element.type == CanvasElementType.pictogramCard;
  }).toList();

  if (items.length < 2) return GeneratedActivity(elements: []);

  final first = items[0];
  final second = items[1];

  final result = <CanvasImage>[];

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  const margin = 40.0;
  const cellSize = 110.0;
  const gap = 16.0;

  result.add(
    CanvasImage.text(
      id: 'series_title',
      text: 'Continúa la serie',
      position: const Offset(margin, margin),
      fontSize: 26,
      textColor: Colors.black,
      fontFamily: 'Roboto',
      scale: 1.0,
    ),
  );

  final startY = margin + 50;
  const startX = margin;
  for (int i = 0; i < modelLength; i++) {
    final isFirst = i % 2 == 0;
    final xPos = startX + i * (cellSize + gap);
    final baseId = 'model_$i';
    final source = isFirst ? first : second;

    if (source.type == CanvasElementType.pictogramCard ||
        source.type == CanvasElementType.networkImage) {
      result.add(
        CanvasImage.networkImage(
          id: baseId,
          imageUrl: source.imageUrl ?? '',
          position: Offset(xPos, startY),
          scale: 0.8,
        ).copyWith(width: cellSize, height: cellSize),
      );
    } else {
      result.add(
        CanvasImage.localImage(
          id: baseId,
          imagePath: source.imagePath ?? '',
          position: Offset(xPos, startY),
          scale: 0.8,
        ).copyWith(width: cellSize, height: cellSize),
      );
    }
  }

  final blanksStartY = startY + cellSize + 40;
  final totalSlots = blanksToFill + 2;
  for (int i = 0; i < totalSlots; i++) {
    final isFirst = i % 2 == 0;
    final xPos = startX + i * (cellSize + gap);
    final baseId = 'exercise_$i';

    if (i < 2) {
      final source = isFirst ? first : second;
      if (source.type == CanvasElementType.pictogramCard ||
          source.type == CanvasElementType.networkImage) {
        result.add(
          CanvasImage.networkImage(
            id: baseId,
            imageUrl: source.imageUrl ?? '',
            position: Offset(xPos, blanksStartY),
            scale: 0.8,
          ).copyWith(width: cellSize, height: cellSize),
        );
      } else {
        result.add(
          CanvasImage.localImage(
            id: baseId,
            imagePath: source.imagePath ?? '',
            position: Offset(xPos, blanksStartY),
            scale: 0.8,
          ).copyWith(width: cellSize, height: cellSize),
        );
      }
    } else {
      result.add(
        CanvasImage.shape(
          id: 'blank_$i',
          shapeType: ShapeType.rectangle,
          position: Offset(xPos, blanksStartY),
          shapeColor: Colors.grey[400]!,
          strokeWidth: 2.0,
        ).copyWith(width: cellSize, height: cellSize),
      );
    }
  }

  return GeneratedActivity(
    elements: result,
    message: 'Actividad de series generada',
  );
}
