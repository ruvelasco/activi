import 'package:flutter/material.dart';
import '../models/canvas_image.dart';

class TemplatePainter extends CustomPainter {
  final TemplateType templateType;

  TemplatePainter({required this.templateType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    switch (templateType) {
      case TemplateType.blank:
        // Sin plantilla, solo fondo blanco
        break;

      case TemplateType.lined:
        // Folio rayado
        final lineSpacing = 30.0;
        for (double y = lineSpacing; y < size.height; y += lineSpacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        break;

      case TemplateType.grid:
        // Cuadrícula
        final gridSpacing = 30.0;
        // Líneas horizontales
        for (double y = gridSpacing; y < size.height; y += gridSpacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
        // Líneas verticales
        for (double x = gridSpacing; x < size.width; x += gridSpacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        break;

      case TemplateType.comic4:
        // Cómic 4 viñetas (2x2)
        final thickPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

        final midX = size.width / 2;
        final midY = size.height / 2;
        final margin = 20.0;

        // Línea vertical central
        canvas.drawLine(
          Offset(midX, margin),
          Offset(midX, size.height - margin),
          thickPaint,
        );
        // Línea horizontal central
        canvas.drawLine(
          Offset(margin, midY),
          Offset(size.width - margin, midY),
          thickPaint,
        );
        break;

      case TemplateType.comic6:
        // Cómic 6 viñetas (2x3)
        final thickPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

        final margin = 20.0;
        final thirdY = (size.height - 2 * margin) / 3;
        final midX = size.width / 2;

        // Línea vertical central
        canvas.drawLine(
          Offset(midX, margin),
          Offset(midX, size.height - margin),
          thickPaint,
        );
        // Líneas horizontales
        canvas.drawLine(
          Offset(margin, margin + thirdY),
          Offset(size.width - margin, margin + thirdY),
          thickPaint,
        );
        canvas.drawLine(
          Offset(margin, margin + 2 * thirdY),
          Offset(size.width - margin, margin + 2 * thirdY),
          thickPaint,
        );
        break;

      case TemplateType.twoColumns:
        // Dos columnas
        final thickPaint = Paint()
          ..color = Colors.grey[400]!
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        final midX = size.width / 2;
        canvas.drawLine(
          Offset(midX, 0),
          Offset(midX, size.height),
          thickPaint,
        );
        break;

      case TemplateType.threeColumns:
        // Tres columnas
        final thickPaint = Paint()
          ..color = Colors.grey[400]!
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        final thirdX = size.width / 3;
        canvas.drawLine(
          Offset(thirdX, 0),
          Offset(thirdX, size.height),
          thickPaint,
        );
        canvas.drawLine(
          Offset(thirdX * 2, 0),
          Offset(thirdX * 2, size.height),
          thickPaint,
        );
        break;

      case TemplateType.shadowMatching:
        // Plantilla de relacionar sombras (2 columnas con 5 filas)
        final thickPaint = Paint()
          ..color = Colors.grey[600]!
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        final thinPaint = Paint()
          ..color = Colors.grey[300]!
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        final margin = 40.0;
        final columnWidth = (size.width - 3 * margin) / 2;
        final rowHeight = (size.height - 2 * margin) / 5;

        // Línea vertical central
        canvas.drawLine(
          Offset(size.width / 2, margin),
          Offset(size.width / 2, size.height - margin),
          thickPaint,
        );

        // Líneas horizontales
        for (int i = 1; i < 5; i++) {
          canvas.drawLine(
            Offset(margin, margin + rowHeight * i),
            Offset(size.width - margin, margin + rowHeight * i),
            thinPaint,
          );
        }

        // Títulos de columnas
        final textPainter = TextPainter(
          textDirection: TextDirection.ltr,
        );

        // Título columna izquierda
        textPainter.text = TextSpan(
          text: 'IMÁGENES',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(margin + columnWidth / 2 - textPainter.width / 2, 10),
        );

        // Título columna derecha
        textPainter.text = TextSpan(
          text: 'SOMBRAS',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(size.width / 2 + margin + columnWidth / 2 - textPainter.width / 2, 10),
        );

        break;

      case TemplateType.puzzle:
        // Puzle con líneas gruesas para recortar
        final puzzlePaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

        // Dividir en 3x3 (9 piezas) o 4x4 (16 piezas) según el tamaño
        final rows = 4;
        final cols = 4;

        final pieceWidth = size.width / cols;
        final pieceHeight = size.height / rows;

        // Líneas horizontales
        for (int i = 1; i < rows; i++) {
          canvas.drawLine(
            Offset(0, i * pieceHeight),
            Offset(size.width, i * pieceHeight),
            puzzlePaint,
          );
        }

        // Líneas verticales
        for (int i = 1; i < cols; i++) {
          canvas.drawLine(
            Offset(i * pieceWidth, 0),
            Offset(i * pieceWidth, size.height),
            puzzlePaint,
          );
        }

        // Borde exterior más grueso
        final borderPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke;

        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height),
          borderPaint,
        );

        break;

      case TemplateType.writingPractice:
        // Plantilla de práctica de escritura (no dibuja nada aquí,
        // las líneas se dibujan dinámicamente debajo de cada imagen)
        break;

      case TemplateType.countingPractice:
        // Plantilla de práctica de conteo (no dibuja nada aquí,
        // los cuadrados y líneas se dibujan dinámicamente)
        break;
    }
  }

  @override
  bool shouldRepaint(covariant TemplatePainter oldDelegate) {
    return oldDelegate.templateType != templateType;
  }
}
