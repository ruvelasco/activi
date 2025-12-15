import 'package:flutter/material.dart';

import '../models/canvas_image.dart';

class SeriesActivityResult {
  final List<List<CanvasImage>> pages;
  final String message;

  SeriesActivityResult({required this.pages, required this.message});
}

SeriesActivityResult generateSeriesActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  int modelLength = 4,
  int blanksToFill = 5,
  int seriesPerPage = 0, // 0 = auto calcular
}) {
  final items = images.where((element) {
    return element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.localImage ||
        element.type == CanvasElementType.pictogramCard;
  }).toList();

  if (items.length < 2) {
    return SeriesActivityResult(pages: [[]], message: 'Añade al menos dos imágenes primero');
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  const margin = 30.0;
  const cellSize = 55.0;
  const gap = 10.0;
  const titleHeight = 26.0;
  const betweenRows = 10.0;

  final slotsPerSeries = blanksToFill + 2;
  final blockHeight = cellSize * 2 + betweenRows + 26;

  final autoSeriesPerPage =
      ((canvasHeight - margin - titleHeight) / blockHeight).floor().clamp(1, 6);
  final effectiveSeriesPerPage = seriesPerPage > 0 ? seriesPerPage : autoSeriesPerPage;

  final totalSeriesFromImages = (items.length / 2).ceil();
  final seriesTotal =
      totalSeriesFromImages >= effectiveSeriesPerPage ? totalSeriesFromImages : effectiveSeriesPerPage;
  final neededPages = (seriesTotal / effectiveSeriesPerPage).ceil().clamp(1, seriesTotal);
  final pages = <List<CanvasImage>>[];
  final Map<String, int> cutoutCounts = {};
  final Map<String, CanvasImage> cutoutSamples = {};
  String keyFor(CanvasImage img) => img.imageUrl ?? img.imagePath ?? img.id;

  for (int pageIndex = 0; pageIndex < neededPages; pageIndex++) {
    final pageElements = <CanvasImage>[];

    pageElements.add(
      CanvasImage.text(
        id: 'series_title_$pageIndex',
        text: 'Continúa la serie',
        position: Offset(margin, margin / 2),
        fontSize: 24,
        textColor: Colors.black,
        fontFamily: 'Roboto',
        isBold: true,
      ).copyWith(width: canvasWidth - margin * 2),
    );

    final seriesStartIndex = pageIndex * effectiveSeriesPerPage;
    final seriesOnThisPage = (seriesStartIndex + effectiveSeriesPerPage) <= seriesTotal
        ? effectiveSeriesPerPage
        : seriesTotal - seriesStartIndex;

    for (int s = 0; s < seriesOnThisPage; s++) {
      final seriesIndex = seriesStartIndex + s;
      final first = items[(seriesIndex * 2) % items.length];
      final second = items[(seriesIndex * 2 + 1) % items.length];
      void addCutouts(CanvasImage img, int count) {
        final key = keyFor(img);
        cutoutCounts[key] = (cutoutCounts[key] ?? 0) + count;
        cutoutSamples[key] = img;
      }

      final baseY = margin + titleHeight + s * blockHeight;

      // Modelo
      for (int i = 0; i < modelLength; i++) {
        final isFirst = i % 2 == 0;
        final xPos = margin + i * (cellSize + gap);
        final source = isFirst ? first : second;
        final id = 'model_${pageIndex}_${s}_$i';

        if (source.type == CanvasElementType.pictogramCard ||
            source.type == CanvasElementType.networkImage) {
          pageElements.add(
            CanvasImage.networkImage(
              id: id,
              imageUrl: source.imageUrl ?? '',
              position: Offset(xPos, baseY),
              scale: 0.8,
            ).copyWith(width: cellSize, height: cellSize),
          );
        } else {
          pageElements.add(
            CanvasImage.localImage(
              id: id,
              imagePath: source.imagePath ?? '',
              position: Offset(xPos, baseY),
              scale: 0.8,
            ).copyWith(width: cellSize, height: cellSize),
          );
        }
      }

      // Ejercicio con huecos
      final blanksStartY = baseY + cellSize + betweenRows;
      final totalSlots = slotsPerSeries;
      for (int i = 0; i < totalSlots; i++) {
        final isFirst = i % 2 == 0;
        final xPos = margin + i * (cellSize + gap);
        final source = isFirst ? first : second;
        final id = 'exercise_${pageIndex}_${s}_$i';

        if (i < 2) {
          if (source.type == CanvasElementType.pictogramCard ||
              source.type == CanvasElementType.networkImage) {
            pageElements.add(
              CanvasImage.networkImage(
                id: id,
                imageUrl: source.imageUrl ?? '',
                position: Offset(xPos, blanksStartY),
                scale: 0.8,
              ).copyWith(width: cellSize, height: cellSize),
            );
          } else {
            pageElements.add(
              CanvasImage.localImage(
                id: id,
                imagePath: source.imagePath ?? '',
                position: Offset(xPos, blanksStartY),
                scale: 0.8,
              ).copyWith(width: cellSize, height: cellSize),
            );
          }
        } else {
          addCutouts(source, 1);
          pageElements.add(
            CanvasImage.shape(
              id: 'blank_${pageIndex}_${s}_$i',
              shapeType: ShapeType.rectangle,
              position: Offset(xPos, blanksStartY),
              shapeColor: Colors.grey[400]!,
              strokeWidth: 2.0,
            ).copyWith(width: cellSize, height: cellSize),
          );
        }
      }
    }

    pages.add(pageElements);
  }

  // Página de recortables
  if (cutoutCounts.isNotEmpty) {
    final cutoutElements = <CanvasImage>[];
    cutoutElements.add(
      CanvasImage.text(
        id: 'cutouts_title',
        text: 'Recorta las piezas',
        position: Offset(margin, margin / 2),
        fontSize: 24,
        textColor: Colors.black,
        fontFamily: 'Roboto',
        isBold: true,
      ).copyWith(width: canvasWidth - margin * 2),
    );

    const cutoutSize = 70.0;
    const cutoutGap = 12.0;

    final cutouts = <CanvasImage>[];
    int copyId = 0;
    cutoutCounts.forEach((key, count) {
      final img = cutoutSamples[key]!;
      for (int c = 0; c < count; c++) {
        final id = 'cutout_${copyId++}';
        if (img.type == CanvasElementType.pictogramCard ||
            img.type == CanvasElementType.networkImage) {
          cutouts.add(
            CanvasImage.networkImage(
              id: id,
              imageUrl: img.imageUrl ?? '',
              position: Offset.zero,
              scale: 1.0,
            ).copyWith(width: cutoutSize, height: cutoutSize),
          );
        } else {
          cutouts.add(
            CanvasImage.localImage(
              id: id,
              imagePath: img.imagePath ?? '',
              position: Offset.zero,
              scale: 1.0,
            ).copyWith(width: cutoutSize, height: cutoutSize),
          );
        }
      }
    });

    // Colocar en grid
    final cols = 5;
    final rows = (cutouts.length / cols).ceil();
    final gridWidth = cols * cutoutSize + (cols - 1) * cutoutGap;
    final startX = (canvasWidth - gridWidth) / 2;
    double y = margin + 30;

    for (int i = 0; i < cutouts.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final xPos = startX + col * (cutoutSize + cutoutGap);
      final yPos = y + row * (cutoutSize + cutoutGap);

      cutoutElements.add(
        CanvasImage.shape(
          id: 'cutout_border_$i',
          shapeType: ShapeType.rectangle,
          position: Offset(xPos - 2, yPos - 2),
          width: cutoutSize + 4,
          height: cutoutSize + 4,
          shapeColor: Colors.grey[600]!,
          strokeWidth: 1.2,
          isDashed: true,
        ),
      );

      cutoutElements.add(
        cutouts[i].copyWith(
          position: Offset(xPos, yPos),
        ),
      );
    }

    pages.add(cutoutElements);
  }

  return SeriesActivityResult(
    pages: pages,
    message: 'Actividad de series generada en ${pages.length} página(s)',
  );
}
