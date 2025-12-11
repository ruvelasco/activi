import 'dart:math';
import '../models/canvas_image.dart';
import 'package:flutter/material.dart';

class ClassificationActivityResult {
  final List<CanvasImage> categoriesPage; // Página con las 2 categorías
  final List<CanvasImage> objectsPage; // Página con los 10 objetos recortables

  ClassificationActivityResult({
    required this.categoriesPage,
    required this.objectsPage,
  });
}

/// Genera una actividad de clasificación con 2 categorías y 20 objetos
///
/// - categoriesPage: Hoja con 2 cuadrados grandes con las imágenes de categoría
/// - objectsPage: Hoja con 20 objetos relacionados para recortar y clasificar (10 de cada categoría)
ClassificationActivityResult generateClassificationActivity({
  required List<CanvasImage> categoryImages, // Las 2 imágenes seleccionadas como categorías
  required List<String> relatedImageUrls, // 20 URLs de imágenes relacionadas
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
}) {
  final random = Random();

  // Dimensiones de la página
  final pageWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final pageHeight = isLandscape ? a4WidthPts : a4HeightPts;

  // ========== PÁGINA 1: CATEGORÍAS ==========
  final categoriesPage = <CanvasImage>[];

  // Cada cuadrado ocupa la mitad de la hoja
  final margin = 40.0;
  final spacing = 20.0; // Espacio entre los dos cuadrados

  // Ancho de cada cuadrado: mitad de la página menos márgenes
  final categoryBoxWidth = (pageWidth - (margin * 2) - spacing) / 2;
  final categoryBoxHeight = pageHeight - (margin * 2);

  // Tamaño de la imagen de categoría (más grande)
  final categoryImageSize = categoryBoxWidth * 0.6;

  for (int i = 0; i < 2 && i < categoryImages.length; i++) {
    final categoryImage = categoryImages[i];
    final xPos = margin + (i * (categoryBoxWidth + spacing));
    final yPos = margin;

    // Añadir el cuadrado de fondo
    categoriesPage.add(
      CanvasImage.shape(
        id: 'category_box_$i',
        shapeType: ShapeType.rectangle,
        position: Offset(xPos, yPos),
        width: categoryBoxWidth,
        height: categoryBoxHeight,
        shapeColor: Colors.grey[300]!,
        strokeWidth: 3.0,
      ),
    );

    // Añadir la imagen de categoría centrada en la parte superior
    categoriesPage.add(
      CanvasImage.networkImage(
        id: 'category_image_$i',
        imageUrl: categoryImage.imageUrl!,
        position: Offset(
          xPos + (categoryBoxWidth - categoryImageSize) / 2,
          yPos + 40,
        ),
        width: categoryImageSize,
        height: categoryImageSize,
      ),
    );
  }

  // ========== PÁGINA 2: OBJETOS RECORTABLES ==========
  final objectsPage = <CanvasImage>[];

  // Configuración de la cuadrícula
  final cols = 4; // 4 columnas
  final rows = 5; // 5 filas = 20 objetos
  final objectSize = 100.0;
  final gridSpacingX = 20.0;
  final gridSpacingY = 20.0;

  // Calcular dimensiones totales de la cuadrícula
  final gridWidth = (cols * objectSize) + ((cols - 1) * gridSpacingX);
  final gridHeight = (rows * objectSize) + ((rows - 1) * gridSpacingY);

  // Centrar la cuadrícula
  final gridStartX = (pageWidth - gridWidth) / 2;
  final gridStartY = (pageHeight - gridHeight) / 2;

  // Mezclar las URLs para distribuir aleatoriamente
  final shuffledUrls = List<String>.from(relatedImageUrls)..shuffle(random);

  int imageIndex = 0;
  for (int row = 0; row < rows && imageIndex < shuffledUrls.length; row++) {
    for (int col = 0; col < cols && imageIndex < shuffledUrls.length; col++) {
      final xPos = gridStartX + (col * (objectSize + gridSpacingX));
      final yPos = gridStartY + (row * (objectSize + gridSpacingY));

      // Añadir borde punteado alrededor de cada objeto (para indicar recorte)
      objectsPage.add(
        CanvasImage.shape(
          id: 'cutline_$imageIndex',
          shapeType: ShapeType.rectangle,
          position: Offset(xPos - 2, yPos - 2),
          width: objectSize + 4,
          height: objectSize + 4,
          shapeColor: Colors.grey[600]!,
          strokeWidth: 1.5,
          isDashed: true,
        ),
      );

      // Añadir la imagen del objeto
      objectsPage.add(
        CanvasImage.networkImage(
          id: 'object_$imageIndex',
          imageUrl: shuffledUrls[imageIndex],
          position: Offset(xPos, yPos),
          width: objectSize,
          height: objectSize,
        ),
      );

      imageIndex++;
    }
  }

  return ClassificationActivityResult(
    categoriesPage: categoriesPage,
    objectsPage: objectsPage,
  );
}
