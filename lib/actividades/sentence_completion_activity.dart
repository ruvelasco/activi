import 'package:flutter/material.dart';

import '../models/canvas_image.dart';
import '../widgets/sentence_completion_config_dialog.dart';

// Exportar para uso desde main.dart
export '../widgets/sentence_completion_config_dialog.dart';

class SentenceCompletionResult {
  final List<List<CanvasImage>> pages;
  final String message;
  final String title;
  final String instructions;

  SentenceCompletionResult({
    required this.pages,
    required this.message,
    this.title = 'COMPLETA LA FRASE',
    this.instructions = 'Lee el modelo y pega las imágenes',
  });
}

/// Genera actividad de completar frases con imágenes de ARASAAC
Future<SentenceCompletionResult> generateSentenceCompletionActivity({
  required SentenceCompletionConfig config,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  String fontFamily = 'Arial',
}) async {
  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;

  final pages = <List<CanvasImage>>[];
  const margin = 40.0;

  // PÁGINA 1: Modelos y frases para completar
  final mainPage = <CanvasImage>[];

  // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
  // NO los agregamos aquí para evitar duplicación en el PDF

  // Posición inicial para las frases
  double currentY = 150.0;
  const sentenceSpacing = 130.0;
  const imageBoxSize = 70.0;

  for (int sentenceIndex = 0; sentenceIndex < config.sentences.length; sentenceIndex++) {
    final sentenceData = config.sentences[sentenceIndex];
    final words = sentenceData.sentence.split(' ').where((w) => w.isNotEmpty).toList();

    // Frase modelo (40px)
    mainPage.add(
      CanvasImage.text(
        id: 'model_$sentenceIndex',
        text: sentenceData.sentence.toUpperCase(),
        position: Offset(margin, currentY),
        fontSize: 40,
        textColor: Colors.black,
        fontFamily: fontFamily,
        isBold: true,
      ).copyWith(width: canvasWidth - margin * 2),
    );

    currentY += 55;

    // Frase para completar con cuadrados vacíos
    double currentX = margin;
    const wordSpacing = 10.0;

    for (int wordIndex = 0; wordIndex < words.length; wordIndex++) {
      final word = words[wordIndex];
      final isToComplete = sentenceData.wordsToComplete.contains(wordIndex);

      if (isToComplete) {
        // Cuadrado VACÍO para pegar imagen
        mainPage.add(
          CanvasImage.shape(
            id: 'blank_box_${sentenceIndex}_$wordIndex',
            shapeType: ShapeType.rectangle,
            position: Offset(currentX, currentY - 5),
            width: imageBoxSize,
            height: imageBoxSize,
            shapeColor: Colors.grey[300]!,
            strokeWidth: 2.0,
          ),
        );
        currentX += imageBoxSize + wordSpacing;
      } else {
        // Palabra normal
        final wordWidth = word.length * 15.0;
        mainPage.add(
          CanvasImage.text(
            id: 'word_${sentenceIndex}_$wordIndex',
            text: word.toUpperCase(),
            position: Offset(currentX, currentY),
            fontSize: 28,
            textColor: Colors.black,
            fontFamily: fontFamily,
            isBold: true,
          ),
        );
        currentX += wordWidth + wordSpacing;
      }
    }

    currentY += sentenceSpacing;
  }

  pages.add(mainPage);

  // PÁGINA 2: Recortables con todas las imágenes
  final cutoutsPage = <CanvasImage>[];

  // NOTA: Títulos e instrucciones se manejan automáticamente por el sistema de _pageTitles/_pageInstructions
  // NO los agregamos aquí para evitar duplicación en el PDF

  // Recopilar todas las imágenes de todas las frases
  final allImages = <CanvasImage>[];
  for (final sentenceData in config.sentences) {
    allImages.addAll(sentenceData.wordImages);
  }

  // Distribuir las imágenes en la página
  const cutoutSize = 90.0;
  const cutoutSpacing = 20.0;
  const cols = 3;
  final startY = 160.0;

  for (int i = 0; i < allImages.length; i++) {
    final row = i ~/ cols;
    final col = i % cols;

    final x = margin + col * (cutoutSize + cutoutSpacing);
    final y = startY + row * (cutoutSize + cutoutSpacing);

    // Borde de recorte
    cutoutsPage.add(
      CanvasImage.shape(
        id: 'cutout_border_$i',
        shapeType: ShapeType.rectangle,
        position: Offset(x, y),
        width: cutoutSize,
        height: cutoutSize,
        shapeColor: Colors.black,
        strokeWidth: 1.5,
      ),
    );

    // Imagen dentro del borde
    final image = allImages[i];
    cutoutsPage.add(
      CanvasImage(
        id: 'cutout_image_$i',
        type: image.type,
        position: Offset(x + 5, y + 5),
        width: cutoutSize - 10,
        height: cutoutSize - 10,
        imageUrl: image.imageUrl,
        imagePath: image.imagePath,
        webBytes: image.webBytes,
        cachedImageBytes: image.cachedImageBytes,
      ),
    );
  }

  pages.add(cutoutsPage);

  return SentenceCompletionResult(
    pages: pages,
    message: 'Actividad de completar frases generada con ${config.sentences.length} frase(s)',
  );
}
