import 'package:flutter/material.dart';
import '../models/canvas_image.dart';
import 'shadow_matching_activity.dart' as shadow;
import 'puzzle_activity.dart' as puzzle;
import 'writing_practice_activity.dart' as writing;
import 'counting_activity.dart' as counting;
import 'series_activity.dart' as series;
import 'symmetry_activity.dart' as symmetry;
import 'instructions_activity.dart' as instructions;
import 'card_activity.dart' as card;

enum ActivityPackType {
  shadowMatching,
  puzzle,
  writingPractice,
  countingPractice,
  series,
  symmetry,
  instructions,
  card,
}

class ActivityPackConfig {
  final String title;
  final Set<ActivityPackType> selectedActivities;

  const ActivityPackConfig({
    required this.title,
    required this.selectedActivities,
  });
}

class ActivityPackResult {
  final List<List<CanvasImage>> pages;
  final String message;

  ActivityPackResult({required this.pages, required this.message});
}

class ActivityPackGenerator {
  static Future<ActivityPackResult> generatePack({
    required List<CanvasImage> canvasImages,
    required ActivityPackConfig config,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
  }) async {
    final List<List<CanvasImage>> allPages = [];
    final List<String> generatedActivities = [];
    final List<String> errors = [];

    for (final activityType in config.selectedActivities) {
      try {
        final pages = await _generateSingleActivity(
          activityType: activityType,
          canvasImages: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );

        if (pages != null && pages.isNotEmpty) {
          allPages.addAll(pages);
          generatedActivities.add(getActivityName(activityType));
        }
      } catch (e) {
        errors.add('${getActivityName(activityType)}: $e');
      }
    }

    final message = generatedActivities.isEmpty
        ? 'No se pudo generar ninguna actividad'
        : 'Pack generado: ${generatedActivities.join(', ')} (${allPages.length} páginas)';

    return ActivityPackResult(pages: allPages, message: message);
  }

  static Future<List<List<CanvasImage>>?> _generateSingleActivity({
    required ActivityPackType activityType,
    required List<CanvasImage> canvasImages,
    required bool isLandscape,
    required double a4WidthPts,
    required double a4HeightPts,
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
        return result.pages.isEmpty ? null : result.pages;

      case ActivityPackType.puzzle:
        final result = puzzle.generatePuzzleActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
          gridSize: 4,
        );
        return [result.referencePage, result.piecesPage];

      case ActivityPackType.writingPractice:
        final result = await writing.generateWritingPracticeActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        return result.pages.isEmpty ? null : result.pages;

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
        return result.pages.isEmpty ? null : result.pages;

      case ActivityPackType.series:
        final result = series.generateSeriesActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        return result.pages.isEmpty ? null : result.pages;

      case ActivityPackType.symmetry:
        final result = symmetry.generateSymmetryActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        return result.pages.isEmpty ? null : result.pages;

      case ActivityPackType.instructions:
        final result = instructions.generateInstructionsActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        return result.elements.isEmpty ? null : [result.elements];

      case ActivityPackType.card:
        final result = await card.generateCardActivity(
          images: canvasImages,
          isLandscape: isLandscape,
          a4WidthPts: a4WidthPts,
          a4HeightPts: a4HeightPts,
        );
        return result.pages.isEmpty ? null : result.pages;
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
    }
  }
}
