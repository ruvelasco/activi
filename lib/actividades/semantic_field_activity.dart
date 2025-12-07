import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/canvas_image.dart';
import '../services/arasaac_service.dart';
import 'activity_result.dart';

Future<GeneratedActivity> generateSemanticFieldActivity({
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

  if (selectable.isEmpty) return GeneratedActivity(elements: []);

  final result = <CanvasImage>[];
  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  const margin = 40.0;

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
    result.add(
      CanvasImage.text(
        id: 'no_keyword',
        text: 'No se pudo obtener la palabra clave del pictograma',
        position: const Offset(margin, margin + 60),
        fontSize: 16,
        textColor: Colors.orange,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );
    return GeneratedActivity(elements: result);
  }

  List<String> relatedWords =
      await arasaacService.getRelatedWords(searchKeyword);

  if (relatedWords.isEmpty) {
    result.add(
      CanvasImage.text(
        id: 'no_wordnet',
        text: 'No se encontraron palabras relacionadas para "$searchKeyword"',
        position: const Offset(margin, margin + 60),
        fontSize: 16,
        textColor: Colors.orange,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );
    return GeneratedActivity(elements: result);
  }

  // Añadir título
  result.add(
    CanvasImage.text(
      id: 'title',
      text: 'Campo Semántico: ${searchKeyword.toUpperCase()}',
      position: const Offset(margin, margin),
      fontSize: 24,
      textColor: Colors.black,
      fontFamily: 'Roboto',
      scale: 1.0,
    ),
  );

  relatedWords = relatedWords.take(maxWords).toList();

  final pictograms = <ArasaacImage>[];
  for (final word in relatedWords) {
    // Nota: ARASAAC no distingue entre pictogramas y dibujos en el endpoint de búsqueda
    // El parámetro usePictograms podría usarse en el futuro para filtrar por tipo de imagen
    final searchResults = await arasaacService.searchPictograms(word);
    if (searchResults.isNotEmpty) {
      pictograms.add(searchResults.first);
    }
  }

  if (pictograms.isEmpty) {
    result.add(
      CanvasImage.text(
        id: 'no_images',
        text: 'No se encontraron ${usePictograms ? "pictogramas" : "dibujos"} para el campo semántico',
        position: const Offset(margin, margin + 60),
        fontSize: 16,
        textColor: Colors.orange,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );
    return GeneratedActivity(elements: result);
  }

  // Añadir el pictograma/dibujo inicial como referencia
  const initialImageSize = 120.0;
  final initialImageX = (canvasWidth - initialImageSize) / 2;
  final initialImageY = margin + 50;

  if (usePictograms) {
    // Pictograma inicial con marco y texto
    result.add(
      CanvasImage.pictogramCard(
        id: 'initial_pictogram',
        imageUrl: selectable.first.imageUrl ?? '',
        text: searchKeyword,
        position: Offset(initialImageX, initialImageY),
        scale: 1.0,
        fontSize: 18,
        textColor: Colors.black,
      ).copyWith(width: initialImageSize, height: initialImageSize + 40),
    );
  } else {
    // Dibujo inicial sin marco ni texto
    result.add(
      CanvasImage.networkImage(
        id: 'initial_drawing',
        imageUrl: selectable.first.imageUrl ?? '',
        position: Offset(initialImageX, initialImageY),
        scale: 1.0,
      ).copyWith(width: initialImageSize, height: initialImageSize),
    );
  }

  // Calcular el número de columnas según la cantidad de imágenes
  final cols = maxWords <= 4 ? 2 : (maxWords <= 9 ? 3 : (maxWords <= 16 ? 4 : 5));
  const gap = 10.0;
  final textHeight = usePictograms ? 30.0 : 0.0; // Solo añadir espacio para texto si es pictograma

  // Ajustar el tamaño de celda según el número de imágenes
  final cellSize = maxWords <= 4 ? 150.0 : (maxWords <= 9 ? 130.0 : (maxWords <= 16 ? 110.0 : 100.0));

  final gridWidth = cols * cellSize + (cols - 1) * gap;
  final gridStartX = (canvasWidth - gridWidth) / 2;
  final gridStartY = initialImageY + (usePictograms ? initialImageSize + 40 : initialImageSize) + 40;

  for (int i = 0; i < pictograms.length; i++) {
    final col = i % cols;
    final row = i ~/ cols;

    final xPos = gridStartX + col * (cellSize + gap);
    final yPos = gridStartY + row * (cellSize + gap + textHeight);

    final pictogram = pictograms[i];
    final word = relatedWords[i];

    if (usePictograms) {
      // Pictograma con marco y texto
      result.add(
        CanvasImage.pictogramCard(
          id: 'pictogram_$i',
          imageUrl: pictogram.imageUrl,
          text: word,
          position: Offset(xPos, yPos),
          scale: 1.0,
          fontSize: 16,
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
        'Campo semántico generado con ${pictograms.length} ${usePictograms ? "pictogramas" : "dibujos"}',
  );
}
