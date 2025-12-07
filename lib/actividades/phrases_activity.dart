import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import '../services/arasaac_service.dart';
import 'activity_result.dart';

Future<GeneratedActivity> generatePhrasesActivity({
  required List<CanvasImage> images,
  required String phrase,
  required ArasaacService arasaacService,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
}) async {
  if (phrase.trim().isEmpty) return GeneratedActivity(elements: []);

  final selectableImage = images.firstWhere(
    (e) =>
        e.type == CanvasElementType.networkImage ||
        e.type == CanvasElementType.localImage ||
        e.type == CanvasElementType.pictogramCard,
    orElse: () => images.isNotEmpty
        ? images.first
        : CanvasImage.text(
            id: 'placeholder',
            text: '',
            position: Offset.zero,
          ),
  );

  // Si no hay ninguna imagen seleccionable
  if (selectableImage.id == 'placeholder') {
    return GeneratedActivity(elements: []);
  }

  final result = <CanvasImage>[];
  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final margin = 40.0;
  final topImageHeight = 280.0;

  // Imagen superior a ancho completo
  if (selectableImage.type == CanvasElementType.networkImage ||
      selectableImage.type == CanvasElementType.pictogramCard) {
    result.add(
      CanvasImage.networkImage(
        id: 'main_image',
        imageUrl: selectableImage.imageUrl ?? '',
        position: Offset(margin, margin),
        scale: 1.0,
      ).copyWith(
        width: canvasWidth - 2 * margin,
        height: topImageHeight,
      ),
    );
  } else {
    result.add(
      CanvasImage.localImage(
        id: 'main_image',
        imagePath: selectableImage.imagePath ?? '',
        position: Offset(margin, margin),
        scale: 1.0,
      ).copyWith(
        width: canvasWidth - 2 * margin,
        height: topImageHeight,
      ),
    );
  }

  // Pictogramas de la frase
  final words =
      phrase.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList();

  final pictograms = <ArasaacImage?>[];
  for (final word in words) {
    final search = await arasaacService.searchPictograms(word);
    pictograms.add(search.isNotEmpty ? search.first : null);
  }

  const cellSize = 110.0;
  const gap = 12.0;
  final availableWidth = canvasWidth - 2 * margin;
  final cellsPerRow = availableWidth ~/ (cellSize + gap) > 0
      ? availableWidth ~/ (cellSize + gap)
      : 1;
  final startY = margin + topImageHeight + 30;

  for (int i = 0; i < pictograms.length; i++) {
    final col = i % cellsPerRow;
    final row = i ~/ cellsPerRow;
    final xPos = margin + col * (cellSize + gap);
    final yPos = startY + row * (cellSize + gap + 24);
    final word = words[i];
    final pictogram = pictograms[i];

    if (pictogram != null) {
      result.add(
        CanvasImage.pictogramCard(
          id: 'phrase_$i',
          imageUrl: pictogram.imageUrl,
          text: word,
          position: Offset(xPos, yPos),
          scale: 1.0,
          fontSize: 16,
          textColor: Colors.black,
        ).copyWith(width: cellSize, height: cellSize + 24),
      );
    } else {
      // Fallback a texto cuando no hay pictograma
      result.add(
        CanvasImage.text(
          id: 'phrase_text_$i',
          text: word,
          position: Offset(xPos + 8, yPos + (cellSize / 2)),
          fontSize: 18,
          textColor: Colors.black,
          fontFamily: 'Roboto',
          scale: 1.0,
        ),
      );
      result.add(
        CanvasImage.shape(
          id: 'phrase_box_$i',
          shapeType: ShapeType.rectangle,
          position: Offset(xPos, yPos),
          shapeColor: Colors.grey[400]!,
          strokeWidth: 2.0,
        ).copyWith(width: cellSize, height: cellSize),
      );
    }
  }

  return GeneratedActivity(
    elements: result,
    message: 'Actividad de frases generada',
  );
}
