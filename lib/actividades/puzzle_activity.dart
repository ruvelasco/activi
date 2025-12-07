import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import 'activity_result.dart';

GeneratedActivity generatePuzzleActivity({
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

  final selectedImage = selectable.first;
  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  final result = <CanvasImage>[];
  String? imageUrl;
  if (selectedImage.type == CanvasElementType.pictogramCard ||
      selectedImage.type == CanvasElementType.networkImage) {
    imageUrl = selectedImage.imageUrl;
  }

  if (imageUrl != null) {
    result.add(
      CanvasImage.networkImage(
        id: 'puzzle_image',
        imageUrl: imageUrl,
        position: const Offset(0, 0),
        scale: 1.0,
      ).copyWith(width: canvasWidth, height: canvasHeight),
    );
  } else if (selectedImage.imagePath != null) {
    result.add(
      CanvasImage.localImage(
        id: 'puzzle_image',
        imagePath: selectedImage.imagePath!,
        position: const Offset(0, 0),
        scale: 1.0,
      ).copyWith(width: canvasWidth, height: canvasHeight),
    );
  }

  return GeneratedActivity(
    elements: result,
    template: TemplateType.puzzle,
    message: 'Puzle generado - Listo para imprimir y recortar',
  );
}
