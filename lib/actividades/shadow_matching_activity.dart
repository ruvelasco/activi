import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import 'activity_result.dart';

GeneratedActivity generateShadowMatchingActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
}) {
  final selectable = images
      .where((element) =>
          element.type == CanvasElementType.networkImage ||
          element.type == CanvasElementType.localImage ||
          element.type == CanvasElementType.pictogramCard)
      .toList();

  if (selectable.isEmpty) return GeneratedActivity(elements: []);

  final selectedImages = selectable.take(5).toList();
  final result = <CanvasImage>[];

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  final margin = 40.0;
  final columnWidth = (canvasWidth - 3 * margin) / 2;
  final rowHeight = (canvasHeight - 2 * margin) / 5;
  final imageSize = 120.0;

  final shadowList = List<int>.from(
    List.generate(selectedImages.length, (i) => i),
  )..shuffle();

  for (int i = 0; i < selectedImages.length; i++) {
    final originalImage = selectedImages[i];
    final yPos = margin + rowHeight * i + (rowHeight - imageSize) / 2;
    final xPos = margin + (columnWidth - imageSize) / 2;

    if (originalImage.type == CanvasElementType.pictogramCard) {
      result.add(
        CanvasImage.pictogramCard(
          id: 'left_$i',
          imageUrl: originalImage.imageUrl!,
          text: originalImage.text ?? '',
          position: Offset(xPos, yPos),
          scale: 0.8,
        ),
      );
    } else if (originalImage.type == CanvasElementType.localImage) {
      result.add(
        CanvasImage.localImage(
          id: 'left_$i',
          imagePath: originalImage.imagePath ?? '',
          position: Offset(xPos, yPos),
          scale: 0.8,
        ),
      );
    } else {
      result.add(
        CanvasImage.networkImage(
          id: 'left_$i',
          imageUrl: originalImage.imageUrl ?? '',
          position: Offset(xPos, yPos),
          scale: 0.8,
        ),
      );
    }
  }

  for (int i = 0; i < selectedImages.length; i++) {
    final shadowIndex = shadowList[i];
    final originalImage = selectedImages[shadowIndex];
    final yPos = margin + rowHeight * i + (rowHeight - imageSize) / 2;
    final xPos = canvasWidth / 2 + margin + (columnWidth - imageSize) / 2;

    result.add(
      CanvasImage.shadow(
        id: 'shadow_$i',
        imageUrl: originalImage.imageUrl ?? '',
        position: Offset(xPos, yPos),
        scale: 0.8,
      ),
    );
  }

  return GeneratedActivity(
    elements: result,
    template: TemplateType.shadowMatching,
    message: 'Actividad generada con ${selectedImages.length} elementos',
  );
}
