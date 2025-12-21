import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/canvas_image.dart';

class WritingPracticeResult {
  final List<List<CanvasImage>> pages;
  final TemplateType? template;
  final String? message;
  final String title;
  final String instructions;

  WritingPracticeResult({
    required this.pages,
    this.template,
    this.message,
    this.title = 'PRÁCTICA DE ESCRITURA',
    this.instructions = 'Escribe el nombre de cada imagen en la pauta',
  });
}

WritingPracticeResult generateEmptyWritingResult(String message) {
  return WritingPracticeResult(
    pages: [[]],
    template: TemplateType.writingPractice,
    message: message,
  );
}

Future<String> _getPictogramName(String pictogramId) async {
  final url = Uri.parse(
    'https://api.arasaac.org/v1/pictograms/$pictogramId/languages/es',
  );
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data['keywordsByLocale'] != null) {
        final keywordsByLocale = data['keywordsByLocale'];
        if (keywordsByLocale['es'] != null && keywordsByLocale['es'] is List) {
          final esKeywords = keywordsByLocale['es'] as List;
          if (esKeywords.isNotEmpty) {
            final firstKeyword = esKeywords[0];
            if (firstKeyword['keyword'] != null) {
              return firstKeyword['keyword'].toString();
            }
          }
        }
      }
    }
  } catch (_) {}
  return '';
}

String? _extractIdFromUrl(String url) {
  var regex = RegExp(r'/pictograms/(\d+)(?:\?|$)');
  var match = regex.firstMatch(url);
  if (match != null && match.groupCount >= 1) return match.group(1);

  regex = RegExp(r'/pictograms/(\d+)/\d+_\d+\.png');
  match = regex.firstMatch(url);
  if (match != null && match.groupCount >= 1) return match.group(1);

  return null;
}

Future<WritingPracticeResult> generateWritingPracticeActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  int itemsPerPage = 6,
  bool showModel = false,
  String fontFamily = 'ColeCarreira',
  bool uppercase = true,
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
    return generateEmptyWritingResult('Añade al menos una imagen primero');
  }

  // Determinar filas y columnas según itemsPerPage
  int cols;
  int rows;
  switch (itemsPerPage) {
    case 4:
      cols = 2;
      rows = 2;
      break;
    case 8:
      cols = 4;
      rows = 2;
      break;
    case 10:
      cols = 4;
      rows = 3;
      break;
    case 6:
      cols = 3;
      rows = 2;
      break;
    default:
      cols = 3;
      rows = 2;
      break;
  }

  final totalPages = (selectable.length / itemsPerPage).ceil();
  final pages = <List<CanvasImage>>[];

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  const margin = 30.0;
  const templateHeaderSpace = 120.0; // Espacio para título (60pt) + instrucciones (50pt) + margen
  final cellWidth = (canvasWidth - margin * 2) / cols;
  // Restar el espacio del header del área disponible
  final availableHeight = canvasHeight - templateHeaderSpace - margin * 2;
  final cellHeight = availableHeight / rows;

  for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final pageElements = <CanvasImage>[];

    // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
    // NO los agregamos aquí para evitar duplicación en el PDF

    final pageImages = <CanvasImage>[];

    for (int i = 0; i < itemsPerPage; i++) {
      final globalIndex = pageIndex * itemsPerPage + i;
      final image = selectable[globalIndex % selectable.length];
      pageImages.add(image);
    }

    final imageSize = min(cellWidth * 0.7, cellHeight * 0.45);
    final writingBlockHeight = cellHeight - imageSize - 12;
    final lineWidth = cellWidth * 0.75;
    final lineSpacing = 16.0;

    for (int i = 0; i < pageImages.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final xPos = margin + col * cellWidth + (cellWidth - imageSize) / 2;
      // Comenzar el contenido después del espacio reservado para título/instrucciones
      final yPos = templateHeaderSpace + margin + row * cellHeight;

      final originalImage = pageImages[i];

      if (originalImage.type == CanvasElementType.pictogramCard ||
          originalImage.type == CanvasElementType.networkImage) {
        pageElements.add(
          CanvasImage.networkImage(
            id: 'img_${pageIndex}_$i',
            imageUrl: originalImage.imageUrl!,
            position: Offset(xPos, yPos),
            scale: 0.8,
          ).copyWith(width: imageSize, height: imageSize),
        );
      } else if (originalImage.type == CanvasElementType.localImage) {
        pageElements.add(
          CanvasImage.localImage(
            id: 'img_${pageIndex}_$i',
            imagePath: originalImage.imagePath!,
            position: Offset(xPos, yPos),
            scale: 0.8,
          ).copyWith(width: imageSize, height: imageSize),
        );
      }

      double currentY = yPos + imageSize + 6;

      if (showModel) {
        String modelText = (originalImage.text?.isNotEmpty ?? false) ? originalImage.text! : '';
        if (modelText.isEmpty && (originalImage.imageUrl?.isNotEmpty ?? false)) {
          final pictogramId = _extractIdFromUrl(originalImage.imageUrl!);
          if (pictogramId != null) {
            modelText = await _getPictogramName(pictogramId);
          }
        }

        if (uppercase) {
          modelText = modelText.toUpperCase();
        } else {
          modelText = modelText.toLowerCase();
        }

        pageElements.add(
          CanvasImage.text(
            id: 'model_${pageIndex}_$i',
            text: modelText,
            position: Offset(margin + col * cellWidth, currentY),
            fontSize: 18,
            textColor: Colors.grey[700]!,
            fontFamily: fontFamily,
          ).copyWith(width: cellWidth),
        );
        currentY += modelText.isNotEmpty ? 22 : 10;
      }

      // Tres líneas de escritura centradas
      for (int l = 0; l < 3; l++) {
        pageElements.add(
          CanvasImage.shape(
            id: 'line_${pageIndex}_${i}_$l',
            shapeType: ShapeType.line,
            position: Offset(
              margin + col * cellWidth + (cellWidth - lineWidth) / 2,
              currentY + l * lineSpacing,
            ),
            shapeColor: Colors.grey[500]!,
            strokeWidth: 1.2,
          ).copyWith(width: lineWidth, height: 0),
        );
      }

      // Ajustar si sobra espacio (no se usa, pero deja margen inferior)
      if (currentY + writingBlockHeight < yPos + cellHeight) {
        currentY += writingBlockHeight;
      }
    }

    pages.add(pageElements);
  }

  return WritingPracticeResult(
    pages: pages,
    template: TemplateType.writingPractice,
    message: 'Actividad de escritura generada en $totalPages página(s)',
  );
}
