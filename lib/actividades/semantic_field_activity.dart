import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/canvas_image.dart';
import '../services/arasaac_service.dart';

class SemanticFieldActivityResult {
  final List<List<CanvasImage>> pages;
  final String title;
  final String instructions;
  final String? message;

  SemanticFieldActivityResult({
    required this.pages,
    this.title = 'CAMPO SEMÁNTICO',
    this.instructions = 'Identifica las palabras relacionadas',
    this.message,
  });
}

Future<SemanticFieldActivityResult> generateSemanticFieldActivity({
  required List<CanvasImage> images,
  required ArasaacService arasaacService,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  int maxWords = 25,
  bool usePictograms = true,
}) async {
  final selectable = images
      .where((element) =>
          element.type == CanvasElementType.networkImage ||
          element.type == CanvasElementType.pictogramCard)
      .toList();

  if (selectable.isEmpty) return SemanticFieldActivityResult(pages: []);

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  const margin = 40.0;
  const templateHeaderSpace = 140.0;

  String? searchKeyword;
  int? pictogramId;

  if (selectable.first.type == CanvasElementType.pictogramCard) {
    searchKeyword = selectable.first.text?.toLowerCase();
  } else if (selectable.first.type == CanvasElementType.networkImage) {
    final url = selectable.first.imageUrl;
    if (url != null) {
      final match = RegExp('/pictograms/(\\d+)').firstMatch(url);
      if (match != null) {
        pictogramId = int.tryParse(match.group(1)!);
      }
    }
  }

  if (pictogramId != null && (searchKeyword == null || searchKeyword.isEmpty)) {
    try {
      final detailUrl =
          '${ArasaacService.baseUrl}/pictograms/${arasaacService.config.language}/$pictogramId';
      final response = await http.get(Uri.parse(detailUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final keywords =
            (data['keywords'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
                [];
        if (keywords.isNotEmpty) {
          searchKeyword = keywords.first['keyword'] as String?;
        }
      }
    } catch (_) {}
  }

  if (searchKeyword == null || searchKeyword.isEmpty) {
    return SemanticFieldActivityResult(
      pages: [],
      message: 'No se pudo obtener la palabra clave del pictograma',
    );
  }

  List<String> relatedWords =
      await arasaacService.getRelatedWords(searchKeyword);

  if (relatedWords.isEmpty) {
    return SemanticFieldActivityResult(
      pages: [],
      message: 'No se encontraron palabras relacionadas para "$searchKeyword"',
    );
  }

  relatedWords = relatedWords.take(maxWords).toList();

  final pictograms = <ArasaacImage>[];
  for (final word in relatedWords) {
    final searchResults = await arasaacService.searchPictograms(word);
    if (searchResults.isNotEmpty) {
      pictograms.add(searchResults.first);
    }
  }

  if (pictograms.isEmpty) {
    return SemanticFieldActivityResult(
      pages: [],
      message: 'No se encontraron ${usePictograms ? "pictogramas" : "dibujos"} para el campo semántico',
    );
  }

  // Calcular cuántos elementos caben por página
  const cols = 5;
  const gap = 10.0;
  const cellSize = 100.0;
  final textHeight = usePictograms ? 30.0 : 0.0;

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
    final pageWords = relatedWords.sublist(startIdx, endIdx);

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
            fontSize: 14,
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

  return SemanticFieldActivityResult(
    pages: allPages,
    message: 'Campo semántico generado con ${pictograms.length} ${usePictograms ? "pictogramas" : "dibujos"} en ${allPages.length} página${allPages.length > 1 ? "s" : ""}',
  );
}
