import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/canvas_image.dart';

class CrosswordResult {
  final List<List<CanvasImage>> pages;
  final String message;
  final String title;
  final String instructions;

  CrosswordResult({
    required this.pages,
    required this.message,
    this.title = 'CRUCIGRAMA',
    this.instructions = 'Completa el crucigrama usando las imágenes como pistas',
  });
}

class _WordEntry {
  final String word;
  final CanvasImage image;
  final int number;
  bool isHorizontal;
  int row;
  int col;
  bool wasPlaced;

  _WordEntry({
    required this.word,
    required this.image,
    required this.number,
    this.isHorizontal = true,
    this.row = 0,
    this.col = 0,
    this.wasPlaced = false,
  });
}

/// Genera actividad de crucigrama
/// Usa las imágenes del canvas para obtener palabras y crear un crucigrama
Future<CrosswordResult> generateCrosswordActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  String fontFamily = 'Arial',
}) async {
  final selectable = images
      .where(
        (element) =>
            element.type == CanvasElementType.networkImage ||
            element.type == CanvasElementType.localImage ||
            element.type == CanvasElementType.pictogramCard,
      )
      .toList();

  if (selectable.isEmpty) {
    return CrosswordResult(
      pages: [[]],
      message: 'Añade al menos una imagen primero',
    );
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  // Obtener palabras de las imágenes
  final wordEntries = <_WordEntry>[];
  for (int i = 0; i < selectable.length && i < 10; i++) {
    final image = selectable[i];
    String word = '';

    if (image.type == CanvasElementType.pictogramCard ||
        image.type == CanvasElementType.networkImage) {
      final pictogramId = _extractIdFromUrl(image.imageUrl ?? '');
      if (pictogramId != null) {
        word = await _getPictogramName(pictogramId);
      }
    }

    if (word.isNotEmpty && word.length >= 3) {
      wordEntries.add(_WordEntry(
        word: word.toUpperCase(),
        image: image,
        number: i + 1,
      ));
    }
  }

  if (wordEntries.isEmpty) {
    return CrosswordResult(
      pages: [[]],
      message: 'No se pudieron obtener palabras de las imágenes',
    );
  }

  // Si hay pocas palabras, intentar añadir palabras comunes para completar
  final commonWords = ['SOL', 'MAR', 'PAN', 'SAL', 'OSO', 'OJO', 'CASA', 'MESA', 'SILLA', 'GATO', 'PERRO', 'FLOR', 'ARBOL'];

  // Crear crucigrama simple (palabras alternadas horizontal/vertical)
  final gridSize = 15;
  final grid = List.generate(gridSize, (_) => List.filled(gridSize, ''));

  // Colocar primera palabra horizontal en el centro
  if (wordEntries.isNotEmpty) {
    final firstWord = wordEntries[0];
    firstWord.isHorizontal = true;
    firstWord.row = gridSize ~/ 2;
    firstWord.col = (gridSize - firstWord.word.length) ~/ 2;
    firstWord.wasPlaced = true;

    for (int i = 0; i < firstWord.word.length; i++) {
      grid[firstWord.row][firstWord.col + i] = firstWord.word[i];
    }
  }

  // Intentar colocar las demás palabras
  for (int i = 1; i < wordEntries.length; i++) {
    final word = wordEntries[i];
    bool placed = false;

    // Intentar cruzar con palabras ya colocadas
    for (int j = 0; j < i && !placed; j++) {
      final existingWord = wordEntries[j];

      // Buscar letras en común
      for (int k = 0; k < word.word.length && !placed; k++) {
        for (int l = 0; l < existingWord.word.length && !placed; l++) {
          if (word.word[k] == existingWord.word[l]) {
            // Intentar colocar perpendicular
            word.isHorizontal = !existingWord.isHorizontal;

            if (word.isHorizontal) {
              word.row = existingWord.row + l;
              word.col = existingWord.col - k;
            } else {
              word.row = existingWord.row - k;
              word.col = existingWord.col + l;
            }

            // Verificar si cabe y no hay conflictos
            if (_canPlaceWord(grid, word, gridSize)) {
              _placeWord(grid, word);
              word.wasPlaced = true;
              placed = true;
            }
          }
        }
      }
    }

    // Si no se pudo cruzar, intentar agregar palabra común de puente
    if (!placed) {
      // Intentar encontrar una palabra común que pueda conectar
      for (final commonWord in commonWords) {
        if (placed) break;

        // Buscar si la palabra común comparte letra con alguna palabra ya colocada
        for (int j = 0; j < i && !placed; j++) {
          final existingWord = wordEntries[j];

          for (int k = 0; k < commonWord.length && !placed; k++) {
            for (int l = 0; l < existingWord.word.length && !placed; l++) {
              if (commonWord[k] == existingWord.word[l]) {
                // Crear entrada temporal para palabra común
                final tempWord = _WordEntry(
                  word: commonWord,
                  image: selectable[0], // Usar imagen dummy
                  number: -1, // Número especial para palabra de relleno
                  isHorizontal: !existingWord.isHorizontal,
                );

                if (tempWord.isHorizontal) {
                  tempWord.row = existingWord.row + l;
                  tempWord.col = existingWord.col - k;
                } else {
                  tempWord.row = existingWord.row - k;
                  tempWord.col = existingWord.col + l;
                }

                if (_canPlaceWord(grid, tempWord, gridSize)) {
                  _placeWord(grid, tempWord);

                  // Ahora intentar cruzar la palabra actual con la palabra común
                  for (int m = 0; m < word.word.length && !placed; m++) {
                    for (int n = 0; n < commonWord.length && !placed; n++) {
                      if (word.word[m] == commonWord[n]) {
                        word.isHorizontal = !tempWord.isHorizontal;

                        if (word.isHorizontal) {
                          word.row = tempWord.row + n;
                          word.col = tempWord.col - m;
                        } else {
                          word.row = tempWord.row - m;
                          word.col = tempWord.col + n;
                        }

                        if (_canPlaceWord(grid, word, gridSize)) {
                          _placeWord(grid, word);
                          word.wasPlaced = true;
                          placed = true;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // Si aún no se pudo colocar, intentar posición libre
    if (!placed) {
      word.isHorizontal = i % 2 == 0;
      for (int row = 0; row < gridSize && !placed; row++) {
        for (int col = 0; col < gridSize && !placed; col++) {
          word.row = row;
          word.col = col;
          if (_canPlaceWord(grid, word, gridSize)) {
            _placeWord(grid, word);
            word.wasPlaced = true;
            placed = true;
          }
        }
      }
    }
  }

  // Filtrar solo las palabras que fueron colocadas exitosamente
  final placedWords = wordEntries.where((word) => word.wasPlaced).toList();

  if (placedWords.isEmpty) {
    return CrosswordResult(
      pages: [[]],
      message: 'No se pudieron colocar las palabras en el crucigrama',
    );
  }

  // Crear página con el crucigrama
  final pageElements = <CanvasImage>[];

  // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
  // NO los agregamos aquí para evitar duplicación en el PDF

  // Dibujar la cuadrícula del crucigrama
  // Ajustar posición inicial hacia arriba para compensar espacio de título/instrucciones
  final cellSize = 20.0;
  final gridStartX = 50.0;
  final gridStartY = 150.0;

  // Encontrar límites del crucigrama
  int minRow = gridSize, maxRow = 0, minCol = gridSize, maxCol = 0;
  for (final word in placedWords) {
    minRow = math.min(minRow, word.row);
    maxRow = math.max(maxRow, word.isHorizontal ? word.row : word.row + word.word.length - 1);
    minCol = math.min(minCol, word.col);
    maxCol = math.max(maxCol, word.isHorizontal ? word.col + word.word.length - 1 : word.col);
  }

  // Dibujar solo las celdas necesarias
  for (int row = minRow; row <= maxRow; row++) {
    for (int col = minCol; col <= maxCol; col++) {
      if (grid[row][col].isNotEmpty) {
        final x = gridStartX + (col - minCol) * cellSize;
        final y = gridStartY + (row - minRow) * cellSize;

        // Celda
        pageElements.add(
          CanvasImage.shape(
            id: 'cell_${row}_$col',
            shapeType: ShapeType.rectangle,
            position: Offset(x, y),
            width: cellSize,
            height: cellSize,
            shapeColor: Colors.black,
            strokeWidth: 1.0,
          ),
        );
      }
    }
  }

  // Números en las palabras
  for (final word in placedWords) {
    final x = gridStartX + (word.col - minCol) * cellSize + 0.5;
    final y = gridStartY + (word.row - minRow) * cellSize + 0.5;

    pageElements.add(
      CanvasImage.text(
        id: 'number_${word.number}',
        text: '${word.number}',
        position: Offset(x, y),
        fontSize: 7,
        textColor: Colors.black,
        fontFamily: 'Arial',
        isBold: true,
        width: 10,
      ),
    );
  }

  // Pistas con imágenes
  final cluesStartY = gridStartY + (maxRow - minRow + 1) * cellSize + 50;
  final imageSize = 50.0;
  final clueSpacing = 65.0;

  for (int i = 0; i < placedWords.length; i++) {
    final word = placedWords[i];
    final x = gridStartX;
    final y = cluesStartY + i * clueSpacing;

    // Número de pista
    pageElements.add(
      CanvasImage.text(
        id: 'clue_number_${word.number}',
        text: '${word.number}.',
        position: Offset(x, y + 15),
        fontSize: 16,
        textColor: Colors.black,
        fontFamily: 'Arial',
        isBold: true,
      ),
    );

    // Imagen de pista
    pageElements.add(
      CanvasImage(
        id: 'clue_image_${word.number}',
        type: word.image.type,
        position: Offset(x + 35, y),
        width: imageSize,
        height: imageSize,
        imageUrl: word.image.imageUrl,
        imagePath: word.image.imagePath,
        webBytes: word.image.webBytes,
        cachedImageBytes: word.image.cachedImageBytes,
      ),
    );

    // Orientación
    pageElements.add(
      CanvasImage.text(
        id: 'clue_direction_${word.number}',
        text: word.isHorizontal ? '→' : '↓',
        position: Offset(x + 95, y + 15),
        fontSize: 18,
        textColor: Colors.grey[600] ?? Colors.grey,
        fontFamily: 'Arial',
      ),
    );
  }

  return CrosswordResult(
    pages: [pageElements],
    message: 'Crucigrama generado con ${placedWords.length} palabra(s)',
  );
}

bool _canPlaceWord(List<List<String>> grid, _WordEntry word, int gridSize) {
  if (word.isHorizontal) {
    if (word.col < 0 || word.col + word.word.length > gridSize || word.row < 0 || word.row >= gridSize) {
      return false;
    }
    for (int i = 0; i < word.word.length; i++) {
      if (grid[word.row][word.col + i].isNotEmpty && grid[word.row][word.col + i] != word.word[i]) {
        return false;
      }
    }
  } else {
    if (word.row < 0 || word.row + word.word.length > gridSize || word.col < 0 || word.col >= gridSize) {
      return false;
    }
    for (int i = 0; i < word.word.length; i++) {
      if (grid[word.row + i][word.col].isNotEmpty && grid[word.row + i][word.col] != word.word[i]) {
        return false;
      }
    }
  }
  return true;
}

void _placeWord(List<List<String>> grid, _WordEntry word) {
  if (word.isHorizontal) {
    for (int i = 0; i < word.word.length; i++) {
      grid[word.row][word.col + i] = word.word[i];
    }
  } else {
    for (int i = 0; i < word.word.length; i++) {
      grid[word.row + i][word.col] = word.word[i];
    }
  }
}

int? _extractIdFromUrl(String url) {
  final match = RegExp(r'/pictograms/(\d+)').firstMatch(url);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }
  return null;
}

Future<String> _getPictogramName(int id) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.arasaac.org/v1/pictograms/es/$id'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final keywords = data['keywords'] as List<dynamic>?;
      if (keywords != null && keywords.isNotEmpty) {
        return keywords[0]['keyword'] as String? ?? '';
      }
    }
  } catch (e) {
    print('Error obteniendo nombre del pictograma: $e');
  }
  return '';
}
