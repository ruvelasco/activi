import 'package:flutter/material.dart';

import '../models/canvas_image.dart';

class ShadowMatchingResult {
  final List<List<CanvasImage>> pages;
  final String message;

  ShadowMatchingResult({required this.pages, required this.message});
}

ShadowMatchingResult generateShadowMatchingActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  int pairsPerPage = 6,
}) {
  final selectable = images
      .where((element) =>
          element.type == CanvasElementType.networkImage ||
          element.type == CanvasElementType.localImage ||
          element.type == CanvasElementType.pictogramCard)
      .toList();

  if (selectable.isEmpty) {
    return ShadowMatchingResult(
      pages: [[]],
      message: 'Añade al menos una imagen primero',
    );
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  final margin = 40.0;
  const separationWidth = 24.0; // espacio central reducido
  const dotSize = 12.0;

  final leftColWidth = (canvasWidth - (2 * margin) - separationWidth) / 2;
  final rightColWidth = leftColWidth;

  final totalPages = (selectable.length / pairsPerPage).ceil();
  final pages = <List<CanvasImage>>[];

  for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final start = pageIndex * pairsPerPage;
    final end = (start + pairsPerPage).clamp(0, selectable.length);
    final pageImages = selectable.sublist(start, end);

    final pageElements = <CanvasImage>[];

    final rows = pageImages.length;
    final cellHeight = (canvasHeight - (2 * margin)) / rows;
    final imageSize = (cellHeight * 0.78).clamp(90.0, leftColWidth * 0.95);

    final shuffled = List<CanvasImage>.from(pageImages)..shuffle();

    for (int i = 0; i < pageImages.length; i++) {
      final yTop = margin + i * cellHeight;
      final yImage = yTop + (cellHeight - imageSize) / 2;
      final centerY = yImage + imageSize / 2;

      final leftImageX = margin + (leftColWidth - imageSize) * 0.25;
      final rightImageX = margin + leftColWidth + separationWidth + (rightColWidth - imageSize) * 1.2;

      final leftImage = pageImages[i];
      final rightImage = shuffled[i];

      // Columna izquierda: imagen original
      if (leftImage.type == CanvasElementType.pictogramCard) {
        pageElements.add(
          CanvasImage.pictogramCard(
            id: 'left_${pageIndex}_$i',
            imageUrl: leftImage.imageUrl!,
            text: leftImage.text ?? '',
            position: Offset(leftImageX, yImage),
            scale: 0.8,
          ).copyWith(width: imageSize, height: imageSize),
        );
      } else if (leftImage.type == CanvasElementType.localImage) {
        pageElements.add(
          CanvasImage.localImage(
            id: 'left_${pageIndex}_$i',
            imagePath: leftImage.imagePath ?? '',
            position: Offset(leftImageX, yImage),
            scale: 0.8,
          ).copyWith(width: imageSize, height: imageSize),
        );
      } else {
        pageElements.add(
          CanvasImage.networkImage(
            id: 'left_${pageIndex}_$i',
            imageUrl: leftImage.imageUrl ?? '',
            position: Offset(leftImageX, yImage),
            scale: 0.8,
          ).copyWith(width: imageSize, height: imageSize),
        );
      }

      // Punto a la derecha de la imagen
      final leftDotCenterX = leftImageX + imageSize + 10;
      pageElements.add(
        CanvasImage.shape(
          id: 'left_dot_${pageIndex}_$i',
          shapeType: ShapeType.circle,
          position: Offset(leftDotCenterX - dotSize / 2, centerY - dotSize / 2),
          width: dotSize,
          height: dotSize,
          shapeColor: Colors.grey[700]!,
          strokeWidth: 2.5,
        ),
      );

      // Columna derecha: sombra (o imagen local si no hay URL)
      if (rightImage.type == CanvasElementType.localImage) {
        pageElements.add(
          CanvasImage.localImage(
            id: 'shadow_${pageIndex}_$i',
            imagePath: rightImage.imagePath ?? '',
            position: Offset(rightImageX, yImage),
            scale: 0.8,
          ).copyWith(width: imageSize, height: imageSize),
        );
      } else {
        pageElements.add(
          CanvasImage.shadow(
            id: 'shadow_${pageIndex}_$i',
            imageUrl: rightImage.imageUrl ?? '',
            position: Offset(rightImageX, yImage),
            scale: 0.8,
          ).copyWith(width: imageSize, height: imageSize),
        );
      }

      // Punto a la izquierda de la sombra
      final rightDotCenterX = rightImageX - 10;
      pageElements.add(
        CanvasImage.shape(
          id: 'right_dot_${pageIndex}_$i',
          shapeType: ShapeType.circle,
          position: Offset(rightDotCenterX - dotSize / 2, centerY - dotSize / 2),
          width: dotSize,
          height: dotSize,
          shapeColor: Colors.grey[700]!,
          strokeWidth: 2.5,
        ),
      );
    }

    pages.add(pageElements);
  }

  final message = 'Actividad generada en $totalPages hoja(s) con ${selectable.length} elementos';

  return ShadowMatchingResult(
    pages: pages,
    message: message,
  );
}
