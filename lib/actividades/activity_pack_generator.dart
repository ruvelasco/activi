import 'package:flutter/material.dart';
import '../models/canvas_image.dart';
import '../services/arasaac_service.dart';
import 'shadow_matching_activity.dart' as shadow;
import 'puzzle_activity.dart' as puzzle;
import 'writing_practice_activity.dart' as writing;
import 'counting_activity.dart' as counting;
import 'series_activity.dart' as series;
import 'symmetry_activity.dart' as symmetry;
import 'instructions_activity.dart' as instructions;
import 'card_activity.dart' as card;
import 'classification_activity.dart' as classification;
import 'phonological_awareness_activity.dart' as phonological;
import 'phonological_squares_activity.dart' as phonological_squares;
import 'semantic_field_activity.dart' as semantic;
import 'syllable_vocabulary_activity.dart' as syllable;
import 'crossword_activity.dart' as crossword;
import 'word_search_activity.dart' as word_search;

enum ActivityPackType {
  shadowMatching,
  puzzle,
  writingPractice,
  countingPractice,
  series,
  symmetry,
  instructions,
  card,
  classification,
  phonologicalAwareness,
  phonologicalBoard,
  phonologicalSquares,
  semanticField,
  syllableVocabulary,
  crossword,
  wordSearch,
}

class ActivityPackConfig {
  final String title;
  final Set<ActivityPackType> selectedActivities;

  const ActivityPackConfig({
    required this.title,
    required this.selectedActivities,
  });
}

class PageWithMetadata {
  final List<CanvasImage> elements;
  final String title;
  final String instructions;

  PageWithMetadata({
    required this.elements,
    required this.title,
    required this.instructions,
  });
}

class ActivityPackResult {
  final List<PageWithMetadata> pagesWithMetadata;
  final String message;

  ActivityPackResult({required this.pagesWithMetadata, required this.message});

  // Compatibility getter
  List<List<CanvasImage>> get pages =>
      pagesWithMetadata.map((p) => p.elements).toList();
}

class ActivityPackGenerator {
  static Future<ActivityPackResult> generatePack({
    required List<CanvasImage> canvasImages,
    required ActivityPackConfig config,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
    ArasaacService? arasaacService,
    void Function(int current, int total, String activityName)? onProgress,
  }) async {
    final List<PageWithMetadata> allPagesWithMetadata = [];
    final List<String> generatedActivities = [];
    final List<String> errors = [];

    final activitiesList = config.selectedActivities.toList();
    final totalActivities = activitiesList.length;

    for (int i = 0; i < activitiesList.length; i++) {
      final activityType = activitiesList[i];
      final activityName = getActivityName(activityType);

      // Reportar progreso antes de generar
      onProgress?.call(i, totalActivities, activityName);

      try {
        final pagesWithMetadata = await _generateSingleActivity(
          activityType: activityType,
          canvasImages: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
          arasaacService: arasaacService,
        );

        if (pagesWithMetadata != null && pagesWithMetadata.isNotEmpty) {
          allPagesWithMetadata.addAll(pagesWithMetadata);
          generatedActivities.add(activityName);
        }
      } catch (e) {
        errors.add('$activityName: $e');
      }

      // Reportar progreso después de generar
      onProgress?.call(i + 1, totalActivities, activityName);
    }

    final message = generatedActivities.isEmpty
        ? 'No se pudo generar ninguna actividad'
        : 'Pack generado: ${generatedActivities.join(', ')} (${allPagesWithMetadata.length} páginas)';

    return ActivityPackResult(pagesWithMetadata: allPagesWithMetadata, message: message);
  }

  static Future<List<PageWithMetadata>?> _generateSingleActivity({
    required ActivityPackType activityType,
    required List<CanvasImage> canvasImages,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
    ArasaacService? arasaacService,
  }) async {
    switch (activityType) {
      case ActivityPackType.shadowMatching:
        final result = shadow.generateShadowMatchingActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
          pairsPerPage: 6,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.puzzle:
        // Generar un puzzle por cada imagen del canvas
        final selectableImages = canvasImages
            .where((element) =>
                element.type == CanvasElementType.networkImage ||
                element.type == CanvasElementType.localImage ||
                element.type == CanvasElementType.pictogramCard)
            .toList();

        if (selectableImages.isEmpty) return null;

        final List<PageWithMetadata> allPuzzlePages = [];

        // Generar un puzzle para cada imagen
        for (final image in selectableImages) {
          final result = puzzle.generatePuzzleActivity(
            images: [image], // Pasar solo una imagen a la vez
            isLandscape: isLandscape,
            a4WidthPts: a4WidthPts,
            a4HeightPts: a4HeightPts,
            gridSize: 4,
          );

          allPuzzlePages.addAll([
            PageWithMetadata(
              elements: result.referencePage,
              title: result.title,
              instructions: result.instructions,
            ),
            PageWithMetadata(
              elements: result.piecesPage,
              title: result.title,
              instructions: result.instructions,
            ),
          ]);
        }

        return allPuzzlePages;

      case ActivityPackType.writingPractice:
        final result = await writing.generateWritingPracticeActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.countingPractice:
        final result = counting.generateCountingActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
          boxesPerPage: 6,
          minCount: 1,
          maxCount: 10,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.series:
        final result = series.generateSeriesActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.symmetry:
        final result = symmetry.generateSymmetryActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.instructions:
        final result = instructions.generateInstructionsActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.elements.isEmpty) return null;
        return [PageWithMetadata(
          elements: result.elements,
          title: result.title,
          instructions: result.instructions,
        )];

      case ActivityPackType.card:
        final result = await card.generateCardActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.classification:
        // Necesita ArasaacService para buscar imágenes relacionadas
        if (arasaacService == null) return null;

        final selectableImages = canvasImages
            .where((element) =>
                element.type == CanvasElementType.networkImage ||
                element.type == CanvasElementType.pictogramCard)
            .toList();

        if (selectableImages.length < 2) return null;

        try {
          // Tomar las dos primeras imágenes como categorías
          final categoryImages = selectableImages.take(2).toList();
          final List<String> relatedUrls = [];

          // Buscar 10 imágenes relacionadas por cada categoría
          for (final catImg in categoryImages) {
            final url = catImg.imageUrl;
            if (url == null) continue;

            // Extraer el ID del pictograma
            final match = RegExp(r'/pictograms/(\d+)').firstMatch(url);
            if (match != null) {
              final pictogramId = match.group(1)!;
              final results = await arasaacService.searchRelatedPictograms(int.parse(pictogramId));
              relatedUrls.addAll(results.take(10).map((p) => p.imageUrl));
            }
          }

          if (relatedUrls.length < 20) return null;

          final result = classification.generateClassificationActivity(
            categoryImages: categoryImages,
            relatedImageUrls: relatedUrls.take(20).toList(),
            isLandscape: isLandscape,
            a4WidthPts: a4WidthPts,
            a4HeightPts: a4HeightPts,
          );

          return [
            PageWithMetadata(
              elements: result.categoriesPage,
              title: result.title,
              instructions: result.instructions,
            ),
            PageWithMetadata(
              elements: result.objectsPage,
              title: result.title,
              instructions: result.instructions,
            ),
          ];
        } catch (e) {
          return null;
        }

      case ActivityPackType.phonologicalAwareness:
        final result = await phonological.generatePhonologicalAwarenessActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.phonologicalBoard:
        final result = await phonological.generatePhonologicalBoardActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.phonologicalSquares:
        final result = await phonological_squares.generatePhonologicalSquaresActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.semanticField:
        // Necesita ArasaacService
        if (arasaacService == null) return null;

        try {
          final result = await semantic.generateSemanticFieldActivity(
            images: canvasImages,
            arasaacService: arasaacService,
            isLandscape: isLandscape,
            a4WidthPts: a4WidthPts,
            a4HeightPts: a4HeightPts,
            maxWords: 25,
            usePictograms: true,
          );

          if (result.pages.isEmpty) return null;

          return result.pages.map((page) => PageWithMetadata(
            elements: page,
            title: result.title,
            instructions: result.instructions,
          )).toList();
        } catch (e) {
          return null;
        }

      case ActivityPackType.syllableVocabulary:
        // Necesita ArasaacService y una sílaba
        if (arasaacService == null) return null;

        try {
          // Obtener la primera imagen con texto
          final imageWithText = canvasImages.firstWhere(
            (img) => img.text != null && img.text!.isNotEmpty,
            orElse: () => canvasImages.first,
          );

          // Extraer la primera sílaba (primeras 2 letras) del texto
          String targetSyllable = 'ma'; // Valor por defecto
          if (imageWithText.text != null && imageWithText.text!.length >= 2) {
            targetSyllable = imageWithText.text!.substring(0, 2).toLowerCase();
          }

          final result = await syllable.generateSyllableVocabularyActivity(
            syllable: targetSyllable,
            arasaacService: arasaacService,
            isLandscape: isLandscape,
            a4WidthPts: a4WidthPts,
            a4HeightPts: a4HeightPts,
            maxWords: 9,
            syllablePosition: 'start',
            usePictograms: true,
          );

          if (result.pages.isEmpty) return null;

          return result.pages.map((page) => PageWithMetadata(
            elements: page,
            title: result.title,
            instructions: result.instructions,
          )).toList();
        } catch (e) {
          return null;
        }

      case ActivityPackType.crossword:
        final result = await crossword.generateCrosswordActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();

      case ActivityPackType.wordSearch:
        final result = await word_search.generateWordSearchActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        if (result.pages.isEmpty) return null;
        return result.pages.map((page) => PageWithMetadata(
          elements: page,
          title: result.title,
          instructions: result.instructions,
        )).toList();
    }
  }

  static String getActivityName(ActivityPackType type) {
    switch (type) {
      case ActivityPackType.shadowMatching:
        return 'Relacionar Sombras';
      case ActivityPackType.puzzle:
        return 'Puzle';
      case ActivityPackType.writingPractice:
        return 'Práctica de Escritura';
      case ActivityPackType.countingPractice:
        return 'Práctica de Conteo';
      case ActivityPackType.series:
        return 'Series';
      case ActivityPackType.symmetry:
        return 'Simetrías';
      case ActivityPackType.instructions:
        return 'Instrucciones';
      case ActivityPackType.card:
        return 'Tarjeta';
      case ActivityPackType.classification:
        return 'Clasificación';
      case ActivityPackType.phonologicalAwareness:
        return 'Conciencia Fonológica';
      case ActivityPackType.phonologicalBoard:
        return 'Tablero Fonológico';
      case ActivityPackType.phonologicalSquares:
        return 'Cuadrados Fonológicos';
      case ActivityPackType.semanticField:
        return 'Campo Semántico';
      case ActivityPackType.syllableVocabulary:
        return 'Vocabulario por Sílabas';
      case ActivityPackType.crossword:
        return 'Crucigrama';
      case ActivityPackType.wordSearch:
        return 'Sopa de Letras';
    }
  }

  static IconData getActivityIcon(ActivityPackType type) {
    switch (type) {
      case ActivityPackType.shadowMatching:
        return Icons.link;
      case ActivityPackType.puzzle:
        return Icons.extension;
      case ActivityPackType.writingPractice:
        return Icons.edit_note;
      case ActivityPackType.countingPractice:
        return Icons.calculate;
      case ActivityPackType.series:
        return Icons.auto_awesome;
      case ActivityPackType.symmetry:
        return Icons.flip;
      case ActivityPackType.instructions:
        return Icons.radio_button_checked;
      case ActivityPackType.card:
        return Icons.credit_card;
      case ActivityPackType.classification:
        return Icons.category;
      case ActivityPackType.phonologicalAwareness:
        return Icons.hearing;
      case ActivityPackType.phonologicalBoard:
        return Icons.grid_on;
      case ActivityPackType.phonologicalSquares:
        return Icons.grid_4x4;
      case ActivityPackType.semanticField:
        return Icons.bubble_chart;
      case ActivityPackType.syllableVocabulary:
        return Icons.text_fields;
      case ActivityPackType.crossword:
        return Icons.apps;
      case ActivityPackType.wordSearch:
        return Icons.search;
    }
  }

  static String getActivityDescription(ActivityPackType type) {
    switch (type) {
      case ActivityPackType.shadowMatching:
        return 'Relaciona imágenes con sus sombras';
      case ActivityPackType.puzzle:
        return 'Puzle de 4x4 para recortar';
      case ActivityPackType.writingPractice:
        return 'Práctica de escritura con pauta';
      case ActivityPackType.countingPractice:
        return 'Ejercicios de conteo';
      case ActivityPackType.series:
        return 'Series de patrones';
      case ActivityPackType.symmetry:
        return 'Encuentra los objetos iguales';
      case ActivityPackType.instructions:
        return 'Sigue las instrucciones';
      case ActivityPackType.card:
        return 'Tarjeta con imagen y texto';
      case ActivityPackType.classification:
        return 'Clasifica objetos en categorías';
      case ActivityPackType.phonologicalAwareness:
        return 'Identifica sílabas y letras';
      case ActivityPackType.phonologicalBoard:
        return 'Tablero con recortables para trabajar sílabas';
      case ActivityPackType.phonologicalSquares:
        return 'Pinta un cuadrado por cada letra';
      case ActivityPackType.semanticField:
        return 'Palabras relacionadas semánticamente';
      case ActivityPackType.syllableVocabulary:
        return 'Vocabulario por sílabas específicas';
      case ActivityPackType.crossword:
        return 'Crucigrama con pistas visuales';
      case ActivityPackType.wordSearch:
        return 'Encuentra las palabras escondidas';
    }
  }
}
