import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/canvas_image.dart';
import '../utils/syllables_helper.dart';

class PhonologicalAwarenessResult {
  final List<List<CanvasImage>> pages;
  final String message;

  PhonologicalAwarenessResult({required this.pages, required this.message});
}

/// Genera actividad de conciencia fonológica
/// Muestra imágenes con sus sílabas debajo
Future<PhonologicalAwarenessResult> generatePhonologicalAwarenessActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  String fontFamily = 'ColeCarreira',
  bool uppercase = true,
  int imagesPerPage = 8,
  bool showWord = true,
  bool showSyllables = true,
  bool showLetters = false,
  String projectName = '',
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
    return PhonologicalAwarenessResult(
      pages: [[]],
      message: 'Añade al menos una imagen primero',
    );
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  // Calcular filas y columnas según el número de imágenes
  int cols, rows;
  switch (imagesPerPage) {
    case 2:
      cols = 1;
      rows = 2;
      break;
    case 4:
      cols = 2;
      rows = 2;
      break;
    case 6:
      cols = 2;
      rows = 3;
      break;
    case 8:
    default:
      cols = 2;
      rows = 4;
      break;
  }

  const margin = 40.0;
  final cellWidth = (canvasWidth - margin * 2) / cols;
  final cellHeight = (canvasHeight - margin * 2) / rows;

  // Dividir imágenes en páginas
  final totalPages = (selectable.length / imagesPerPage).ceil();
  final pages = <List<CanvasImage>>[];

  // Página inicial con el nombre del proyecto (si existe)
  debugPrint('DEBUG: projectName recibido = "$projectName"');
  final titleElements = <CanvasImage>[];

  if (projectName.isNotEmpty) {
    final titleText = uppercase ? projectName.toUpperCase() : projectName;
    // Calcular posición centrada aproximadamente
    final titleWidthApprox = titleText.length * 25.0;
    final titleX = (canvasWidth - titleWidthApprox) / 2;

    titleElements.add(
      CanvasImage.text(
        id: 'project_name',
        text: titleText,
        position: Offset(
          titleX.clamp(50, canvasWidth - 100),
          canvasHeight / 2 - 50,
        ),
        fontSize: 48.0,
        textColor: Colors.blue.shade700,
        isBold: true,
        fontFamily: fontFamily,
      ),
    );
  }

  // Siempre añadir el subtítulo
  final subtitleText = 'Conciencia Fonológica';
  final subtitleWidthApprox = subtitleText.length * 17.0;
  final subtitleX = (canvasWidth - subtitleWidthApprox) / 2;

  titleElements.add(
    CanvasImage.text(
      id: 'subtitle',
      text: subtitleText,
      position: Offset(
        subtitleX.clamp(50, canvasWidth - 100),
        projectName.isNotEmpty ? canvasHeight / 2 + 20 : canvasHeight / 2,
      ),
      fontSize: 32.0,
      textColor: Colors.black87,
      isBold: false,
      fontFamily: fontFamily,
    ),
  );

  pages.add(titleElements);

  for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final pageElements = <CanvasImage>[];
    final startIdx = pageIndex * imagesPerPage;
    final endIdx = (startIdx + imagesPerPage).clamp(0, selectable.length);
    final pageImages = selectable.sublist(startIdx, endIdx);

    // Procesar cada imagen de esta página
    for (int i = 0; i < pageImages.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final cellX = margin + col * cellWidth;
      final cellY = margin + row * cellHeight;

      final originalImage = pageImages[i];

      // Calcular dimensiones de imagen según espacio disponible
      // Escalar más agresivamente cuando hay menos imágenes
      double imageSize;
      switch (imagesPerPage) {
        case 2:
          imageSize = (cellWidth * 0.85).clamp(120.0, 250.0);
          break;
        case 4:
          imageSize = (cellWidth * 0.8).clamp(100.0, 200.0);
          break;
        case 6:
          imageSize = (cellWidth * 0.75).clamp(90.0, 170.0);
          break;
        case 8:
        default:
          imageSize = (cellWidth * 0.7).clamp(80.0, 150.0);
          break;
      }
      final imageX = cellX + (cellWidth - imageSize) / 2;
      final imageY = cellY + 10;

      // Añadir imagen
      if (originalImage.type == CanvasElementType.pictogramCard ||
          originalImage.type == CanvasElementType.networkImage) {
        pageElements.add(
          CanvasImage.networkImage(
            id: 'img_${pageIndex}_$i',
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

          double currentY = imageY + imageSize + 10;
          const lineSpacing = 25.0;

          // 1. Mostrar palabra completa si está marcado
          if (showWord) {
            final wordText = uppercase
                ? palabra.toUpperCase()
                : palabra.toLowerCase();
            // Centrar texto respecto a la celda (no solo a la imagen)
            final textX = cellX + (cellWidth - imageSize) / 2;
            pageElements.add(
              CanvasImage.text(
                id: 'word_${pageIndex}_$i',
                text: wordText,
                position: Offset(textX, currentY),
                fontSize: 18.0,
                textColor: Colors.black,
                isBold: false,
                fontFamily: fontFamily,
              ).copyWith(width: imageSize),
            );
            currentY += lineSpacing;
          }

          // 2. Mostrar sílabas separadas si está marcado
          if (showSyllables && silabas.isNotEmpty) {
            final syllableSpacing = 0.5; // Espaciado muy reducido
            final totalSyllablesWidth = imageSize;
            final syllableWidth =
                (totalSyllablesWidth -
                    (syllableSpacing * (silabas.length - 1))) /
                silabas.length;
            final textStartX = cellX + (cellWidth - imageSize) / 2;

            for (int j = 0; j < silabas.length; j++) {
              final syllableX =
                  textStartX + (j * (syllableWidth + syllableSpacing));
              final syllableText = uppercase
                  ? silabas[j].toUpperCase()
                  : silabas[j].toLowerCase();

              pageElements.add(
                CanvasImage.text(
                  id: 'syllable_${pageIndex}_${i}_$j',
                  text: syllableText,
                  position: Offset(syllableX, currentY),
                  fontSize: 18.0,
                  textColor: Colors.black,
                  isBold: false,
                  fontFamily: fontFamily,
                ).copyWith(width: syllableWidth),
              );
            }
            currentY += lineSpacing;
          }

          // 3. Mostrar letras separadas si está marcado
          if (showLetters) {
            final letters = palabra.split('');
            final letterSpacing = 0.5; // Espaciado muy reducido
            final totalLettersWidth = imageSize;
            final letterWidth =
                (totalLettersWidth - (letterSpacing * (letters.length - 1))) /
                letters.length;
            final textStartX = cellX + (cellWidth - imageSize) / 2;

            for (int j = 0; j < letters.length; j++) {
              final letterX = textStartX + (j * (letterWidth + letterSpacing));
              final letterText = uppercase
                  ? letters[j].toUpperCase()
                  : letters[j].toLowerCase();

              pageElements.add(
                CanvasImage.text(
                  id: 'letter_${pageIndex}_${i}_$j',
                  text: letterText,
                  position: Offset(letterX, currentY),
                  fontSize: 18.0,
                  textColor: Colors.black,
                  isBold: false,
                  fontFamily: fontFamily,
                ).copyWith(width: letterWidth),
              );
            }
          }
        }
      } else if (originalImage.type == CanvasElementType.localImage) {
        pageElements.add(
          CanvasImage.localImage(
            id: 'img_${pageIndex}_$i',
            imagePath: originalImage.imagePath!,
            position: Offset(imageX, imageY),
            scale: 1.0,
          ).copyWith(width: imageSize, height: imageSize),
        );

        // Para imágenes locales, mostrar mensaje
        pageElements.add(
          CanvasImage.text(
            id: 'local_msg_${pageIndex}_$i',
            text: '(Sílabas no disponibles\npara imágenes locales)',
            position: Offset(cellX + 10, imageY + imageSize + 10),
            fontSize: 12.0,
            textColor: Colors.grey,
          ).copyWith(width: cellWidth - 20),
        );
      }
    }

    pages.add(pageElements);
  }

  return PhonologicalAwarenessResult(
    pages: pages,
    message:
        'Actividad de conciencia fonológica generada con ${selectable.length} palabra(s) en ${totalPages + 1} página(s) (incluyendo portada)',
  );
}

/// Genera un tablero fonológico como el de la referencia (tablero + recortables)
/// Una página con la plantilla y otra con las piezas recortables por palabra
Future<PhonologicalAwarenessResult> generatePhonologicalBoardActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
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
    return PhonologicalAwarenessResult(
      pages: [[]],
      message: 'Añade al menos una imagen primero',
    );
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  final pages = <List<CanvasImage>>[];

  // Usar la primera palabra como referencia para el tablero
  final baseWordData = await _resolveWordData(
    selectable.first,
    uppercase: uppercase,
  );

  pages.add(
    _buildBoardTemplatePage(
      index: 0,
      wordText: baseWordData.wordText,
      syllables: baseWordData.syllables,
      letters: baseWordData.letters,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      fontFamily: fontFamily,
    ),
  );

  for (int index = 0; index < selectable.length; index++) {
    final originalImage = selectable[index];
    final wordData = await _resolveWordData(
      originalImage,
      uppercase: uppercase,
    );

    pages.add(
      _buildCutoutsPage(
        index: index,
        image: originalImage,
        wordText: wordData.wordText,
        syllables: wordData.syllables,
        letters: wordData.letters,
        canvasWidth: canvasWidth,
        canvasHeight: canvasHeight,
        fontFamily: fontFamily,
      ),
    );
  }

  return PhonologicalAwarenessResult(
    pages: pages,
    message:
        'Tablero fonológico generado + ${selectable.length} página(s) de recortables',
  );
}

class _WordData {
  final String wordText;
  final List<String> syllables;
  final List<String> letters;

  _WordData({
    required this.wordText,
    required this.syllables,
    required this.letters,
  });
}

Future<_WordData> _resolveWordData(
  CanvasImage image, {
  required bool uppercase,
}) async {
  String palabra = '';
  if (image.type == CanvasElementType.pictogramCard ||
      image.type == CanvasElementType.networkImage) {
    final pictogramId = _extractIdFromUrl(image.imageUrl ?? '');
    if (pictogramId != null) {
      palabra = await _getPictogramName(pictogramId);
    }
  }

  final fallbackWord = uppercase ? 'PALABRA' : 'palabra';
  final wordText = palabra.isEmpty
      ? fallbackWord
      : (uppercase ? palabra.toUpperCase() : palabra.toLowerCase());

  final silabasStr = palabra.isNotEmpty
      ? await SyllablesHelper.obtenerSilabas(palabra)
      : '';
  final silabas =
      (silabasStr.isEmpty
              ? <String>[palabra.isEmpty ? fallbackWord : palabra]
              : SyllablesHelper.separarSilabas(silabasStr))
          .map((s) => uppercase ? s.toUpperCase() : s.toLowerCase())
          .toList();

  final letters = (palabra.isEmpty ? fallbackWord : palabra)
      .split('')
      .map((l) => uppercase ? l.toUpperCase() : l.toLowerCase())
      .toList();

  return _WordData(wordText: wordText, syllables: silabas, letters: letters);
}

List<CanvasImage> _buildBoardTemplatePage({
  required int index,
  required String wordText,
  required List<String> syllables,
  required List<String> letters,
  required double canvasWidth,
  required double canvasHeight,
  required String fontFamily,
}) {
  final elements = <CanvasImage>[];
  const margin = 28.0;
  const gap = 18.0;
  const slotHeight = 52.0;

  final boardWidth = canvasWidth - margin * 2;
  final boardHeight = canvasHeight - margin * 2;
  final boardX = margin;
  final boardY = margin;

  elements.add(
    CanvasImage.shape(
      id: 'board_outline_$index',
      shapeType: ShapeType.rectangle,
      position: Offset(boardX, boardY),
      width: boardWidth,
      height: boardHeight,
      shapeColor: Colors.orange[600]!,
      strokeWidth: 4.0,
    ),
  );

  final puzzleSize = math.min(boardWidth * 0.7, boardHeight * 0.36);
  final puzzleX = boardX + (boardWidth - puzzleSize) / 2;
  final puzzleY = boardY + 24;

  elements.add(
    CanvasImage.shape(
      id: 'board_puzzle_frame_$index',
      shapeType: ShapeType.rectangle,
      position: Offset(puzzleX, puzzleY),
      width: puzzleSize,
      height: puzzleSize,
      shapeColor: Colors.grey[700]!,
      strokeWidth: 2.5,
      isDashed: true,
    ),
  );

  elements.add(
    CanvasImage.shape(
      id: 'board_puzzle_v_$index',
      shapeType: ShapeType.line,
      position: Offset(puzzleX + puzzleSize / 2, puzzleY),
      width: 0,
      height: puzzleSize,
      shapeColor: Colors.grey[600]!,
      strokeWidth: 2,
      isDashed: true,
    ),
  );

  elements.add(
    CanvasImage.shape(
      id: 'board_puzzle_h_$index',
      shapeType: ShapeType.line,
      position: Offset(puzzleX, puzzleY + puzzleSize / 2),
      width: puzzleSize,
      height: 0,
      shapeColor: Colors.grey[600]!,
      strokeWidth: 2,
      isDashed: true,
    ),
  );

  double currentY = puzzleY + puzzleSize + gap;
  final wordSlotWidth = math.min(boardWidth * 0.7, 380.0);
  final wordSlotX = boardX + (boardWidth - wordSlotWidth) / 2;

  elements.add(
    CanvasImage.shape(
      id: 'board_word_slot_$index',
      shapeType: ShapeType.rectangle,
      position: Offset(wordSlotX, currentY),
      width: wordSlotWidth,
      height: slotHeight,
      shapeColor: Colors.green[700]!,
      strokeWidth: 3,
      isDashed: true,
    ),
  );

  currentY += slotHeight + gap;

  final syllableCount = syllables.isEmpty ? 2 : syllables.length;
  final syllableRowWidth = math.min(
    boardWidth * 0.82,
    canvasWidth - margin * 2,
  );
  final syllableGap = 10.0;
  final syllableWidth =
      (syllableRowWidth - (syllableGap * (syllableCount - 1))) / syllableCount;
  final syllableStartX = boardX + (boardWidth - syllableRowWidth) / 2;

  for (int i = 0; i < syllableCount; i++) {
    final syllableX = syllableStartX + i * (syllableWidth + syllableGap);
    elements.add(
      CanvasImage.shape(
        id: 'board_syllable_slot_${index}_$i',
        shapeType: ShapeType.rectangle,
        position: Offset(syllableX, currentY),
        width: syllableWidth,
        height: slotHeight,
        shapeColor: Colors.blue[700]!,
        strokeWidth: 3,
        isDashed: true,
      ),
    );
  }

  currentY += slotHeight + gap;

  final letterCount = letters.isEmpty ? wordText.length : letters.length;
  final letterRowWidth = math.min(boardWidth * 0.84, canvasWidth - margin * 2);
  final letterGap = 6.0;
  final letterWidth =
      (letterRowWidth - (letterGap * (math.max(letterCount, 1) - 1))) /
      math.max(letterCount, 1);
  final letterStartX = boardX + (boardWidth - letterRowWidth) / 2;

  for (int i = 0; i < letterCount; i++) {
    final letterX = letterStartX + i * (letterWidth + letterGap);
    elements.add(
      CanvasImage.shape(
        id: 'board_letter_slot_${index}_$i',
        shapeType: ShapeType.rectangle,
        position: Offset(letterX, currentY),
        width: letterWidth,
        height: slotHeight,
        shapeColor: Colors.red[700]!,
        strokeWidth: 3,
        isDashed: true,
      ),
    );
  }

  currentY += slotHeight + gap;

  final writingWidth = math.min(boardWidth * 0.86, 420.0);
  final writingX = boardX + (boardWidth - writingWidth) / 2;

  elements.add(
    CanvasImage.shape(
      id: 'board_writing_slot_$index',
      shapeType: ShapeType.rectangle,
      position: Offset(writingX, currentY),
      width: writingWidth,
      height: slotHeight + 6,
      shapeColor: Colors.purple[400]!,
      strokeWidth: 3,
      isDashed: true,
    ),
  );

  return elements;
}

List<CanvasImage> _buildCutoutsPage({
  required int index,
  required CanvasImage image,
  required String wordText,
  required List<String> syllables,
  required List<String> letters,
  required double canvasWidth,
  required double canvasHeight,
  required String fontFamily,
}) {
  final elements = <CanvasImage>[];
  const margin = 28.0;
  const cardHeight = 50.0;
  const rowGap = 18.0;
  double _centerX(String text, double width, double fontSize) {
    final estimated = text.length * fontSize * 0.55;
    return (width - estimated) / 2;
  }
  double _centerY(double boxHeight, double fontSize) {
    const lineHeightFactor = 1.1;
    return (boxHeight - fontSize * lineHeightFactor) / 2;
  }

  elements.add(
    CanvasImage.text(
      id: 'cutouts_label_$index',
      text: '',
      position: const Offset(20, 20),
      fontSize: 20,
      textColor: Colors.grey[700]!,
      fontFamily: fontFamily,
      isBold: true,
    ),
  );

  final puzzleSize = math.min(canvasWidth - margin * 2, canvasHeight * 0.42);
  final puzzleX = (canvasWidth - puzzleSize) / 2;
  final puzzleY = margin + 10;

  if (image.type == CanvasElementType.localImage) {
    elements.add(
      CanvasImage.localImage(
        id: 'cutout_base_$index',
        imagePath: image.imagePath ?? '',
        position: Offset(puzzleX, puzzleY),
      ).copyWith(width: puzzleSize, height: puzzleSize),
    );
  } else {
    elements.add(
      CanvasImage.networkImage(
        id: 'cutout_base_$index',
        imageUrl: image.imageUrl ?? '',
        position: Offset(puzzleX, puzzleY),
      ).copyWith(width: puzzleSize, height: puzzleSize),
    );
  }

  elements.add(
    CanvasImage.shape(
      id: 'cutout_border_$index',
      shapeType: ShapeType.rectangle,
      position: Offset(puzzleX, puzzleY),
      width: puzzleSize,
      height: puzzleSize,
      shapeColor: Colors.grey[800]!,
      strokeWidth: 2.0,
      isDashed: true,
    ),
  );

  elements.add(
    CanvasImage.shape(
      id: 'cutout_v_$index',
      shapeType: ShapeType.line,
      position: Offset(puzzleX + puzzleSize / 2, puzzleY),
      width: 0,
      height: puzzleSize,
      shapeColor: Colors.grey[800]!,
      strokeWidth: 2.0,
      isDashed: true,
    ),
  );

  elements.add(
    CanvasImage.shape(
      id: 'cutout_h_$index',
      shapeType: ShapeType.line,
      position: Offset(puzzleX, puzzleY + puzzleSize / 2),
      width: puzzleSize,
      height: 0,
      shapeColor: Colors.grey[800]!,
      strokeWidth: 2.0,
      isDashed: true,
    ),
  );

  double currentY = puzzleY + puzzleSize + rowGap;
  final rowWidth = math.min(canvasWidth - margin * 2, 420.0);
  final rowX = (canvasWidth - rowWidth) / 2;

  elements.add(
    CanvasImage.shape(
      id: 'cutout_word_$index',
      shapeType: ShapeType.rectangle,
      position: Offset(rowX, currentY),
      width: rowWidth,
      height: cardHeight,
      shapeColor: Colors.green[700]!,
      strokeWidth: 3,
    ),
  );

  elements.add(
    CanvasImage.text(
      id: 'cutout_word_text_$index',
      text: wordText,
      position: Offset(
        rowX,
        currentY + _centerY(cardHeight, 26),
      ),
      fontSize: 26,
      textColor: Colors.black,
      fontFamily: fontFamily,
      isBold: true,
    ).copyWith(width: rowWidth),
  );

  currentY += cardHeight + rowGap;

  final syllableCount = syllables.isEmpty ? 2 : syllables.length;
  final syllableGap = 10.0;
  final syllableWidth =
      (rowWidth - syllableGap * (syllableCount - 1)) / syllableCount;
  for (int i = 0; i < syllableCount; i++) {
    final syllableX = rowX + i * (syllableWidth + syllableGap);
    final text = i < syllables.length ? syllables[i] : '';

    elements.add(
      CanvasImage.shape(
        id: 'cutout_syllable_${index}_$i',
        shapeType: ShapeType.rectangle,
        position: Offset(syllableX, currentY),
        width: syllableWidth,
        height: cardHeight,
        shapeColor: Colors.blue[700]!,
        strokeWidth: 3,
      ),
    );

    if (text.isNotEmpty) {
      elements.add(
        CanvasImage.text(
          id: 'cutout_syllable_text_${index}_$i',
          text: text,
          position: Offset(
            syllableX,
            currentY + _centerY(cardHeight, 22),
          ),
          fontSize: 22,
          textColor: Colors.black,
          fontFamily: fontFamily,
        ).copyWith(width: syllableWidth),
      );
    }
  }

  currentY += cardHeight + rowGap;

  final letterCount = letters.isEmpty ? wordText.length : letters.length;
  final letterGap = 6.0;
  final letterWidth =
      (rowWidth - letterGap * (math.max(letterCount, 1) - 1)) /
      math.max(letterCount, 1);

  for (int i = 0; i < letterCount; i++) {
    final letterX = rowX + i * (letterWidth + letterGap);
    final text = i < letters.length ? letters[i] : '';

    elements.add(
      CanvasImage.shape(
        id: 'cutout_letter_${index}_$i',
        shapeType: ShapeType.rectangle,
        position: Offset(letterX, currentY),
        width: letterWidth,
        height: cardHeight,
        shapeColor: Colors.red[700]!,
        strokeWidth: 3,
      ),
    );

    if (text.isNotEmpty) {
      elements.add(
        CanvasImage.text(
          id: 'cutout_letter_text_${index}_$i',
          text: text,
          position: Offset(
            letterX,
            currentY + _centerY(cardHeight, 22),
          ),
          fontSize: 22,
          textColor: Colors.black,
          fontFamily: fontFamily,
          isBold: true,
        ).copyWith(width: letterWidth),
      );
    }
  }

  currentY += cardHeight + rowGap;

  elements.add(
    CanvasImage.shape(
      id: 'cutout_writing_$index',
      shapeType: ShapeType.rectangle,
      position: Offset(rowX, currentY),
      width: rowWidth,
      height: cardHeight + 6,
      shapeColor: Colors.purple[400]!,
      strokeWidth: 3,
    ),
  );

  elements.add(
    CanvasImage.text(
      id: 'cutout_writing_label_$index',
      text: '',
      position: Offset(
        rowX,
        currentY + _centerY(cardHeight + 6, 20),
      ),
      fontSize: 20,
      textColor: Colors.black87,
      fontFamily: fontFamily,
    ).copyWith(width: rowWidth),
  );

  return elements;
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
