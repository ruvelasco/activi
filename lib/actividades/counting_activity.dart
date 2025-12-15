import 'dart:math';
import 'package:flutter/material.dart';

import '../models/canvas_image.dart';

class CountingActivityResult {
  final List<List<CanvasImage>> pages;
  final TemplateType? template;
  final String? message;

  CountingActivityResult({
    required this.pages,
    this.template,
    this.message,
  });
}

CountingActivityResult generateCountingActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  int boxesPerPage = 6,
  int minCount = 1,
  int maxCount = 20,
}) {
  final selectable = images
      .where(
        (element) =>
            element.type == CanvasElementType.networkImage ||
            element.type == CanvasElementType.localImage ||
            element.type == CanvasElementType.pictogramCard,
      )
      .toList();

  if (selectable.isEmpty) {
    return CountingActivityResult(pages: [[]], template: TemplateType.countingPractice, message: 'Añade al menos una imagen primero');
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  final pages = <List<CanvasImage>>[];
  if (minCount < 1) minCount = 1;
  if (maxCount > 20) maxCount = 20;
  if (maxCount < minCount) maxCount = minCount;

  const margin = 40.0;

  int cols;
  int rows;
  switch (boxesPerPage) {
    case 2:
      cols = 1;
      rows = 2;
      break;
    case 4:
      cols = 2;
      rows = 2;
      break;
    case 8:
      cols = 2;
      rows = 4;
      break;
    case 6:
      cols = 2;
      rows = 3;
      break;
    default:
      cols = 2;
      rows = 3;
      break;
  }

  final totalPages = (selectable.length / boxesPerPage).ceil();

  for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final pageImages = <CanvasImage>[];
    for (int i = 0; i < boxesPerPage; i++) {
      final idx = (pageIndex * boxesPerPage + i) % selectable.length;
      pageImages.add(selectable[idx]);
    }
    final result = <CanvasImage>[];

    final effectiveRows = (pageImages.length / cols).ceil().clamp(1, rows);
    final cellWidth = (canvasWidth - margin * 2) / cols;
    final cellHeight = (canvasHeight - margin * 2) / effectiveRows;

    for (int i = 0; i < pageImages.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final cellX = margin + col * cellWidth;
      final cellY = margin + row * cellHeight;

      final originalImage = pageImages[i];

      final rng = Random(pageIndex * 100 + i + DateTime.now().millisecondsSinceEpoch);
      final count = rng.nextInt(maxCount - minCount + 1) + minCount;

      final boxWidth = cellWidth * 0.76;
      final boxHeight = cellHeight * 0.7;
      final stagger = (row % 2 == 0 ? -6.0 : 6.0);
      final rawBoxX = cellX + (cellWidth - boxWidth) / 2 + stagger;
      final boxX = rawBoxX.clamp(margin, canvasWidth - margin - boxWidth);
      final boxY = cellY + 10;

      result.add(
        CanvasImage.shape(
          id: 'box_${pageIndex}_$i',
          shapeType: ShapeType.rectangle,
          position: Offset(boxX, boxY),
          shapeColor: Colors.grey[400]!,
          strokeWidth: 1.2,
        ).copyWith(width: boxWidth, height: boxHeight),
      );

      final imgCols = count <= 2 ? count : (count <= 4 ? 2 : (count <= 6 ? 3 : 4));
      final imgRows = (count / imgCols).ceil();

      final imgSpacingX = (boxWidth - 20) / imgCols;
      final imgSpacingY = (boxHeight - 20) / imgRows;
      final imgSize = (imgSpacingX < imgSpacingY ? imgSpacingX : imgSpacingY) * 0.8;

      for (int j = 0; j < count; j++) {
        final imgCol = j % imgCols;
        final imgRow = j ~/ imgCols;

        final imgX = boxX + 10 + imgCol * imgSpacingX + (imgSpacingX - imgSize) / 2;
        final imgY = boxY + 10 + imgRow * imgSpacingY + (imgSpacingY - imgSize) / 2;

        if (originalImage.type == CanvasElementType.pictogramCard ||
            originalImage.type == CanvasElementType.networkImage) {
          result.add(
            CanvasImage.networkImage(
              id: 'img_${pageIndex}_${i}_$j',
              imageUrl: originalImage.imageUrl!,
              position: Offset(imgX, imgY),
              scale: 1.0,
            ).copyWith(width: imgSize, height: imgSize),
          );
        } else if (originalImage.type == CanvasElementType.localImage) {
          result.add(
            CanvasImage.localImage(
              id: 'img_${pageIndex}_${i}_$j',
              imagePath: originalImage.imagePath!,
              position: Offset(imgX, imgY),
              scale: 1.0,
            ).copyWith(width: imgSize, height: imgSize),
          );
        }
      }

      // Cuadrado para escribir el número
      const numberBoxSize = 36.0;
      result.add(
        CanvasImage.shape(
          id: 'number_box_${pageIndex}_$i',
          shapeType: ShapeType.rectangle,
          position: Offset(
            cellX + (cellWidth - numberBoxSize) / 2,
            boxY + boxHeight + 14,
          ),
          width: numberBoxSize,
          height: numberBoxSize,
          shapeColor: Colors.grey[700]!,
          strokeWidth: 2.0,
        ),
      );
    }

    pages.add(result);
  }

  return CountingActivityResult(
    pages: pages,
    template: TemplateType.countingPractice,
    message: 'Actividad de conteo generada en $totalPages página(s)',
  );
}
