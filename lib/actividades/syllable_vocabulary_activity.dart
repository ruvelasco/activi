import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import '../services/arasaac_service.dart';
import 'activity_result.dart';

Future<GeneratedActivity> generateSyllableVocabularyActivity({
  required String syllable,
  required ArasaacService arasaacService,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  int maxWords = 9,
  String syllablePosition = 'start',
  bool usePictograms = true,
}) async {
  final result = <CanvasImage>[];
  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  const margin = 40.0;

  final titleText = syllablePosition == 'start'
      ? 'Palabras que empiezan por: ${syllable.toUpperCase()}'
      : 'Palabras que terminan en: ${syllable.toUpperCase()}';

  result.add(
    CanvasImage.text(
      id: 'syllable_title',
      text: titleText,
      position: const Offset(margin, margin),
      fontSize: 24,
      textColor: Colors.black,
      fontFamily: 'Roboto',
      scale: 1.0,
    ),
  );

  // Obtener palabras que coincidan con la sílaba desde la API de ARASAAC
  final words = await arasaacService.getWordsBySyllable(
    syllable: syllable,
    position: syllablePosition,
    limit: maxWords * 3, // Obtener más palabras para asegurar que encontremos suficientes con pictogramas
  );

  if (words.isEmpty) {
    result.add(
      CanvasImage.text(
        id: 'no_words',
        text: 'No se encontraron palabras con la sílaba "$syllable"',
        position: const Offset(margin, margin + 60),
        fontSize: 16,
        textColor: Colors.orange,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );
    return GeneratedActivity(elements: result);
  }

  // Buscar pictogramas para las palabras encontradas
  final pictograms = <ArasaacImage>[];
  final foundWords = <String>[];

  for (final word in words) {
    if (foundWords.length >= maxWords) break;

    final searchResults = await arasaacService.searchPictograms(word);
    if (searchResults.isNotEmpty) {
      pictograms.add(searchResults.first);
      foundWords.add(word);
    }
  }

  if (pictograms.isEmpty) {
    result.add(
      CanvasImage.text(
        id: 'no_pictograms',
        text: 'No se encontraron ${usePictograms ? "pictogramas" : "dibujos"} para las palabras',
        position: const Offset(margin, margin + 60),
        fontSize: 16,
        textColor: Colors.orange,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );
    return GeneratedActivity(elements: result);
  }

  // Calcular el número de columnas según la cantidad de imágenes
  final cols = maxWords <= 4 ? 2 : (maxWords <= 9 ? 3 : 4);
  const gap = 20.0;
  final textHeight = usePictograms ? 40.0 : 0.0;

  // Ajustar el tamaño de celda según el número de imágenes
  final cellSize = maxWords <= 4 ? 150.0 : (maxWords <= 9 ? 140.0 : 120.0);

  final gridWidth = cols * cellSize + (cols - 1) * gap;
  final gridStartX = (canvasWidth - gridWidth) / 2;
  final gridStartY = margin + 60;

  for (int i = 0; i < pictograms.length; i++) {
    final col = i % cols;
    final row = i ~/ cols;

    final xPos = gridStartX + col * (cellSize + gap);
    final yPos = gridStartY + row * (cellSize + gap + textHeight);

    final pictogram = pictograms[i];
    final word = foundWords[i];

    if (usePictograms) {
      // Pictograma con marco y texto
      result.add(
        CanvasImage.pictogramCard(
          id: 'pictogram_$i',
          imageUrl: pictogram.imageUrl,
          text: word,
          position: Offset(xPos, yPos),
          scale: 1.0,
          fontSize: 18,
          textColor: Colors.black,
        ).copyWith(width: cellSize, height: cellSize + textHeight),
      );
    } else {
      // Dibujo sin marco ni texto
      result.add(
        CanvasImage.networkImage(
          id: 'drawing_$i',
          imageUrl: pictogram.imageUrl,
          position: Offset(xPos, yPos),
          scale: 1.0,
        ).copyWith(width: cellSize, height: cellSize),
      );
    }
  }

  return GeneratedActivity(
    elements: result,
    message:
        'Actividad generada con ${pictograms.length} ${usePictograms ? "pictogramas" : "dibujos"}',
  );
}
