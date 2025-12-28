import 'package:flutter/material.dart';

import '../models/canvas_image.dart';

class PuzzleActivityResult {
  final List<CanvasImage> referencePage; // Página con la imagen completa de referencia
  final List<CanvasImage> piecesPage; // Página con las piezas recortables
  final String title;
  final String instructions;

  PuzzleActivityResult({
    required this.referencePage,
    required this.piecesPage,
    this.title = 'PUZLE',
    this.instructions = 'Recorta las piezas y forma la imagen',
  });
}

/// Genera una actividad de puzle con 2 páginas
///
/// - referencePage: Hoja con la imagen en sombra (escala de grises) como referencia
/// - piecesPage: Hoja con la imagen dividida en piezas con líneas de recorte
PuzzleActivityResult generatePuzzleActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  required int gridSize, // 2, 3, 4, etc. para nxn piezas
}) {
  final selectable = images
      .where((element) =>
          element.type == CanvasElementType.networkImage ||
          element.type == CanvasElementType.localImage ||
          element.type == CanvasElementType.pictogramCard)
      .toList();

  if (selectable.isEmpty) {
    return PuzzleActivityResult(referencePage: [], piecesPage: []);
  }

  final selectedImage = selectable.first;
  final pageWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final pageHeight = isLandscape ? a4WidthPts : a4HeightPts;

  String? imageUrl;
  String? imagePath;

  if (selectedImage.type == CanvasElementType.pictogramCard ||
      selectedImage.type == CanvasElementType.networkImage) {
    imageUrl = selectedImage.imageUrl;
  } else if (selectedImage.type == CanvasElementType.localImage) {
    imagePath = selectedImage.imagePath;
  }

  // ========== PÁGINA 1: IMAGEN DE REFERENCIA ==========
  final referencePage = <CanvasImage>[];

  // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
  // NO los agregamos aquí para evitar duplicación en el PDF

  // Tamaño de la imagen de referencia (más pequeña, centrada)
  final margin = 80.0;
  final refWidth = pageWidth - (margin * 2);
  final refHeight = pageHeight - (margin * 2);
  final refSize = refWidth < refHeight ? refWidth : refHeight;

  // Centrar la imagen
  final refX = (pageWidth - refSize) / 2;
  final refY = (pageHeight - refSize) / 2;

  // Añadir imagen de referencia en sombra (escala de grises/negro)
  if (imageUrl != null) {
    referencePage.add(
      CanvasImage.shadow(
        id: 'reference_shadow',
        imageUrl: imageUrl,
        position: Offset(refX, refY),
      ).copyWith(width: refSize, height: refSize),
    );
  } else if (imagePath != null) {
    // Para imágenes locales, usamos la imagen normal con overlay gris
    referencePage.add(
      CanvasImage.localImage(
        id: 'reference_image',
        imagePath: imagePath,
        position: Offset(refX, refY),
      ).copyWith(width: refSize, height: refSize),
    );
    // Añadir overlay gris semi-transparente
    referencePage.add(
      CanvasImage.shape(
        id: 'shadow_overlay',
        shapeType: ShapeType.rectangle,
        position: Offset(refX, refY),
        width: refSize,
        height: refSize,
        shapeColor: Colors.grey.withValues(alpha: 0.7),
      ),
    );
  }

  // Añadir líneas de división en la referencia (CONTINUAS, no discontinuas)
  final refRows = gridSize;
  final refCols = gridSize;
  final refPieceWidth = refSize / refCols;
  final refPieceHeight = refSize / refRows;

  // Líneas verticales (continuas)
  for (int i = 1; i < refCols; i++) {
    final x = refX + (i * refPieceWidth);
    referencePage.add(
      CanvasImage.shape(
        id: 'ref_vline_$i',
        shapeType: ShapeType.line,
        position: Offset(x, refY),
        width: 0,
        height: refSize,
        shapeColor: Colors.grey[800]!,
        strokeWidth: 2.0,
        isDashed: false, // Líneas continuas en página de referencia
      ),
    );
  }

  // Líneas horizontales (continuas)
  for (int i = 1; i < refRows; i++) {
    final y = refY + (i * refPieceHeight);
    referencePage.add(
      CanvasImage.shape(
        id: 'ref_hline_$i',
        shapeType: ShapeType.line,
        position: Offset(refX, y),
        width: refSize,
        height: 0,
        shapeColor: Colors.grey[800]!,
        strokeWidth: 2.0,
        isDashed: false, // Líneas continuas en página de referencia
      ),
    );
  }

  // Borde exterior en la referencia (continuo)
  referencePage.add(
    CanvasImage.shape(
      id: 'reference_border',
      shapeType: ShapeType.rectangle,
      position: Offset(refX - 2, refY - 2),
      width: refSize + 4,
      height: refSize + 4,
      shapeColor: Colors.grey[800]!,
      strokeWidth: 2.0,
      isDashed: false, // Borde continuo en página de referencia
    ),
  );

  // ========== PÁGINA 2: PIEZAS RECORTABLES ==========
  final piecesPage = <CanvasImage>[];

  // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
  // NO los agregamos aquí para evitar duplicación en el PDF

  // Calcular tamaño del puzzle para que quepa en la página
  final puzzleMargin = 60.0;
  final availableWidth = pageWidth - (puzzleMargin * 2);
  final availableHeight = pageHeight - (puzzleMargin * 2);
  final puzzleSize = availableWidth < availableHeight ? availableWidth : availableHeight;

  // Centrar el puzzle
  final puzzleX = (pageWidth - puzzleSize) / 2;
  final puzzleY = (pageHeight - puzzleSize) / 2;

  // Añadir la imagen completa (detrás de las líneas)
  if (imageUrl != null) {
    piecesPage.add(
      CanvasImage.networkImage(
        id: 'puzzle_base',
        imageUrl: imageUrl,
        position: Offset(puzzleX, puzzleY),
      ).copyWith(width: puzzleSize, height: puzzleSize),
    );
  } else if (imagePath != null) {
    piecesPage.add(
      CanvasImage.localImage(
        id: 'puzzle_base',
        imagePath: imagePath,
        position: Offset(puzzleX, puzzleY),
      ).copyWith(width: puzzleSize, height: puzzleSize),
    );
  }

  // Añadir líneas de corte (gridSize x gridSize)
  final rows = gridSize;
  final cols = gridSize;
  final pieceWidth = puzzleSize / cols;
  final pieceHeight = puzzleSize / rows;

  // Líneas verticales
  for (int i = 1; i < cols; i++) {
    final x = puzzleX + (i * pieceWidth);
    piecesPage.add(
      CanvasImage.shape(
        id: 'vline_$i',
        shapeType: ShapeType.line,
        position: Offset(x, puzzleY),
        width: 0,
        height: puzzleSize,
        shapeColor: Colors.grey[800]!,
        strokeWidth: 2.0,
        isDashed: true,
      ),
    );
  }

  // Líneas horizontales
  for (int i = 1; i < rows; i++) {
    final y = puzzleY + (i * pieceHeight);
    piecesPage.add(
      CanvasImage.shape(
        id: 'hline_$i',
        shapeType: ShapeType.line,
        position: Offset(puzzleX, y),
        width: puzzleSize,
        height: 0,
        shapeColor: Colors.grey[800]!,
        strokeWidth: 2.0,
        isDashed: true,
      ),
    );
  }

  // Borde exterior con línea punteada
  piecesPage.add(
    CanvasImage.shape(
      id: 'puzzle_border',
      shapeType: ShapeType.rectangle,
      position: Offset(puzzleX - 2, puzzleY - 2),
      width: puzzleSize + 4,
      height: puzzleSize + 4,
      shapeColor: Colors.grey[800]!,
      strokeWidth: 2.0,
      isDashed: true,
    ),
  );

  return PuzzleActivityResult(
    referencePage: referencePage,
    piecesPage: piecesPage,
  );
}
