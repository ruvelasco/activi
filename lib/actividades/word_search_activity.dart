import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/canvas_image.dart';

class WordSearchResult {
  final List<List<CanvasImage>> pages;
  final String message;
  final String title;
  final String instructions;

  WordSearchResult({
    required this.pages,
    required this.message,
    this.title = 'SOPA DE LETRAS',
    this.instructions = 'Encuentra las palabras en la sopa de letras',
  });
}

class _PlacedWord {
  final String word;
  final int row;
  final int col;
  final int dx;
  final int dy;

  _PlacedWord({
    required this.word,
    required this.row,
    required this.col,
    required this.dx,
    required this.dy,
  });
}

/// Genera actividad de sopa de letras
/// Usa las imágenes del canvas para obtener palabras y crear una sopa de letras
Future<WordSearchResult> generateWordSearchActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  String fontFamily = 'Arial',
  int gridSize = 12,
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
    return WordSearchResult(
      pages: [[]],
      message: 'Añade al menos una imagen primero',
    );
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  // Obtener palabras de las imágenes
  final words = <String>[];
  final wordImages = <CanvasImage>[];

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

    if (word.isNotEmpty && word.length >= 3 && word.length <= gridSize) {
      words.add(word.toUpperCase());
      wordImages.add(image);
    }
  }

  if (words.isEmpty) {
    return WordSearchResult(
      pages: [[]],
      message: 'No se pudieron obtener palabras de las imágenes',
    );
  }

  // Crear la sopa de letras
  final grid = List.generate(gridSize, (_) => List.filled(gridSize, ''));
  final placedWords = <_PlacedWord>[];
  final random = math.Random();

  // Direcciones: horizontal, vertical, diagonal (8 direcciones)
  final directions = [
    [0, 1], // horizontal derecha
    [1, 0], // vertical abajo
    [1, 1], // diagonal abajo-derecha
    [1, -1], // diagonal abajo-izquierda
    [0, -1], // horizontal izquierda
    [-1, 0], // vertical arriba
    [-1, -1], // diagonal arriba-izquierda
    [-1, 1], // diagonal arriba-derecha
  ];

  // Intentar colocar cada palabra
  for (final word in words) {
    bool placed = false;
    int attempts = 0;
    const maxAttempts = 100;

    while (!placed && attempts < maxAttempts) {
      attempts++;

      // Posición inicial aleatoria
      final row = random.nextInt(gridSize);
      final col = random.nextInt(gridSize);

      // Dirección aleatoria
      final direction = directions[random.nextInt(directions.length)];
      final dx = direction[0];
      final dy = direction[1];

      // Verificar si la palabra cabe
      if (_canPlaceWord(grid, word, row, col, dx, dy, gridSize)) {
        _placeWord(grid, word, row, col, dx, dy);
        placedWords.add(
          _PlacedWord(word: word, row: row, col: col, dx: dx, dy: dy),
        );
        placed = true;
      }
    }
  }

  // Rellenar espacios vacíos con letras aleatorias
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  for (int row = 0; row < gridSize; row++) {
    for (int col = 0; col < gridSize; col++) {
      if (grid[row][col].isEmpty) {
        grid[row][col] = letters[random.nextInt(letters.length)];
      }
    }
  }

  // Crear página con la sopa de letras
  final pageElements = <CanvasImage>[];

  // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
  // NO los agregamos aquí para evitar duplicación en el PDF

  // Dibujar la cuadrícula de la sopa de letras
  final cellSize = 26.0;
  final gridStartX = (canvasWidth - gridSize * cellSize) / 2;
  final gridStartY = 150.0;

  // Dibujar celdas y letras
  for (int row = 0; row < gridSize; row++) {
    for (int col = 0; col < gridSize; col++) {
      final x = gridStartX + col * cellSize;
      final y = gridStartY + row * cellSize;

      // Celda
      pageElements.add(
        CanvasImage.shape(
          id: 'cell_${row}_$col',
          shapeType: ShapeType.rectangle,
          position: Offset(x, y),
          width: cellSize,
          height: cellSize,
          shapeColor: Colors.grey[400]!,
          strokeWidth: 1.0,
        ),
      );

      // Letra - centrada en la celda
      pageElements.add(
        CanvasImage.text(
          id: 'letter_${row}_$col',
          text: grid[row][col],
          position: Offset(x + 5, y + 7),
          fontSize: 12,
          textColor: Colors.black,
          fontFamily: 'Arial',
          isBold: true,
          width: cellSize,
        ),
      );
    }
  }

  // Lista de palabras a buscar con imágenes - DEBAJO de la cuadrícula
  final wordsListStartY = gridStartY + gridSize * cellSize + 13;
  final imageSize = 40.0;

  pageElements.add(
    CanvasImage.text(
      id: 'words_title',
      text: 'Palabras a buscar:',
      position: Offset(40, wordsListStartY),
      fontSize: 14,
      textColor: Colors.black,
      fontFamily: 'Arial',
      isBold: true,
    ),
  );

  // Colocar palabras en filas horizontales (2 columnas)
  final cols = 2;
  final colWidth = canvasWidth / cols;
  final rowHeight = 45.0;

  for (int i = 0; i < placedWords.length; i++) {
    final word = placedWords[i];
    final row = i ~/ cols;
    final col = i % cols;

    final x = 40 + col * colWidth;
    final y = wordsListStartY + 25 + row * rowHeight;

    // Imagen
    if (i < wordImages.length) {
      pageElements.add(
        CanvasImage(
          id: 'word_image_$i',
          type: wordImages[i].type,
          position: Offset(x, y),
          width: imageSize,
          height: imageSize,
          imageUrl: wordImages[i].imageUrl,
          imagePath: wordImages[i].imagePath,
          webBytes: wordImages[i].webBytes,
          cachedImageBytes: wordImages[i].cachedImageBytes,
        ),
      );
    }

    // Palabra
    pageElements.add(
      CanvasImage.text(
        id: 'word_text_$i',
        text: word.word,
        position: Offset(x + imageSize + 2, y + 13),
        fontSize: 13,
        textColor: Colors.black,
        fontFamily: 'Arial',
      ),
    );
  }

  return WordSearchResult(
    pages: [pageElements],
    message: 'Sopa de letras generada con ${placedWords.length} palabra(s)',
  );
}

bool _canPlaceWord(
  List<List<String>> grid,
  String word,
  int row,
  int col,
  int dx,
  int dy,
  int gridSize,
) {
  for (int i = 0; i < word.length; i++) {
    final newRow = row + i * dx;
    final newCol = col + i * dy;

    // Verificar límites
    if (newRow < 0 || newRow >= gridSize || newCol < 0 || newCol >= gridSize) {
      return false;
    }

    // Verificar conflictos (permitir misma letra)
    if (grid[newRow][newCol].isNotEmpty && grid[newRow][newCol] != word[i]) {
      return false;
    }
  }

  return true;
}

void _placeWord(
  List<List<String>> grid,
  String word,
  int row,
  int col,
  int dx,
  int dy,
) {
  for (int i = 0; i < word.length; i++) {
    final newRow = row + i * dx;
    final newCol = col + i * dy;
    grid[newRow][newCol] = word[i];
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
