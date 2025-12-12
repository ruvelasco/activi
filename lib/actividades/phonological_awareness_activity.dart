import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/canvas_image.dart';
import '../utils/syllables_helper.dart';
import 'activity_result.dart';

/// Genera actividad de conciencia fonológica
/// Muestra imágenes con sus sílabas debajo y líneas para repasar en letra escolar
Future<GeneratedActivity> generatePhonologicalAwarenessActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
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
    return GeneratedActivity(
      elements: [],
      message: 'Añade al menos una imagen primero',
    );
  }

  final result = <CanvasImage>[];
  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  // Layout en 2 columnas
  const cols = 2;
  final rows = (selectable.length / cols).ceil();
  const margin = 40.0;
  final cellWidth = (canvasWidth - margin * 2) / cols;
  final cellHeight = (canvasHeight - margin * 2) / rows;

  // Procesar cada imagen
  for (int i = 0; i < selectable.length; i++) {
    final col = i % cols;
    final row = i ~/ cols;

    final cellX = margin + col * cellWidth;
    final cellY = margin + row * cellHeight;

    final originalImage = selectable[i];

    // Calcular dimensiones
    const imageSize = 120.0;
    final imageX = cellX + (cellWidth - imageSize) / 2;
    final imageY = cellY + 10;

    // Añadir imagen
    if (originalImage.type == CanvasElementType.pictogramCard ||
        originalImage.type == CanvasElementType.networkImage) {
      result.add(
        CanvasImage.networkImage(
          id: 'img_$i',
          imageUrl: originalImage.imageUrl!,
          position: Offset(imageX, imageY),
          scale: 1.0,
        ).copyWith(width: imageSize, height: imageSize),
      );

      // Obtener ID y nombre del pictograma de la URL
      debugPrint('URL de imagen: ${originalImage.imageUrl}');
      final pictogramId = _extractIdFromUrl(originalImage.imageUrl!);
      String palabra = '';

      if (pictogramId != null) {
        debugPrint('Pictogram ID: $pictogramId');
        palabra = await _getPictogramName(pictogramId);
        debugPrint('Palabra obtenida: $palabra');
      } else {
        debugPrint('No se pudo extraer el ID del pictograma de la URL');
      }

      if (palabra.isNotEmpty) {
        // Obtener sílabas de la API
        String silabasStr = await SyllablesHelper.obtenerSilabas(palabra);
        debugPrint('Sílabas obtenidas: $silabasStr');
        List<String> silabas = SyllablesHelper.separarSilabas(silabasStr);
        debugPrint('Sílabas separadas: $silabas');

        if (silabas.isNotEmpty) {
          // Posición para las sílabas
          final syllablesY = imageY + imageSize + 10;

          // Mostrar sílabas en mayúsculas
          final syllablesText = silabas.join(' - ').toUpperCase();
          result.add(
            CanvasImage.text(
              id: 'syllables_$i',
              text: syllablesText,
              position: Offset(cellX + 10, syllablesY),
              fontSize: 20.0,
              textColor: Colors.black,
              isBold: true,
            ).copyWith(width: cellWidth - 20),
          );

          // Líneas para repasar cada sílaba (letra escolar)
          final linesY = syllablesY + 35;
          final lineSpacing = 45.0;

          for (int j = 0; j < silabas.length; j++) {
            final lineY = linesY + (j * lineSpacing);

            // Sílaba en gris claro como guía
            result.add(
              CanvasImage.text(
                id: 'guide_${i}_$j',
                text: silabas[j].toUpperCase(),
                position: Offset(cellX + 15, lineY - 25),
                fontSize: 18.0,
                textColor: Colors.grey[400]!,
                isBold: false,
              ),
            );

            // Línea superior (azul claro)
            result.add(
              CanvasImage.shape(
                id: 'line_top_${i}_$j',
                shapeType: ShapeType.line,
                position: Offset(cellX + 15, lineY),
                shapeColor: Colors.blue[300]!,
                strokeWidth: 1.0,
              ).copyWith(width: cellWidth - 30, height: 0),
            );

            // Línea central (negra)
            result.add(
              CanvasImage.shape(
                id: 'line_mid_${i}_$j',
                shapeType: ShapeType.line,
                position: Offset(cellX + 15, lineY + 15),
                shapeColor: Colors.black,
                strokeWidth: 2.0,
              ).copyWith(width: cellWidth - 30, height: 0),
            );

            // Línea inferior (azul claro)
            result.add(
              CanvasImage.shape(
                id: 'line_bot_${i}_$j',
                shapeType: ShapeType.line,
                position: Offset(cellX + 15, lineY + 30),
                shapeColor: Colors.blue[300]!,
                strokeWidth: 1.0,
              ).copyWith(width: cellWidth - 30, height: 0),
            );
          }
        }
      }
    } else if (originalImage.type == CanvasElementType.localImage) {
      result.add(
        CanvasImage.localImage(
          id: 'img_$i',
          imagePath: originalImage.imagePath!,
          position: Offset(imageX, imageY),
          scale: 1.0,
        ).copyWith(width: imageSize, height: imageSize),
      );

      // Para imágenes locales, mostrar mensaje
      result.add(
        CanvasImage.text(
          id: 'local_msg_$i',
          text: '(Sílabas no disponibles\npara imágenes locales)',
          position: Offset(cellX + 10, imageY + imageSize + 10),
          fontSize: 12.0,
          textColor: Colors.grey,
        ).copyWith(width: cellWidth - 20),
      );
    }
  }

  return GeneratedActivity(
    elements: result,
    message:
        'Actividad de conciencia fonológica generada con ${selectable.length} palabra(s)',
  );
}

/// Extrae el ID del pictograma de la URL de ARASAAC
String? _extractIdFromUrl(String url) {
  // URL típica API: https://api.arasaac.org/v1/pictograms/28339?download=false
  // URL típica estática: https://static.arasaac.org/pictograms/2242/2242_300.png

  // Intentar con formato de API primero
  var regex = RegExp(r'/pictograms/(\d+)(?:\?|$)');
  var match = regex.firstMatch(url);

  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }

  // Intentar con formato estático
  regex = RegExp(r'/pictograms/(\d+)/\d+_\d+\.png');
  match = regex.firstMatch(url);

  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }

  return null;
}

/// Obtiene el nombre del pictograma desde la API de ARASAAC
Future<String> _getPictogramName(String pictogramId) async {
  final url = Uri.parse(
    'https://api.arasaac.org/v1/pictograms/$pictogramId/languages/es',
  );

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));

      // La estructura correcta es: keywordsByLocale.es[0].keyword
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
  } catch (e) {
    debugPrint('Error obteniendo nombre de pictograma $pictogramId: $e');
  }

  return '';
}
