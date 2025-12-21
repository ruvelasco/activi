import 'package:flutter/material.dart';

import '../models/canvas_image.dart';

class SymmetryActivityResult {
  final List<List<CanvasImage>> pages;
  final String message;
  final String title;
  final String instructions;

  SymmetryActivityResult({
    required this.pages,
    required this.message,
    this.title = 'SIMETRÍAS',
    this.instructions = 'Busca los objetos iguales al modelo',
  });
}

SymmetryActivityResult generateSymmetryActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
}) {
  final items = images.where((element) {
    return element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.localImage ||
        element.type == CanvasElementType.pictogramCard;
  }).toList();

  if (items.isEmpty) {
    return SymmetryActivityResult(pages: [[]], message: 'Añade al menos una imagen primero');
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  const margin = 40.0;
  const cellSize = 80.0;
  const gap = 8.0;
  const modelBoxSize = 130.0;
  const modelSize = 100.0;
  const gridPadding = 20.0;
  const templateHeaderSpace = 120.0; // Espacio para título (60pt) + instrucciones (50pt) + margen

  final pages = <List<CanvasImage>>[];

  for (int pageIndex = 0; pageIndex < items.length; pageIndex++) {
    final modelImage = items[pageIndex];
    final pageElements = <CanvasImage>[];

    final modelTransformSeed = DateTime.now().millisecondsSinceEpoch + pageIndex * 31;
    final availableTransforms = [
      {'rotation': 0.0, 'flipH': false, 'flipV': false},
      {'rotation': 90.0, 'flipH': false, 'flipV': false},
      {'rotation': 180.0, 'flipH': false, 'flipV': false},
      {'rotation': 270.0, 'flipH': false, 'flipV': false},
      {'rotation': 0.0, 'flipH': true, 'flipV': false},
      {'rotation': 0.0, 'flipH': false, 'flipV': true},
      {'rotation': 0.0, 'flipH': true, 'flipV': true},
      {'rotation': 90.0, 'flipH': true, 'flipV': false},
    ];
    final modelTransform = availableTransforms[modelTransformSeed % availableTransforms.length];

    // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
    // NO los agregamos aquí para evitar duplicación en el PDF

    // Comenzar el contenido después del espacio reservado para título/instrucciones
    final modelBoxY = templateHeaderSpace + margin;
    final modelBoxX = (canvasWidth - modelBoxSize) / 2;

    pageElements.add(
      CanvasImage.shape(
        id: 'model_box_$pageIndex',
        shapeType: ShapeType.rectangle,
        position: Offset(modelBoxX, modelBoxY),
        shapeColor: Colors.grey[700]!,
        strokeWidth: 3.0,
      ).copyWith(width: modelBoxSize, height: modelBoxSize),
    );

    final modelY = modelBoxY + (modelBoxSize - modelSize) / 2;
    final modelX = modelBoxX + (modelBoxSize - modelSize) / 2;

    if (modelImage.type == CanvasElementType.pictogramCard ||
        modelImage.type == CanvasElementType.networkImage) {
      pageElements.add(
        CanvasImage.networkImage(
          id: 'model_$pageIndex',
          imageUrl: modelImage.imageUrl ?? '',
          position: Offset(modelX, modelY),
          scale: 1.0,
        ).copyWith(width: modelSize, height: modelSize),
      );
    } else {
      pageElements.add(
        CanvasImage.localImage(
          id: 'model_$pageIndex',
          imagePath: modelImage.imagePath ?? '',
          position: Offset(modelX, modelY),
          scale: 1.0,
        ).copyWith(width: modelSize, height: modelSize),
      );
    }
    // Aplicar transformaciones al modelo
    pageElements[pageElements.length - 1] = pageElements.last.copyWith(
      rotation: modelTransform['rotation'] as double,
      flipHorizontal: modelTransform['flipH'] as bool,
      flipVertical: modelTransform['flipV'] as bool,
    );

    final gridStartY = modelBoxY + modelBoxSize + 30;
    final gridWidth = 5 * cellSize + 4 * gap;
    final gridHeight = 5 * cellSize + 4 * gap;
    final gridStartX = (canvasWidth - gridWidth) / 2;

    pageElements.add(
      CanvasImage.shape(
        id: 'grid_box_$pageIndex',
        shapeType: ShapeType.rectangle,
        position: Offset(gridStartX - gridPadding, gridStartY - gridPadding),
        shapeColor: Colors.grey[400]!,
        strokeWidth: 2.0,
      ).copyWith(
        width: gridWidth + 2 * gridPadding,
        height: gridHeight + 2 * gridPadding,
      ),
    );

    final randomSeed = DateTime.now().millisecondsSinceEpoch + pageIndex * 13;
    final gridTransformations = <Map<String, dynamic>>[];
    // Garantizar que el modelo tenga al menos una coincidencia exacta
    gridTransformations.add(modelTransform);
    gridTransformations.addAll(List.filled(3, {'rotation': 0.0, 'flipH': false, 'flipV': false}));
    for (int i = 4; i < 25; i++) {
      final index = (randomSeed + i * 7) % availableTransforms.length;
      gridTransformations.add(availableTransforms[index]);
    }
    gridTransformations.shuffle();

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
          pageElements.add(
            CanvasImage.networkImage(
              id: 'grid_${pageIndex}_${row}_$col',
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
          pageElements.add(
            CanvasImage.localImage(
              id: 'grid_${pageIndex}_${row}_$col',
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

    pages.add(pageElements);
  }

  return SymmetryActivityResult(
    pages: pages,
    message: 'Actividad de simetrías generada en ${pages.length} hoja(s)',
  );
}
