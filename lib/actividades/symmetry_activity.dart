import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import 'activity_result.dart';

GeneratedActivity generateSymmetryActivity({
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

  if (items.isEmpty) return GeneratedActivity(elements: []);

  final modelImage = items.first;
  final result = <CanvasImage>[];

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  const margin = 40.0;
  const cellSize = 80.0;
  const gap = 8.0;

  result.add(
    CanvasImage.text(
      id: 'symmetry_title',
      text: 'Busca los objetos iguales al modelo',
      position: const Offset(margin, margin),
      fontSize: 20,
      textColor: Colors.black,
      fontFamily: 'Roboto',
      scale: 1.0,
    ),
  );

  const modelBoxSize = 130.0;
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

  const modelSize = 100.0;
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

  final gridStartY = modelBoxY + modelBoxSize + 30;
  final gridWidth = 5 * cellSize + 4 * gap;
  final gridHeight = 5 * cellSize + 4 * gap;
  final gridStartX = (canvasWidth - gridWidth) / 2;

  const gridPadding = 20.0;
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

  final transformations = [
    {'rotation': 0.0, 'flipH': false, 'flipV': false},
    {'rotation': 90.0, 'flipH': false, 'flipV': false},
    {'rotation': 180.0, 'flipH': false, 'flipV': false},
    {'rotation': 270.0, 'flipH': false, 'flipV': false},
    {'rotation': 0.0, 'flipH': true, 'flipV': false},
    {'rotation': 0.0, 'flipH': false, 'flipV': true},
    {'rotation': 0.0, 'flipH': true, 'flipV': true},
    {'rotation': 90.0, 'flipH': true, 'flipV': false},
  ];

  final random = DateTime.now().millisecondsSinceEpoch;
  final gridTransformations = <Map<String, dynamic>>[];
  for (int i = 0; i < 4; i++) {
    gridTransformations
        .add({'rotation': 0.0, 'flipH': false, 'flipV': false});
  }
  for (int i = 4; i < 25; i++) {
    final index = (random + i * 7) % transformations.length;
    gridTransformations.add(transformations[index]);
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

  return GeneratedActivity(
    elements: result,
    message: 'Actividad de simetrías generada',
  );
}
