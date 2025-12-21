import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import '../services/arasaac_service.dart';

class SyllableVocabularyActivityResult {
  final List<List<CanvasImage>> pages;
  final String title;
  final String instructions;
  final String? message;

  SyllableVocabularyActivityResult({
    required this.pages,
    this.title = 'VOCABULARIO POR SÍLABAS',
    required this.instructions,
    this.message,
  });
}

Future<SyllableVocabularyActivityResult> generateSyllableVocabularyActivity({
  required String syllable,
  required ArasaacService arasaacService,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  int maxWords = 9,
  String syllablePosition = 'start',
  bool usePictograms = true,
}) async {
  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  const margin = 40.0;
  const templateHeaderSpace = 140.0;

  final titleText = syllablePosition == 'start'
      ? 'Palabras que empiezan por: ${syllable.toUpperCase()}'
      : 'Palabras que terminan en: ${syllable.toUpperCase()}';

  // Obtener palabras que coincidan con la sílaba desde la API de ARASAAC
  final words = await arasaacService.getWordsBySyllable(
    syllable: syllable,
    position: syllablePosition,
    limit: maxWords * 3, // Obtener más palabras para asegurar que encontremos suficientes con pictogramas
    coreVocabularyOnly: true, // Filtrar solo vocabulario nuclear
  );

  if (words.isEmpty) {
    return SyllableVocabularyActivityResult(
      pages: [],
      instructions: titleText,
      message: 'No se encontraron palabras con la sílaba "$syllable"',
    );
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
    return SyllableVocabularyActivityResult(
      pages: [],
      instructions: titleText,
      message: 'No se encontraron ${usePictograms ? "pictogramas" : "dibujos"} para las palabras',
    );
  }

  // Calcular cuántos elementos caben por página
  const cols = 3;
  const gap = 20.0;
  const cellSize = 140.0;
  final textHeight = usePictograms ? 40.0 : 0.0;

  // Calcular cuántas filas caben en una página
  final availableHeight = canvasHeight - templateHeaderSpace - margin * 2;
  final maxRows = (availableHeight / (cellSize + gap + textHeight)).floor();
  final itemsPerPage = cols * maxRows;

  // Dividir los pictogramas en páginas
  final List<List<CanvasImage>> allPages = [];

  for (int pageIndex = 0; pageIndex * itemsPerPage < pictograms.length; pageIndex++) {
    final pageElements = <CanvasImage>[];

    // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
    // NO los agregamos aquí para evitar duplicación en el PDF

    // Calcular índices para esta página
    final startIdx = pageIndex * itemsPerPage;
    final endIdx = ((pageIndex + 1) * itemsPerPage).clamp(0, pictograms.length);
    final pagePictograms = pictograms.sublist(startIdx, endIdx);
    final pageWords = foundWords.sublist(startIdx, endIdx);

    // Calcular posición inicial de la cuadrícula
    final gridWidth = cols * cellSize + (cols - 1) * gap;
    final gridStartX = (canvasWidth - gridWidth) / 2;
    final gridStartY = templateHeaderSpace + margin;

    // Añadir pictogramas a la página
    for (int i = 0; i < pagePictograms.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final xPos = gridStartX + col * (cellSize + gap);
      final yPos = gridStartY + row * (cellSize + gap + textHeight);

      final pictogram = pagePictograms[i];
      final word = pageWords[i];

      if (usePictograms) {
        pageElements.add(
          CanvasImage.pictogramCard(
            id: 'pictogram_${pageIndex}_$i',
            imageUrl: pictogram.imageUrl,
            text: word,
            position: Offset(xPos, yPos),
            scale: 1.0,
            fontSize: 16,
            textColor: Colors.black,
          ).copyWith(width: cellSize, height: cellSize + textHeight),
        );
      } else {
        pageElements.add(
          CanvasImage.networkImage(
            id: 'drawing_${pageIndex}_$i',
            imageUrl: pictogram.imageUrl,
            position: Offset(xPos, yPos),
            scale: 1.0,
          ).copyWith(width: cellSize, height: cellSize),
        );
      }
    }

    allPages.add(pageElements);
  }

  return SyllableVocabularyActivityResult(
    pages: allPages,
    instructions: titleText,
    message: 'Actividad generada con ${pictograms.length} ${usePictograms ? "pictogramas" : "dibujos"} en ${allPages.length} página${allPages.length > 1 ? "s" : ""}',
  );
}
