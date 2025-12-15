import 'dart:math';
import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import 'activity_result.dart';

class _PlacedObject {
  final CanvasImage source;
  final bool isTarget;

  _PlacedObject({required this.source, required this.isTarget});
}

GeneratedActivity generateInstructionsActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  int minTargets = 1,
  int maxTargets = 3,
}) {
  final selectable = images
      .where(
        (e) =>
            e.type == CanvasElementType.networkImage ||
            e.type == CanvasElementType.localImage ||
            e.type == CanvasElementType.pictogramCard,
      )
      .toList();

  if (selectable.isEmpty) {
    return GeneratedActivity(
      elements: [],
      message: 'Añade al menos una imagen primero',
    );
  }

  minTargets = minTargets.clamp(1, 10);
  maxTargets = maxTargets.clamp(1, 10);
  if (maxTargets < minTargets) maxTargets = minTargets;

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  const margin = 30.0;
  const imageSize = 70.0;
  const gap = 12.0;
  final cols = ((canvasWidth - 2 * margin) / (imageSize + gap)).floor().clamp(
    2,
    8,
  );
  final rows = ((canvasHeight - margin - 140) / (imageSize + gap))
      .floor()
      .clamp(2, 10);
  final capacity = cols * rows;

  final random = Random();
  selectable.shuffle(random);

  // Tomar hasta 4 tipos de objetivo para no saturar el título
  final targets = selectable.take(4).toList();
  final counts = <CanvasImage, int>{};
  for (final img in targets) {
    counts[img] = random.nextInt(maxTargets - minTargets + 1) + minTargets;
  }

  // Preparar todos los objetos objetivo (repetidos según cantidad)
  final targetObjects = <_PlacedObject>[];
  counts.forEach((img, qty) {
    for (int i = 0; i < qty; i++) {
      targetObjects.add(_PlacedObject(source: img, isTarget: true));
    }
  });

  // Si exceden la capacidad, recortar
  if (targetObjects.length > capacity ~/ 2) {
    targetObjects.removeRange(capacity ~/ 2, targetObjects.length);
  }

  // Calcular cantidades objetivo y muestras
  final countsThisPage = <CanvasImage, int>{};
  for (final obj in targetObjects) {
    countsThisPage[obj.source] = (countsThisPage[obj.source] ?? 0) + 1;
  }

  final elements = <CanvasImage>[];

  elements.add(
    CanvasImage.text(
      id: 'subtitle',
      text: 'Mira los modelos y rodea la cantidad indicada',
      position: Offset((canvasWidth - 380) / 2, margin / 2),
      fontSize: 16,
      textColor: Colors.grey[700]!,
      fontFamily: 'Roboto',
    ).copyWith(width: 380),
  );

  // Muestras en fila
  const sampleSize = 55.0;
  const sampleGap = 12.0;
  final samplesWidth =
      countsThisPage.length * (sampleSize + 40 + sampleGap) - sampleGap;
  double sampleX = (canvasWidth - samplesWidth) / 2;
  final sampleY = margin + 14;

  for (final entry in countsThisPage.entries) {
    final img = entry.key;
    final qty = entry.value;
    final idBase = 'sample_${elements.length}';

    elements.add(
      CanvasImage.shape(
        id: '${idBase}_box',
        shapeType: ShapeType.rectangle,
        position: Offset(sampleX - 4, sampleY - 4),
        shapeColor: Colors.grey[700]!,
        strokeWidth: 1.5,
      ).copyWith(width: sampleSize + 8, height: sampleSize + 28),
    );

    if (img.type == CanvasElementType.pictogramCard ||
        img.type == CanvasElementType.networkImage) {
      elements.add(
        CanvasImage.networkImage(
          id: '${idBase}_img',
          imageUrl: img.imageUrl ?? '',
          position: Offset(sampleX, sampleY),
          scale: 1.0,
        ).copyWith(width: sampleSize, height: sampleSize),
      );
    } else {
      elements.add(
        CanvasImage.localImage(
          id: '${idBase}_img',
          imagePath: img.imagePath ?? '',
          position: Offset(sampleX, sampleY),
          scale: 1.0,
        ).copyWith(width: sampleSize, height: sampleSize),
      );
    }

    elements.add(
      CanvasImage.text(
        id: '${idBase}_qty',
        text: 'x$qty',
        position: Offset(sampleX, sampleY + sampleSize + 2),
        fontSize: 16,
        textColor: Colors.black,
        fontFamily: 'Roboto',
      ).copyWith(width: sampleSize),
    );

    sampleX += sampleSize + 40 + sampleGap;
  }

  // Objetos de la página (objetivos + distractores)
  final objects = <_PlacedObject>[]..addAll(targetObjects);
  while (objects.length < capacity) {
    final img = selectable[random.nextInt(selectable.length)];
    objects.add(_PlacedObject(source: img, isTarget: false));
  }
  objects.shuffle(random);

  final startY = margin + 110;
  int objIdx = 0;
  for (int row = 0; row < rows && objIdx < objects.length; row++) {
    for (int col = 0; col < cols && objIdx < objects.length; col++) {
      final obj = objects[objIdx];
      final jitterX = random.nextDouble() * 6 - 3;
      final jitterY = random.nextDouble() * 6 - 3;
      final xPos = margin + col * (imageSize + gap) + jitterX;
      final yPos = startY + row * (imageSize + gap) + jitterY;

      final baseId = '${obj.isTarget ? "target" : "dist"}_$objIdx';
      if (obj.source.type == CanvasElementType.pictogramCard ||
          obj.source.type == CanvasElementType.networkImage) {
        elements.add(
          CanvasImage.networkImage(
            id: baseId,
            imageUrl: obj.source.imageUrl ?? '',
            position: Offset(xPos, yPos),
            scale: 1.0,
          ).copyWith(width: imageSize, height: imageSize),
        );
      } else {
        elements.add(
          CanvasImage.localImage(
            id: baseId,
            imagePath: obj.source.imagePath ?? '',
            position: Offset(xPos, yPos),
            scale: 1.0,
          ).copyWith(width: imageSize, height: imageSize),
        );
      }

      objIdx++;
    }
  }

  return GeneratedActivity(
    elements: elements,
    template: TemplateType.blank,
    message:
        'Actividad de instrucciones generada con ${targetObjects.length} objetivos',
  );
}
