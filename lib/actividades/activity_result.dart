import '../models/canvas_image.dart';

class GeneratedActivity {
  final List<CanvasImage> elements;
  final TemplateType? template;
  final String? message;
  final String title;
  final String instructions;

  GeneratedActivity({
    required this.elements,
    this.template,
    this.message,
    this.title = 'INSTRUCCIONES',
    this.instructions = 'Señala los objetos indicados',
  });
}
