import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/canvas_image.dart';
import '../services/arasaac_service.dart';

class ActivityGenerators {
  // Generador de actividad de relacionar sombras
  static List<CanvasImage> generateShadowMatchingActivity({
    required List<CanvasImage> canvasImages,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
  }) {
    final images = canvasImages.where((element) =>
        element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.localImage ||
        element.type == CanvasElementType.pictogramCard).toList();

    if (images.isEmpty) return [];

    final selectedImages = images.take(5).toList();
    final result = <CanvasImage>[];

    final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
    final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

    final margin = 40.0;
    final columnWidth = (canvasWidth - 3 * margin) / 2;
    final rowHeight = (canvasHeight - 2 * margin) / 5;
    final imageSize = 120.0;

    // Crear lista de sombras y desordenarlas
    final shadowList = List<int>.from(List.generate(selectedImages.length, (i) => i));
    shadowList.shuffle();

    // Colocar imágenes en columna izquierda
    for (int i = 0; i < selectedImages.length; i++) {
      final originalImage = selectedImages[i];
      final yPos = margin + rowHeight * i + (rowHeight - imageSize) / 2;
      final xPos = margin + (columnWidth - imageSize) / 2;

      if (originalImage.type == CanvasElementType.pictogramCard) {
        result.add(
          CanvasImage.pictogramCard(
            id: 'left_$i',
            imageUrl: originalImage.imageUrl!,
            text: originalImage.text ?? '',
            position: Offset(xPos, yPos),
            scale: 0.8,
          ),
        );
      } else {
        result.add(
          CanvasImage.networkImage(
            id: 'left_$i',
            imageUrl: originalImage.imageUrl ?? '',
            position: Offset(xPos, yPos),
            scale: 0.8,
          ),
        );
      }
    }

    // Colocar sombras desordenadas en columna derecha
    for (int i = 0; i < selectedImages.length; i++) {
      final shadowIndex = shadowList[i];
      final originalImage = selectedImages[shadowIndex];
      final yPos = margin + rowHeight * i + (rowHeight - imageSize) / 2;
      final xPos = canvasWidth / 2 + margin + (columnWidth - imageSize) / 2;

      result.add(
        CanvasImage.shadow(
          id: 'shadow_$i',
          imageUrl: originalImage.imageUrl ?? '',
          position: Offset(xPos, yPos),
          scale: 0.8,
        ),
      );
    }

    return result;
  }

  // Generador de actividad de puzle
  static List<CanvasImage> generatePuzzleActivity({
    required List<CanvasImage> canvasImages,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
  }) {
    final images = canvasImages.where((element) =>
        element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.localImage ||
        element.type == CanvasElementType.pictogramCard).toList();

    if (images.isEmpty) return [];

    final selectedImage = images.first;
    final result = <CanvasImage>[];

    final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
    final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

    final imageWidth = canvasWidth;
    final imageHeight = canvasHeight;

    String? imageUrl;
    if (selectedImage.type == CanvasElementType.pictogramCard ||
        selectedImage.type == CanvasElementType.networkImage) {
      imageUrl = selectedImage.imageUrl;
    }

    if (imageUrl != null) {
      result.add(
        CanvasImage.networkImage(
          id: 'puzzle_image',
          imageUrl: imageUrl,
          position: Offset(0, 0),
          scale: 1.0,
        ).copyWith(
          width: imageWidth,
          height: imageHeight,
        ),
      );
    } else if (selectedImage.imagePath != null) {
      result.add(
        CanvasImage.localImage(
          id: 'puzzle_image',
          imagePath: selectedImage.imagePath!,
          position: Offset(0, 0),
          scale: 1.0,
        ).copyWith(
          width: imageWidth,
          height: imageHeight,
        ),
      );
    }

    return result;
  }

  // Generador de actividad de práctica de escritura
  static List<CanvasImage> generateWritingPracticeActivity({
    required List<CanvasImage> canvasImages,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
  }) {
    final images = canvasImages.where((element) =>
        element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.localImage ||
        element.type == CanvasElementType.pictogramCard).toList();

    if (images.isEmpty) return [];

    final result = <CanvasImage>[];
    final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;

    final cols = 3;
    final margin = 30.0;
    final imageSize = 120.0;
    final writingHeight = 50.0;
    final cellWidth = (canvasWidth - margin * 2) / cols;
    final cellHeight = imageSize + writingHeight + 20;

    for (int i = 0; i < images.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final xPos = margin + col * cellWidth + (cellWidth - imageSize) / 2;
      final yPos = margin + row * cellHeight;

      final originalImage = images[i];

      // Añadir imagen
      if (originalImage.type == CanvasElementType.pictogramCard) {
        result.add(
          CanvasImage.networkImage(
            id: 'img_$i',
            imageUrl: originalImage.imageUrl!,
            position: Offset(xPos, yPos),
            scale: 0.8,
          ),
        );
      } else if (originalImage.type == CanvasElementType.networkImage) {
        result.add(
          CanvasImage.networkImage(
            id: 'img_$i',
            imageUrl: originalImage.imageUrl!,
            position: Offset(xPos, yPos),
            scale: 0.8,
          ),
        );
      } else if (originalImage.type == CanvasElementType.localImage) {
        result.add(
          CanvasImage.localImage(
            id: 'img_$i',
            imagePath: originalImage.imagePath!,
            position: Offset(xPos, yPos),
            scale: 0.8,
          ),
        );
      }

      // Añadir líneas de doble pauta
      final lineY = yPos + imageSize + 10;
      final lineWidth = imageSize;

      result.add(
        CanvasImage.shape(
          id: 'line1_$i',
          shapeType: ShapeType.line,
          position: Offset(xPos, lineY),
          shapeColor: Colors.blue[300]!,
          strokeWidth: 1.0,
        ).copyWith(width: lineWidth, height: 0),
      );

      result.add(
        CanvasImage.shape(
          id: 'line2_$i',
          shapeType: ShapeType.line,
          position: Offset(xPos, lineY + 15),
          shapeColor: Colors.black,
          strokeWidth: 2.0,
        ).copyWith(width: lineWidth, height: 0),
      );

      result.add(
        CanvasImage.shape(
          id: 'line3_$i',
          shapeType: ShapeType.line,
          position: Offset(xPos, lineY + 30),
          shapeColor: Colors.blue[300]!,
          strokeWidth: 1.0,
        ).copyWith(width: lineWidth, height: 0),
      );
    }

    return result;
  }

  // Generador de actividad de práctica de conteo
  static List<CanvasImage> generateCountingActivity({
    required List<CanvasImage> canvasImages,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
  }) {
    final images = canvasImages.where((element) =>
        element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.localImage ||
        element.type == CanvasElementType.pictogramCard).toList();

    if (images.isEmpty) return [];

    final result = <CanvasImage>[];
    final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
    final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

    final cols = 2;
    final rows = (images.length / cols).ceil();

    final margin = 40.0;
    final cellWidth = (canvasWidth - margin * 2) / cols;
    final cellHeight = (canvasHeight - margin * 2) / rows;

    for (int i = 0; i < images.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final cellX = margin + col * cellWidth;
      final cellY = margin + row * cellHeight;

      final originalImage = images[i];

      // Número aleatorio de repeticiones (1-10)
      final random = DateTime.now().millisecondsSinceEpoch + i;
      final count = (random % 10) + 1;

      final boxWidth = cellWidth - 20;
      final boxHeight = cellHeight - 80;

      // Dibujar rectángulo contenedor
      result.add(
        CanvasImage.shape(
          id: 'box_$i',
          shapeType: ShapeType.rectangle,
          position: Offset(cellX + 10, cellY + 10),
          shapeColor: Colors.grey[400]!,
          strokeWidth: 2.0,
        ).copyWith(width: boxWidth, height: boxHeight),
      );

      // Distribuir las imágenes dentro del cuadrado
      final imgCols = count <= 2 ? count : (count <= 6 ? 3 : 4);
      final imgRows = (count / imgCols).ceil();

      final imgSize = 40.0;
      final imgSpacingX = (boxWidth - 20) / imgCols;
      final imgSpacingY = (boxHeight - 20) / imgRows;

      for (int j = 0; j < count; j++) {
        final imgCol = j % imgCols;
        final imgRow = j ~/ imgCols;

        final imgX = cellX + 20 + imgCol * imgSpacingX + (imgSpacingX - imgSize) / 2;
        final imgY = cellY + 20 + imgRow * imgSpacingY + (imgSpacingY - imgSize) / 2;

        if (originalImage.type == CanvasElementType.pictogramCard ||
            originalImage.type == CanvasElementType.networkImage) {
          result.add(
            CanvasImage.networkImage(
              id: 'img_${i}_$j',
              imageUrl: originalImage.imageUrl!,
              position: Offset(imgX, imgY),
              scale: 1.0,
            ).copyWith(width: imgSize, height: imgSize),
          );
        } else if (originalImage.type == CanvasElementType.localImage) {
          result.add(
            CanvasImage.localImage(
              id: 'img_${i}_$j',
              imagePath: originalImage.imagePath!,
              position: Offset(imgX, imgY),
              scale: 1.0,
            ).copyWith(width: imgSize, height: imgSize),
          );
        }
      }

      // Añadir líneas de doble pauta debajo del cuadrado
      final lineY = cellY + boxHeight + 20;
      final lineWidth = boxWidth;

      result.add(
        CanvasImage.shape(
          id: 'line1_$i',
          shapeType: ShapeType.line,
          position: Offset(cellX + 10, lineY),
          shapeColor: Colors.blue[300]!,
          strokeWidth: 1.0,
        ).copyWith(width: lineWidth, height: 0),
      );

      result.add(
        CanvasImage.shape(
          id: 'line2_$i',
          shapeType: ShapeType.line,
          position: Offset(cellX + 10, lineY + 15),
          shapeColor: Colors.black,
          strokeWidth: 2.0,
        ).copyWith(width: lineWidth, height: 0),
      );

      result.add(
        CanvasImage.shape(
          id: 'line3_$i',
          shapeType: ShapeType.line,
          position: Offset(cellX + 10, lineY + 30),
          shapeColor: Colors.blue[300]!,
          strokeWidth: 1.0,
        ).copyWith(width: lineWidth, height: 0),
      );
    }

    return result;
  }

  /// Generador de actividad de series: muestra un modelo y deja huecos para continuarla.
  static List<CanvasImage> generateSeriesActivity({
    required List<CanvasImage> canvasImages,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
    int modelLength = 4,
    int blanksToFill = 3,
  }) {
    final items = canvasImages.where((element) {
      return element.type == CanvasElementType.networkImage ||
          element.type == CanvasElementType.localImage ||
          element.type == CanvasElementType.pictogramCard;
    }).toList();

    if (items.length < 2) return [];

    // Tomamos dos elementos para alternar la serie (ABAB…)
    final first = items[0];
    final second = items[1];

    final result = <CanvasImage>[];

    final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
    final margin = 40.0;
    final cellSize = 110.0;
    final gap = 16.0;

    // Texto introductorio
    result.add(
      CanvasImage.text(
        id: 'series_title',
        text: 'Continúa la serie',
        position: Offset(margin, margin),
        fontSize: 26,
        textColor: Colors.black,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );

    // Línea de ejemplo / modelo
    final startY = margin + 50;
    final startX = margin;
    for (int i = 0; i < modelLength; i++) {
      final isFirst = i % 2 == 0;
      final xPos = startX + i * (cellSize + gap);
      final baseId = 'model_$i';
      final source = isFirst ? first : second;

      if (source.type == CanvasElementType.pictogramCard || source.type == CanvasElementType.networkImage) {
        result.add(
          CanvasImage.networkImage(
            id: baseId,
            imageUrl: source.imageUrl ?? '',
            position: Offset(xPos, startY),
            scale: 0.8,
          ).copyWith(width: cellSize, height: cellSize),
        );
      } else {
        result.add(
          CanvasImage.localImage(
            id: baseId,
            imagePath: source.imagePath ?? '',
            position: Offset(xPos, startY),
            scale: 0.8,
          ).copyWith(width: cellSize, height: cellSize),
        );
      }
    }

    // Línea para que el alumno complete
    final blanksStartY = startY + cellSize + 40;
    final totalSlots = blanksToFill + 2; // añadimos dos primeros de referencia
    for (int i = 0; i < totalSlots; i++) {
      final isFirst = i % 2 == 0;
      final xPos = startX + i * (cellSize + gap);
      final baseId = 'exercise_$i';

      if (i < 2) {
        // mostrarmos los dos primeros como guía de la serie
        final source = isFirst ? first : second;
        if (source.type == CanvasElementType.pictogramCard || source.type == CanvasElementType.networkImage) {
          result.add(
            CanvasImage.networkImage(
              id: baseId,
              imageUrl: source.imageUrl ?? '',
              position: Offset(xPos, blanksStartY),
              scale: 0.8,
            ).copyWith(width: cellSize, height: cellSize),
          );
        } else {
          result.add(
            CanvasImage.localImage(
              id: baseId,
              imagePath: source.imagePath ?? '',
              position: Offset(xPos, blanksStartY),
              scale: 0.8,
            ).copyWith(width: cellSize, height: cellSize),
          );
        }
      } else {
        // hueco vacío para completar
        result.add(
          CanvasImage.shape(
            id: 'blank_$i',
            shapeType: ShapeType.rectangle,
            position: Offset(xPos, blanksStartY),
            shapeColor: Colors.grey[400]!,
            strokeWidth: 2.0,
          ).copyWith(width: cellSize, height: cellSize),
        );
      }
    }

    return result;
  }

  /// Generador de actividad de simetrías: muestra un modelo y una cuadrícula con el objeto en diferentes orientaciones.
  static List<CanvasImage> generateSymmetryActivity({
    required List<CanvasImage> canvasImages,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
  }) {
    final items = canvasImages.where((element) {
      return element.type == CanvasElementType.networkImage ||
          element.type == CanvasElementType.localImage ||
          element.type == CanvasElementType.pictogramCard;
    }).toList();

    if (items.isEmpty) return [];

    final modelImage = items.first;
    final result = <CanvasImage>[];

    final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
    final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

    final margin = 40.0;
    final cellSize = 80.0;
    final gap = 8.0;

    // Texto introductorio
    result.add(
      CanvasImage.text(
        id: 'symmetry_title',
        text: 'Busca los objetos iguales al modelo',
        position: Offset(margin, margin),
        fontSize: 20,
        textColor: Colors.black,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );

    // Cuadrado para el modelo
    final modelBoxSize = 130.0;
    final modelBoxY = margin + 40;
    final modelBoxX = (canvasWidth - modelBoxSize) / 2;

    result.add(
      CanvasImage.shape(
        id: 'model_box',
        shapeType: ShapeType.rectangle,
        position: Offset(modelBoxX, modelBoxY),
        shapeColor: Colors.grey[700]!,
        strokeWidth: 3.0,
      ).copyWith(width: modelBoxSize, height: modelBoxSize),
    );

    // Imagen modelo (centrada dentro del cuadrado)
    final modelSize = 100.0;
    final modelY = modelBoxY + (modelBoxSize - modelSize) / 2;
    final modelX = modelBoxX + (modelBoxSize - modelSize) / 2;

    if (modelImage.type == CanvasElementType.pictogramCard ||
        modelImage.type == CanvasElementType.networkImage) {
      result.add(
        CanvasImage.networkImage(
          id: 'model',
          imageUrl: modelImage.imageUrl ?? '',
          position: Offset(modelX, modelY),
          scale: 1.0,
        ).copyWith(width: modelSize, height: modelSize),
      );
    } else {
      result.add(
        CanvasImage.localImage(
          id: 'model',
          imagePath: modelImage.imagePath ?? '',
          position: Offset(modelX, modelY),
          scale: 1.0,
        ).copyWith(width: modelSize, height: modelSize),
      );
    }

    // Cuadrícula 5x5
    final gridStartY = modelBoxY + modelBoxSize + 30;
    final gridWidth = 5 * cellSize + 4 * gap;
    final gridHeight = 5 * cellSize + 4 * gap;
    final gridStartX = (canvasWidth - gridWidth) / 2;

    // Cuadrado grande para la cuadrícula
    final gridPadding = 20.0;
    result.add(
      CanvasImage.shape(
        id: 'grid_box',
        shapeType: ShapeType.rectangle,
        position: Offset(gridStartX - gridPadding, gridStartY - gridPadding),
        shapeColor: Colors.grey[400]!,
        strokeWidth: 2.0,
      ).copyWith(
        width: gridWidth + 2 * gridPadding,
        height: gridHeight + 2 * gridPadding,
      ),
    );

    // Lista de transformaciones posibles
    final transformations = [
      {'rotation': 0.0, 'flipH': false, 'flipV': false}, // Original
      {'rotation': 90.0, 'flipH': false, 'flipV': false}, // Rotado 90°
      {'rotation': 180.0, 'flipH': false, 'flipV': false}, // Rotado 180°
      {'rotation': 270.0, 'flipH': false, 'flipV': false}, // Rotado 270°
      {'rotation': 0.0, 'flipH': true, 'flipV': false}, // Volteado horizontal
      {'rotation': 0.0, 'flipH': false, 'flipV': true}, // Volteado vertical
      {'rotation': 0.0, 'flipH': true, 'flipV': true}, // Volteado ambos
      {'rotation': 90.0, 'flipH': true, 'flipV': false}, // 90° + flip H
    ];

    // Crear lista de 25 transformaciones aleatorias (asegurando que haya al menos 3-5 originales)
    final random = DateTime.now().millisecondsSinceEpoch;
    final gridTransformations = <Map<String, dynamic>>[];

    // Añadir 4 originales en posiciones aleatorias
    for (int i = 0; i < 4; i++) {
      gridTransformations.add({'rotation': 0.0, 'flipH': false, 'flipV': false});
    }

    // Completar hasta 25 con transformaciones aleatorias
    for (int i = 4; i < 25; i++) {
      final index = (random + i * 7) % transformations.length;
      gridTransformations.add(transformations[index]);
    }

    // Desordenar la lista
    gridTransformations.shuffle();

    // Crear la cuadrícula
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        final index = row * 5 + col;
        final xPos = gridStartX + col * (cellSize + gap);
        final yPos = gridStartY + row * (cellSize + gap);

        final transform = gridTransformations[index];
        final rotation = transform['rotation'] as double;
        final flipH = transform['flipH'] as bool;
        final flipV = transform['flipV'] as bool;

        if (modelImage.type == CanvasElementType.pictogramCard ||
            modelImage.type == CanvasElementType.networkImage) {
          result.add(
            CanvasImage.networkImage(
              id: 'grid_${row}_$col',
              imageUrl: modelImage.imageUrl ?? '',
              position: Offset(xPos, yPos),
              scale: 1.0,
            ).copyWith(
              width: cellSize,
              height: cellSize,
              rotation: rotation,
              flipHorizontal: flipH,
              flipVertical: flipV,
            ),
          );
        } else {
          result.add(
            CanvasImage.localImage(
              id: 'grid_${row}_$col',
              imagePath: modelImage.imagePath ?? '',
              position: Offset(xPos, yPos),
              scale: 1.0,
            ).copyWith(
              width: cellSize,
              height: cellSize,
              rotation: rotation,
              flipHorizontal: flipH,
              flipVertical: flipV,
            ),
          );
        }
      }
    }

    return result;
  }

  /// Generador de actividad de vocabulario por sílaba: busca palabras que empiezan o terminan con una sílaba específica.
  static Future<List<CanvasImage>> generateSyllableVocabularyActivity({
    required String syllable,
    required ArasaacService arasaacService,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
    int maxWords = 9,
    String syllablePosition = 'start', // 'start' o 'end'
  }) async {
    final result = <CanvasImage>[];

    final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
    final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

    final margin = 40.0;

    // Título con la sílaba
    final titleText = syllablePosition == 'start'
        ? 'Palabras que empiezan por: ${syllable.toUpperCase()}'
        : 'Palabras que terminan en: ${syllable.toUpperCase()}';

    result.add(
      CanvasImage.text(
        id: 'syllable_title',
        text: titleText,
        position: Offset(margin, margin),
        fontSize: 24,
        textColor: Colors.black,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );

    // Lista de palabras comunes que empiezan con cada sílaba
    final wordsStartMap = {
      'pa': ['pato', 'pan', 'papá', 'paloma', 'pala', 'payaso', 'pastel', 'paella', 'palabra'],
      'pe': ['perro', 'pez', 'pelota', 'pera', 'pelo', 'peine', 'peluche', 'pepino', 'persona'],
      'pi': ['piscina', 'piña', 'pico', 'pie', 'piano', 'pintura', 'pirata', 'pistola', 'pijama'],
      'po': ['pollo', 'policía', 'pomelo', 'polo', 'postre', 'poder', 'pozo', 'poeta', 'politica'],
      'pu': ['puerta', 'pueblo', 'puente', 'pulpo', 'pulsera', 'pulmón', 'pupitre', 'punto', 'puño'],
      'ma': ['mamá', 'mano', 'mar', 'manzana', 'mariposa', 'malo', 'martillo', 'mañana', 'maestro'],
      'me': ['mesa', 'melón', 'médico', 'media', 'metal', 'metro', 'melocotón', 'mensaje', 'menor'],
      'mi': ['miedo', 'miel', 'mina', 'minuto', 'mirar', 'mismo', 'mitad', 'mito', 'microscopio'],
      'mo': ['moto', 'mono', 'mosca', 'morado', 'mochila', 'moneda', 'montaña', 'molino', 'momento'],
      'mu': ['muñeca', 'muro', 'música', 'museo', 'mujer', 'mundo', 'muela', 'mucho', 'muerte'],
      'sa': ['sapo', 'sal', 'saco', 'salsa', 'sandía', 'sábana', 'sartén', 'salud', 'sabio'],
      'se': ['seta', 'sed', 'sello', 'semana', 'serpiente', 'señor', 'segunda', 'segundo', 'semilla'],
      'si': ['silla', 'sí', 'siete', 'silla', 'silencio', 'sitio', 'símbolo', 'simple', 'sirena'],
      'so': ['sol', 'sopa', 'sofá', 'soldado', 'solo', 'sobre', 'sonido', 'sombra', 'sor'],
      'su': ['suma', 'sur', 'sudor', 'sueño', 'suelo', 'sucio', 'suerte', 'suela', 'surf'],
      'la': ['lago', 'lámpara', 'lana', 'lápiz', 'lazo', 'lado', 'labio', 'látigo', 'lavadora'],
      'le': ['león', 'leche', 'letra', 'ley', 'leer', 'lejos', 'lengua', 'lento', 'lección'],
      'li': ['libro', 'limón', 'lima', 'lino', 'línea', 'liso', 'lista', 'litro', 'libre'],
      'lo': ['lobo', 'loro', 'loco', 'lodo', 'lomo', 'lote', 'lotería', 'loza', 'local'],
      'lu': ['luna', 'luz', 'lugar', 'lucha', 'lujo', 'lunes', 'lupa', 'luciérnaga', 'lucir'],
      'ca': ['casa', 'caballo', 'café', 'cama', 'camión', 'cara', 'cabeza', 'calabaza', 'caja'],
      'co': ['conejo', 'corazón', 'coche', 'comida', 'cocodrilo', 'color', 'cola', 'codo', 'copa'],
      'cu': ['cuatro', 'cuchara', 'cuello', 'cuerpo', 'cuento', 'cubo', 'cuerda', 'cueva', 'cuna'],
      'ta': ['taza', 'tabla', 'taburete', 'tarro', 'tarde', 'taxi', 'tapa', 'tallo', 'tambor'],
      'te': ['teléfono', 'tele', 'té', 'teatro', 'techo', 'tela', 'tema', 'tejado', 'templo'],
      'ti': ['tigre', 'tijeras', 'tiempo', 'tierra', 'tinta', 'tío', 'tipo', 'tienda', 'timbre'],
      'to': ['tomate', 'toro', 'torre', 'tortuga', 'torta', 'toalla', 'tostada', 'total', 'todo'],
      'tu': ['túnel', 'turismo', 'turno', 'tutor', 'tubo', 'tú', 'tulipán', 'tumba', 'tumor'],
      'ba': ['barco', 'ballena', 'balón', 'banco', 'baño', 'bañera', 'banana', 'bata', 'balanza'],
      'be': ['bebé', 'beber', 'beso', 'bella', 'bestia', 'belleza', 'beneficio', 'berenjena', 'berro'],
      'bi': ['bicicleta', 'bien', 'billete', 'bicho', 'bigote', 'biblioteca', 'bistec', 'bizcocho', 'bisonte'],
      'bo': ['boca', 'bola', 'bolso', 'botón', 'bota', 'bolígrafo', 'bosque', 'botella', 'bomba'],
      'bu': ['búho', 'burro', 'bueno', 'bufanda', 'burbuja', 'buque', 'buzo', 'buitre', 'burla'],
      'da': ['dado', 'dama', 'danza', 'dar', 'dardo', 'dato', 'dátil', 'daño', 'debate'],
      'de': ['dedo', 'delantal', 'delfín', 'dentista', 'deporte', 'derecha', 'desayuno', 'desierto', 'despacio'],
      'di': ['dinero', 'diente', 'diez', 'día', 'dinosaurio', 'dibujo', 'difícil', 'disco', 'disfraz'],
      'do': ['dos', 'dolor', 'domingo', 'dormir', 'dominó', 'doctor', 'documento', 'dorado', 'dona'],
      'du': ['ducha', 'dulce', 'duda', 'dueño', 'duende', 'duque', 'duro', 'duelo', 'duplicado'],
      'fa': ['faro', 'falda', 'familia', 'farmacia', 'fantasma', 'favor', 'fábrica', 'fácil', 'fama'],
      'fe': ['feliz', 'feo', 'feria', 'fecha', 'féretro', 'ferrocarril', 'festivo', 'fetiche', 'feto'],
      'fi': ['fiebre', 'fiesta', 'figura', 'fila', 'fino', 'firma', 'física', 'fijo', 'filtro'],
      'fo': ['foca', 'foto', 'foco', 'fogata', 'fondo', 'forma', 'fórmula', 'foro', 'fosa'],
      'fu': ['fuego', 'fuerte', 'fútbol', 'furgoneta', 'fumar', 'función', 'funda', 'funeral', 'furia'],
      'ga': ['gato', 'gallina', 'gafas', 'galleta', 'garaje', 'gamba', 'ganso', 'ganar', 'garra'],
      'go': ['gol', 'goma', 'gorila', 'gorra', 'gota', 'gobierno', 'golpe', 'gordo', 'goloso'],
      'gu': ['guante', 'guitarra', 'gusano', 'guerra', 'guía', 'guapo', 'guardia', 'gusto', 'guisante'],
      'ra': ['ratón', 'rana', 'radio', 'rápido', 'ramo', 'rayo', 'raíz', 'rama', 'rape'],
      're': ['regalo', 'rey', 'reloj', 'red', 'regla', 'reina', 'reír', 'resto', 'revista'],
      'ri': ['río', 'risa', 'rico', 'rizo', 'rifle', 'riña', 'ritmo', 'rincón', 'riñón'],
      'ro': ['rosa', 'rojo', 'ropa', 'rodilla', 'romero', 'robo', 'robot', 'roca', 'rollo'],
      'ru': ['rueda', 'rubio', 'ruido', 'ruta', 'rugby', 'rulo', 'rumor', 'rural', 'ruso'],
    };

    // Lista de palabras comunes que terminan con cada sílaba
    final wordsEndMap = {
      'pa': ['sopa', 'tapa', 'lupa', 'ropa', 'copa', 'mapa', 'capa', 'pipa', 'rapa'],
      'pe': ['tape', 'golpe', 'equipaje', 'paisaje', 'traje', 'viaje', 'aje', 'coche', 'noche'],
      'ta': ['gata', 'pata', 'lata', 'rata', 'plata', 'bata', 'tarta', 'carta', 'maleta'],
      'te': ['tomate', 'chocolate', 'cacahuete', 'cohete', 'juguete', 'paquete', 'billete', 'machete', 'lete'],
      'to': ['gato', 'pato', 'plato', 'zapato', 'rato', 'contrato', 'rato', 'trato', 'rato'],
      'ma': ['cama', 'rama', 'llama', 'dama', 'fama', 'gama', 'drama', 'tema', 'problema'],
      'mo': ['humo', 'remo', 'gusano', 'timo', 'ramo', 'mimo', 'ritmo', 'primo', 'último'],
      'no': ['mono', 'pino', 'vino', 'mano', 'piano', 'grano', 'plano', 'verano', 'hermano'],
      'na': ['rana', 'lana', 'banana', 'ventana', 'manzana', 'campana', 'semana', 'niña', 'montaña'],
      'ne': ['cine', 'tren', 'sartén', 'ratón', 'melón', 'jamón', 'avión', 'león', 'camión'],
      'sa': ['casa', 'mesa', 'fresa', 'Teresa', 'princesa', 'taza', 'rosa', 'cosa', 'blusa'],
      'so': ['oso', 'paso', 'queso', 'peso', 'beso', 'hueso', 'vaso', 'caso', 'payaso'],
      'la': ['bola', 'cola', 'hola', 'ola', 'muela', 'escuela', 'tela', 'vela', 'abuela'],
      'lo': ['pelo', 'palo', 'malo', 'regalo', 'palo', 'abuelo', 'suelo', 'cielo', 'vuelo'],
      'ra': ['pera', 'cera', 'era', 'tijera', 'bandera', 'carrera', 'manera', 'primavera', 'calavera'],
      'ro': ['perro', 'carro', 'burro', 'tarro', 'churro', 'orro', 'gorro', 'hierro', 'cerro'],
      'ca': ['vaca', 'boca', 'foca', 'barba', 'marca', 'parca', 'mosca', 'charca', 'barca'],
      'co': ['saco', 'taco', 'pico', 'rico', 'poco', 'loco', 'blanco', 'flaco', 'banco'],
    };

    final syllableLower = syllable.toLowerCase();
    final words = syllablePosition == 'start'
        ? (wordsStartMap[syllableLower] ?? [])
        : (wordsEndMap[syllableLower] ?? []);

    if (words.isEmpty) {
      // Si no hay palabras predefinidas, retornar solo el título
      return result;
    }

    // Limitar al número máximo de palabras
    final selectedWords = words.take(maxWords).toList();

    // Buscar pictogramas en ARASAAC
    final pictograms = <ArasaacImage>[];
    for (final word in selectedWords) {
      final searchResults = await arasaacService.searchPictograms(word);
      if (searchResults.isNotEmpty) {
        pictograms.add(searchResults.first);
      }
    }

    if (pictograms.isEmpty) {
      return result;
    }

    // Organizar en cuadrícula 3x3
    final cols = 3;
    final cellSize = 140.0;
    final gap = 20.0;
    final textHeight = 40.0;

    final gridWidth = cols * cellSize + (cols - 1) * gap;
    final gridStartX = (canvasWidth - gridWidth) / 2;
    final gridStartY = margin + 60;

    for (int i = 0; i < pictograms.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final xPos = gridStartX + col * (cellSize + gap);
      final yPos = gridStartY + row * (cellSize + gap + textHeight);

      final pictogram = pictograms[i];
      final word = selectedWords[i];

      // Añadir tarjeta de pictograma (imagen + texto)
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
    }

    return result;
  }

  /// Generador de actividad de campo semántico: busca palabras relacionadas del mismo campo semántico.
  static Future<List<CanvasImage>> generateSemanticFieldActivity({
    required List<CanvasImage> canvasImages,
    required ArasaacService arasaacService,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
  }) async {
    final images = canvasImages.where((element) =>
        element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.pictogramCard).toList();

    if (images.isEmpty) return [];

    final result = <CanvasImage>[];
    final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
    final margin = 40.0;

    // Obtener la palabra clave del primer elemento
    String? searchKeyword;
    int? pictogramId;

    if (images.first.type == CanvasElementType.pictogramCard) {
      searchKeyword = images.first.text?.toLowerCase();
    } else if (images.first.type == CanvasElementType.networkImage) {
      // Extraer el ID del pictograma de la URL
      final url = images.first.imageUrl;
      if (url != null) {
        final match = RegExp(r'/pictograms/(\d+)').firstMatch(url);
        if (match != null) {
          pictogramId = int.tryParse(match.group(1)!);
        }
      }
    }

    // Si tenemos un ID de pictograma pero no palabra clave, obtener la primera keyword
    if (pictogramId != null && (searchKeyword == null || searchKeyword.isEmpty)) {
      try {
        final detailUrl = '${ArasaacService.baseUrl}/pictograms/${arasaacService.config.language}/$pictogramId';
        final response = await http.get(Uri.parse(detailUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final keywords = (data['keywords'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          if (keywords.isNotEmpty) {
            searchKeyword = keywords.first['keyword'] as String?;
          }
        }
      } catch (e) {
        print('DEBUG: Error obteniendo keyword del pictograma: $e');
      }
    }

    // Si no tenemos palabra clave, retornar vacío
    if (searchKeyword == null || searchKeyword.isEmpty) {
      result.add(
        CanvasImage.text(
          id: 'no_keyword',
          text: 'No se pudo obtener la palabra clave del pictograma',
          position: Offset(margin, margin + 60),
          fontSize: 16,
          textColor: Colors.orange,
          fontFamily: 'Roboto',
          scale: 1.0,
        ),
      );
      return result;
    }

    print('DEBUG: Buscando palabras relacionadas para: $searchKeyword');

    // Usar categorías para obtener palabras relacionadas del mismo campo semántico
    List<String> relatedWords = await arasaacService.getRelatedWords(searchKeyword);

    // Si aún no hay palabras relacionadas, retornar vacío
    if (relatedWords.isEmpty) {
      result.add(
        CanvasImage.text(
          id: 'no_wordnet',
          text: 'No se encontraron palabras relacionadas en WordNet para: $searchKeyword',
          position: Offset(margin, margin + 60),
          fontSize: 16,
          textColor: Colors.orange,
          fontFamily: 'Roboto',
          scale: 1.0,
        ),
      );
      return result;
    }

    // Título
    result.add(
      CanvasImage.text(
        id: 'semantic_title',
        text: 'Campo semántico: ${searchKeyword.toUpperCase()}',
        position: Offset(margin, margin),
        fontSize: 22,
        textColor: Colors.black,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );

    // Buscar pictogramas en ARASAAC para las 25 palabras (5x5)
    final maxWords = 25;
    final selectedWords = relatedWords.take(maxWords).toList();

    final pictograms = <ArasaacImage>[];
    final foundWords = <String>[];

    for (final word in selectedWords) {
      final searchResults = await arasaacService.searchPictograms(word);
      if (searchResults.isNotEmpty) {
        pictograms.add(searchResults.first);
        foundWords.add(word);
      }
    }

    if (pictograms.isEmpty) {
      result.add(
        CanvasImage.text(
          id: 'no_results',
          text: 'No se encontraron palabras relacionadas en ARASAAC',
          position: Offset(margin, margin + 60),
          fontSize: 16,
          textColor: Colors.red,
          fontFamily: 'Roboto',
          scale: 1.0,
        ),
      );
      return result;
    }

    // Organizar en cuadrícula 5x5
    final cols = 5;
    final cellSize = 100.0;
    final gap = 12.0;
    final textHeight = 30.0;

    final gridWidth = cols * cellSize + (cols - 1) * gap;
    final gridStartX = (canvasWidth - gridWidth) / 2;
    final gridStartY = margin + 60;

    for (int i = 0; i < pictograms.length && i < 25; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final xPos = gridStartX + col * (cellSize + gap);
      final yPos = gridStartY + row * (cellSize + gap + textHeight);

      final pictogram = pictograms[i];
      final word = foundWords[i];

      // Añadir tarjeta de pictograma (imagen + texto)
      result.add(
        CanvasImage.pictogramCard(
          id: 'pictogram_$i',
          imageUrl: pictogram.imageUrl,
          text: word,
          position: Offset(xPos, yPos),
          scale: 1.0,
          fontSize: 14,
          textColor: Colors.black,
        ).copyWith(width: cellSize, height: cellSize + textHeight),
      );
    }

    return result;
  }
}
