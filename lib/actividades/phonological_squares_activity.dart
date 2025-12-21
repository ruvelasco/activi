import 'package:flutter/material.dart';

import '../models/canvas_image.dart';

class PhonologicalSquaresResult {
  final List<List<CanvasImage>> pages;
  final String message;
  final String title;
  final String instructions;

  PhonologicalSquaresResult({
    required this.pages,
    required this.message,
    this.title = 'CUADRADOS FONOLÓGICOS',
    this.instructions = 'Pinta un cuadrado por cada letra',
  });
}

/// Genera actividad de cuadrados fonológicos
/// Muestra imágenes con un rectángulo de 10 cuadrados debajo para pintar
Future<PhonologicalSquaresResult> generatePhonologicalSquaresActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  String fontFamily = 'ColeCarreira',
  int imagesPerPage = 6,
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
    return PhonologicalSquaresResult(
      pages: [[]],
      message: 'Añade al menos una imagen primero',
    );
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  final pages = <List<CanvasImage>>[];

  // Espacio para título e instrucciones (mismo formato que otras actividades)
  const templateHeaderSpace = 120.0;
  const margin = 40.0;
  final availableHeight = canvasHeight - templateHeaderSpace - margin * 2;

  // Calcular dimensiones para las tarjetas
  const cols = 2;
  final rows = (imagesPerPage / cols).ceil();
  final cardWidth = (canvasWidth - margin * 2) / cols;
  final cardHeight = availableHeight / rows;

  // Dimensiones de los elementos dentro de cada tarjeta
  // Reducir el tamaño de la imagen para dejar espacio para los cuadrados
  final imageSize = cardWidth * 0.6;

  // Rectángulo de cuadrados: 2 filas x 5 columnas, mismo ancho que la imagen
  const squareCols = 5;
  const squareRows = 2;
  final squareSize = imageSize / squareCols; // Ancho de la imagen dividido entre 5 columnas
  final squaresWidth = imageSize; // Mismo ancho que la imagen
  final squaresHeight = squareSize * squareRows; // 2 filas

  // Dividir en páginas
  for (int pageIndex = 0; pageIndex * imagesPerPage < selectable.length; pageIndex++) {
    final pageElements = <CanvasImage>[];

    // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
    // NO los agregamos aquí para evitar duplicación en el PDF

    // Agregar imágenes con sus cuadrados
    final startIndex = pageIndex * imagesPerPage;
    final endIndex = (startIndex + imagesPerPage < selectable.length)
        ? startIndex + imagesPerPage
        : selectable.length;

    for (int i = startIndex; i < endIndex; i++) {
      final localIndex = i - startIndex;
      final row = localIndex ~/ cols;
      final col = localIndex % cols;

      final cellX = margin + col * cardWidth;
      final cellY = templateHeaderSpace + margin + row * cardHeight;

      final originalImage = selectable[i];

      // Centrar la imagen en su área
      final imageX = cellX + (cardWidth - imageSize) / 2;
      final imageY = cellY + 10;

      // Agregar imagen
      pageElements.add(
        CanvasImage(
          id: 'image_${pageIndex}_$localIndex',
          type: originalImage.type,
          position: Offset(imageX, imageY),
          width: imageSize,
          height: imageSize,
          imageUrl: originalImage.imageUrl,
          imagePath: originalImage.imagePath,
          webBytes: originalImage.webBytes,
          cachedImageBytes: originalImage.cachedImageBytes,
          text: originalImage.text,
          textColor: originalImage.textColor,
          fontSize: originalImage.fontSize,
          fontFamily: originalImage.fontFamily,
        ),
      );

      // Agregar rectángulo dividido en 10 cuadrados (2 filas x 5 columnas)
      final squaresX = cellX + (cardWidth - squaresWidth) / 2;
      final squaresY = imageY + imageSize + 10;

      // Dibujar 10 cuadrados en una cuadrícula de 2 filas x 5 columnas
      for (int squareIndex = 0; squareIndex < 10; squareIndex++) {
        final squareRow = squareIndex ~/ squareCols;
        final squareCol = squareIndex % squareCols;
        final squareX = squaresX + squareCol * squareSize;
        final squareY = squaresY + squareRow * squareSize;

        pageElements.add(
          CanvasImage.shape(
            id: 'square_${pageIndex}_${localIndex}_$squareIndex',
            shapeType: ShapeType.rectangle,
            position: Offset(squareX, squareY),
            width: squareSize,
            height: squareSize,
            shapeColor: Colors.black,
            strokeWidth: 2.0,
          ),
        );
      }
    }

    pages.add(pageElements);
  }

  return PhonologicalSquaresResult(
    pages: pages,
    message:
        'Actividad de cuadrados fonológicos generada con ${selectable.length} imagen(es) en ${pages.length} página(s)',
  );
}
