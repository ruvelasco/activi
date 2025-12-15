import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/canvas_image.dart';

enum CardLayout { imageTop, imageRight, imageLeft, textThenImage }

class CardActivityResult {
  final List<List<CanvasImage>> pages;
  final String message;

  CardActivityResult({required this.pages, required this.message});
}

Future<CardActivityResult> generateCardActivity({
  required List<CanvasImage> images,
  required bool isLandscape,
  required double a4WidthPts,
  required double a4HeightPts,
  CardLayout layout = CardLayout.imageLeft,
}) async {
  final selectable = images.where((element) {
    return element.type == CanvasElementType.networkImage ||
        element.type == CanvasElementType.localImage ||
        element.type == CanvasElementType.pictogramCard;
  }).toList();

  if (selectable.isEmpty) {
    return CardActivityResult(pages: [[]], message: 'Añade al menos una imagen primero');
  }

  final canvasWidth = isLandscape ? a4HeightPts : a4WidthPts;
  final canvasHeight = isLandscape ? a4WidthPts : a4HeightPts;
  const margin = 30.0;
  final cardWidth = canvasWidth - margin * 2;
  const rowsPerPage = 2;
  final cardHeight = ((canvasHeight - margin * 2 - 10) / rowsPerPage).clamp(260.0, 420.0);

  final pages = <List<CanvasImage>>[];

  for (int i = 0; i < selectable.length; i++) {
    final pageElements = <CanvasImage>[];
    final image = selectable[i];
    final data = await _getPictogramData(image.imageUrl);
    final title = data.title.isNotEmpty ? data.title : (image.text ?? 'TARJETA');
    final body = data.description.isNotEmpty ? data.description : 'Descripción no disponible';

    for (int row = 0; row < rowsPerPage; row++) {
      final cardY = margin + row * (cardHeight + 10);
      final baseId = 'card_${i}_$row';
      // Fondo
      pageElements.add(
        CanvasImage.shape(
          id: 'card_bg_${i}_$row',
          shapeType: ShapeType.rectangle,
          position: Offset(margin, cardY),
          shapeColor: Colors.grey[200]!,
          strokeWidth: 2.0,
        ).copyWith(width: cardWidth, height: cardHeight),
      );

      switch (layout) {
        case CardLayout.imageTop:
          final imgHeight = cardHeight * 0.45;
          final imgWidth = cardWidth * 0.65;
          final imgX = margin + (cardWidth - imgWidth) / 2;
          final imgY = cardY + 12;
          pageElements.add(_placeImage(image, '${baseId}_img', imgX, imgY, imgWidth, imgHeight));

          pageElements.add(
            CanvasImage.text(
              id: '${baseId}_title',
              text: title,
              position: Offset(margin + 12, imgY + imgHeight + 12),
              fontSize: 24,
              textColor: Colors.black,
              fontFamily: 'Roboto',
              isBold: true,
            ).copyWith(width: cardWidth - 24),
          );

          pageElements.add(
            CanvasImage.text(
              id: '${baseId}_body',
              text: body,
              position: Offset(margin + 12, imgY + imgHeight + 44),
              fontSize: 14,
              textColor: Colors.black87,
              fontFamily: 'Roboto',
            ).copyWith(width: cardWidth - 24),
          );
          break;

        case CardLayout.imageRight:
          final imgWidth = cardWidth * 0.4;
          final imgHeight = cardHeight - 24;
          final imgX = margin + cardWidth - imgWidth - 12;
          final imgY = cardY + 12;
          final textWidth = cardWidth - imgWidth - 30;

          pageElements.add(_placeImage(image, '${baseId}_img', imgX, imgY, imgWidth, imgHeight));

          pageElements.add(
            CanvasImage.text(
              id: '${baseId}_title',
              text: title,
              position: Offset(margin + 12, cardY + 16),
              fontSize: 24,
              textColor: Colors.black,
              fontFamily: 'Roboto',
              isBold: true,
            ).copyWith(width: textWidth),
          );

          pageElements.add(
            CanvasImage.text(
              id: '${baseId}_body',
              text: body,
              position: Offset(margin + 12, cardY + 46),
              fontSize: 14,
              textColor: Colors.black87,
              fontFamily: 'Roboto',
            ).copyWith(width: textWidth),
          );
          break;

        case CardLayout.imageLeft:
          final imgWidth = cardWidth * 0.4;
          final imgHeight = cardHeight - 24;
          final imgX = margin + 12;
          final imgY = cardY + 12;
          final textWidth = cardWidth - imgWidth - 30;

          pageElements.add(_placeImage(image, '${baseId}_img', imgX, imgY, imgWidth, imgHeight));

          pageElements.add(
            CanvasImage.text(
              id: '${baseId}_title',
              text: title,
              position: Offset(imgX + imgWidth + 10, cardY + 16),
              fontSize: 24,
              textColor: Colors.black,
              fontFamily: 'Roboto',
              isBold: true,
            ).copyWith(width: textWidth),
          );

          pageElements.add(
            CanvasImage.text(
              id: '${baseId}_body',
              text: body,
              position: Offset(imgX + imgWidth + 10, cardY + 46),
              fontSize: 14,
              textColor: Colors.black87,
              fontFamily: 'Roboto',
            ).copyWith(width: textWidth),
          );
          break;

        case CardLayout.textThenImage:
          final textHeight = cardHeight * 0.45;
          final imgHeight = cardHeight - textHeight - 24;
          final imgWidth = cardWidth * 0.6;
          final imgX = margin + (cardWidth - imgWidth) / 2;
          final imgY = cardY + textHeight + 12;

          pageElements.add(
            CanvasImage.text(
              id: '${baseId}_title',
              text: title,
              position: Offset(margin + 12, cardY + 12),
              fontSize: 24,
              textColor: Colors.black,
              fontFamily: 'Roboto',
              isBold: true,
            ).copyWith(width: cardWidth - 24),
          );

          pageElements.add(
            CanvasImage.text(
              id: '${baseId}_body',
              text: body,
              position: Offset(margin + 12, cardY + 42),
              fontSize: 14,
              textColor: Colors.black87,
              fontFamily: 'Roboto',
            ).copyWith(width: cardWidth - 24),
          );

          pageElements.add(_placeImage(image, '${baseId}_img', imgX, imgY, imgWidth, imgHeight));
          break;
      }
    }

    pages.add(pageElements);
  }

  return CardActivityResult(
    pages: pages,
    message: 'Tarjetas generadas en ${pages.length} página(s)',
  );
}

Future<_PictogramData> _getPictogramData(String? imageUrl) async {
  if (imageUrl == null || imageUrl.isEmpty) return _PictogramData('', '');
  final id = _extractIdFromUrl(imageUrl);
  if (id == null) return _PictogramData('', '');

  final url = Uri.parse('https://api.arasaac.org/v1/pictograms/$id/languages/es');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      String title = '';
      String description = '';
      if (data['keywordsByLocale'] != null) {
        final esKeywords = data['keywordsByLocale']['es'] as List?;
        if (esKeywords != null && esKeywords.isNotEmpty && esKeywords[0]['keyword'] != null) {
          title = esKeywords[0]['keyword'].toString();
          // Preferir meaning si existe
          if (esKeywords[0]['meaning'] != null) {
            description = esKeywords[0]['meaning'].toString();
          }
        }
      }
      if (description.isEmpty && data['description'] != null) {
        description = data['description'].toString();
      } else if (description.isEmpty && data['tags'] != null && data['tags'] is List) {
        description = (data['tags'] as List).join(', ');
      }
      return _PictogramData(title, description);
    }
  } catch (_) {}
  return _PictogramData('', '');
}

String? _extractIdFromUrl(String url) {
  var regex = RegExp(r'/pictograms/(\d+)(?:\?|$)');
  var match = regex.firstMatch(url);
  if (match != null && match.groupCount >= 1) return match.group(1);

  regex = RegExp(r'/pictograms/(\d+)/\d+_\d+\.png');
  match = regex.firstMatch(url);
  if (match != null && match.groupCount >= 1) return match.group(1);

  return null;
}

CanvasImage _placeImage(CanvasImage image, String id, double x, double y, double width, double height) {
  if (image.type == CanvasElementType.localImage) {
    return CanvasImage.localImage(
      id: id,
      imagePath: image.imagePath ?? '',
      position: Offset(x, y),
      scale: 1.0,
    ).copyWith(width: width, height: height);
  }
  return CanvasImage.networkImage(
    id: id,
    imageUrl: image.imageUrl ?? '',
    position: Offset(x, y),
    scale: 1.0,
  ).copyWith(width: width, height: height);
}

class _PictogramData {
  final String title;
  final String description;

  _PictogramData(this.title, this.description);
}
