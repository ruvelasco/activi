import 'dart:math';
import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import '../services/arasaac_service.dart';
import 'activity_result.dart';

/// Configuración de un objeto para rodear en la actividad
class InstructionItem {
  final String word;
  final int quantity;

  InstructionItem({required this.word, required this.quantity});
}

Future<GeneratedActivity> generateInstructionsActivity({
  required List<InstructionItem> instructions,
  required ArasaacService arasaacService,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
}) async {
  final result = <CanvasImage>[];
  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  const margin = 40.0;

  // Título
  result.add(
    CanvasImage.text(
      id: 'title',
      text: 'RODEA:',
      position: const Offset(margin, margin),
      fontSize: 24,
      textColor: Colors.black,
      fontFamily: 'Roboto',
      scale: 1.0,
    ),
  );

  // Crear texto de instrucciones
  final instructionText = instructions
      .map((item) => '${item.quantity} ${item.word}${item.quantity > 1 ? "s" : ""}')
      .join('; ');

  result.add(
    CanvasImage.text(
      id: 'instructions',
      text: instructionText,
      position: const Offset(margin, margin + 35),
      fontSize: 20,
      textColor: Colors.blue,
      fontFamily: 'Roboto',
      scale: 1.0,
    ),
  );

  // Buscar pictogramas para cada palabra
  final objectsToPlace = <_ObjectToPlace>[];

  for (final instruction in instructions) {
    final searchResults = await arasaacService.searchPictograms(instruction.word);
    if (searchResults.isNotEmpty) {
      objectsToPlace.add(_ObjectToPlace(
        word: instruction.word,
        quantity: instruction.quantity,
        imageUrl: searchResults.first.imageUrl,
      ));
    }
  }

  if (objectsToPlace.isEmpty) {
    result.add(
      CanvasImage.text(
        id: 'no_objects',
        text: 'No se encontraron dibujos para los objetos',
        position: const Offset(margin, margin + 80),
        fontSize: 16,
        textColor: Colors.orange,
        fontFamily: 'Roboto',
        scale: 1.0,
      ),
    );
    return GeneratedActivity(elements: result);
  }

  // Configuración de la cuadrícula - solo dibujos
  const imageSize = 80.0;
  const gap = 15.0;

  // Calcular cuántas columnas y filas caben en la página
  final cols = ((canvasWidth - 2 * margin) / (imageSize + gap)).floor();
  final rows = ((canvasHeight - margin - 100) / (imageSize + gap)).floor();

  // Calcular el total de espacios disponibles
  final totalSpaces = cols * rows;

  // Calcular el total de objetos target
  final totalTargetObjects = instructions.fold<int>(0, (sum, item) => sum + item.quantity);

  // Calcular cuántos distractores necesitamos para llenar la hoja
  final numDistractors = totalSpaces - totalTargetObjects;

  // Crear lista de todos los objetos a colocar (targets + distractores)
  final allObjects = <_PlacedObject>[];
  final random = Random();

  // Agregar objetos target
  for (final obj in objectsToPlace) {
    for (int i = 0; i < obj.quantity; i++) {
      allObjects.add(_PlacedObject(
        word: obj.word,
        imageUrl: obj.imageUrl,
        isTarget: true,
      ));
    }
  }

  // Agregar objetos distractores hasta llenar la hoja
  for (int i = 0; i < numDistractors && i < 200; i++) {
    final randomObj = objectsToPlace[random.nextInt(objectsToPlace.length)];
    allObjects.add(_PlacedObject(
      word: randomObj.word,
      imageUrl: randomObj.imageUrl,
      isTarget: false,
    ));
  }

  // Mezclar los objetos aleatoriamente
  allObjects.shuffle(random);

  final gridStartY = margin + 100;

  // Distribuir objetos en la cuadrícula llenando toda la hoja
  int objectIndex = 0;
  for (int row = 0; row < rows && objectIndex < allObjects.length; row++) {
    for (int col = 0; col < cols && objectIndex < allObjects.length; col++) {
      final obj = allObjects[objectIndex];

      // Añadir algo de variación aleatoria en la posición
      final randomOffsetX = random.nextDouble() * 10 - 5;
      final randomOffsetY = random.nextDouble() * 10 - 5;

      final xPos = margin + col * (imageSize + gap) + randomOffsetX;
      final yPos = gridStartY + row * (imageSize + gap) + randomOffsetY;

      // Solo dibujos, sin pictogramas
      result.add(
        CanvasImage.networkImage(
          id: 'object_$objectIndex',
          imageUrl: obj.imageUrl,
          position: Offset(xPos, yPos),
          scale: 1.0,
        ).copyWith(width: imageSize, height: imageSize),
      );

      objectIndex++;
    }
  }

  return GeneratedActivity(
    elements: result,
    message: 'Actividad de instrucciones generada con $totalTargetObjects objetos a rodear (${allObjects.length} objetos en total)',
  );
}

// Clase auxiliar para objetos a colocar
class _ObjectToPlace {
  final String word;
  final int quantity;
  final String imageUrl;

  _ObjectToPlace({
    required this.word,
    required this.quantity,
    required this.imageUrl,
  });
}

// Clase auxiliar para objetos colocados
class _PlacedObject {
  final String word;
  final String imageUrl;
  final bool isTarget;

  _PlacedObject({
    required this.word,
    required this.imageUrl,
    required this.isTarget,
  });
}
