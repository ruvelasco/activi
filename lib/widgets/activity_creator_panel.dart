import 'package:flutter/material.dart';

class ActivityCreatorPanel extends StatelessWidget {
  final VoidCallback onActivityPack;
  final VoidCallback onShadowMatching;
  final VoidCallback onPuzzle;
  final VoidCallback onWritingPractice;
  final VoidCallback onCountingPractice;
  final VoidCallback onSeries;
  final VoidCallback onSymmetry;
  final VoidCallback onSyllableVocabulary;
  final VoidCallback onSemanticField;
  final VoidCallback onInstructions;
  final VoidCallback onPhrases;
  final VoidCallback onCard;
  final VoidCallback onClassification;
  final VoidCallback onPhonologicalAwareness;
  final VoidCallback onPhonologicalBoard;
  final VoidCallback onPhonologicalSquares;
  final VoidCallback onCrossword;
  final VoidCallback onWordSearch;
  final VoidCallback onSentenceCompletion;

  const ActivityCreatorPanel({
    super.key,
    required this.onActivityPack,
    required this.onShadowMatching,
    required this.onPuzzle,
    required this.onWritingPractice,
    required this.onCountingPractice,
    required this.onSeries,
    required this.onSymmetry,
    required this.onSyllableVocabulary,
    required this.onSemanticField,
    required this.onInstructions,
    required this.onPhrases,
    required this.onCard,
    required this.onClassification,
    required this.onPhonologicalAwareness,
    required this.onPhonologicalBoard,
    required this.onPhonologicalSquares,
    required this.onCrossword,
    required this.onWordSearch,
    required this.onSentenceCompletion,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Generador de Actividades',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea actividades automáticamente usando las imágenes del canvas',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              context,
              label: 'Pack de Actividades',
              icon: Icons.auto_awesome,
              color: Colors.deepPurple[700],
              infoTooltip:
                  'Genera múltiples actividades de forma automática. Selecciona qué tipos de actividades quieres crear y se generarán todas usando las imágenes del canvas.',
              onPressed: onActivityPack,
              isHighlighted: true,
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 12),
            Text(
              'Actividades Individuales',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              context,
              label: 'Relacionar Sombras',
              icon: Icons.link,
              color: Colors.blue[700],
              description: null,
              infoTooltip:
                  'Crea una actividad con imágenes y sombras en 3 columnas con puntos de unión. El alumno traza líneas entre los puntos para relacionar cada imagen con su sombra.',
              onPressed: onShadowMatching,
            ),
            _buildActionButton(
              context,
              label: 'Puzle',
              icon: Icons.extension,
              color: Colors.orange[700],
              infoTooltip:
                  'Genera un puzle de 4x4 (16 piezas) con la imagen del canvas. Perfecto para imprimir, recortar y que el alumno lo monte.',
              onPressed: onPuzzle,
            ),
            _buildActionButton(
              context,
              label: 'Práctica de Escritura',
              icon: Icons.edit_note,
              color: Colors.green[700],
              infoTooltip:
                  'Organiza las imágenes en filas y columnas con pauta debajo de cada una para que el alumno escriba el nombre.',
              onPressed: onWritingPractice,
            ),
            _buildActionButton(
              context,
              label: 'Práctica de Conteo',
              icon: Icons.calculate,
              color: Colors.purple[700],
              infoTooltip:
                  'Crea ejercicios con cada imagen repetida un número aleatorio de veces en su caja, con espacio para escribir la cantidad.',
              onPressed: onCountingPractice,
            ),
            _buildActionButton(
              context,
              label: 'Conciencia Fonológica',
              icon: Icons.hearing,
              color: Colors.deepPurple[700],
              infoTooltip:
                  'Separa las palabras en sílabas. Muestra la imagen, las sílabas separadas y líneas en pauta escolar para que el alumno repase cada sílaba.',
              onPressed: onPhonologicalAwareness,
            ),
            _buildActionButton(
              context,
              label: 'Tablero Fonológico (recortable)',
              icon: Icons.view_column,
              color: Colors.deepOrange[700],
              infoTooltip:
                  'Crea un tablero vertical con zona de puzle 2x2 y huecos para palabra, sílabas y letras, más otra hoja con las piezas y tarjetas recortables listas para imprimir.',
              onPressed: onPhonologicalBoard,
            ),
            _buildActionButton(
              context,
              label: 'Series',
              icon: Icons.auto_awesome,
              color: Colors.pink[700],
              infoTooltip:
                  'Muestra una serie de dos elementos alternados (ABAB...) y deja espacios en blanco para que el alumno continúe el patrón.',
              onPressed: onSeries,
            ),
            _buildActionButton(
              context,
              label: 'Simetrías',
              icon: Icons.flip,
              color: Colors.teal[700],
              infoTooltip:
                  'Muestra un objeto modelo y una cuadrícula 5x5 con el mismo objeto en diferentes orientaciones (rotado, volteado). El alumno debe encontrar los iguales al modelo.',
              onPressed: onSymmetry,
            ),
            _buildActionButton(
              context,
              label: 'Frases',
              icon: Icons.forum_outlined,
              color: Colors.blueGrey[700],
              infoTooltip:
                  'Muestra una imagen grande arriba y debajo la frase convertida en pictogramas para que el alumno lea o reconstruya.',
              onPressed: onPhrases,
            ),
            _buildActionButton(
              context,
              label: 'Tarjeta',
              icon: Icons.credit_card,
              color: Colors.deepOrange[700],
              infoTooltip:
                  'Genera una tarjeta con la imagen a la izquierda y texto (título + párrafo) a la derecha.',
              onPressed: onCard,
            ),
            _buildActionButton(
              context,
              label: 'Vocabulario por Sílaba',
              icon: Icons.abc,
              color: Colors.indigo[700],
              infoTooltip:
                  'Genera automáticamente una lista de palabras con pictogramas de ARASAAC que empiezan con la sílaba que elijas (pa, ma, sa, etc.). No requiere añadir imágenes previamente.',
              onPressed: onSyllableVocabulary,
            ),
            _buildActionButton(
              context,
              label: 'Campo Semántico',
              icon: Icons.category,
              color: Colors.amber[700],
              infoTooltip:
                  'Añade una imagen de ARASAAC con texto y genera automáticamente una cuadrícula 5x5 con palabras relacionadas del mismo campo semántico (animales, frutas, ropa, etc.).',
              onPressed: onSemanticField,
            ),
            _buildActionButton(
              context,
              label: 'Instrucciones (Rodea)',
              icon: Icons.radio_button_checked,
              color: Colors.red[700],
              infoTooltip:
                  'Genera una actividad con instrucciones tipo "Rodea 2 casas, 3 árboles". Los objetos aparecen distribuidos aleatoriamente con algunos distractores.',
              onPressed: onInstructions,
            ),
            _buildActionButton(
              context,
              label: 'Clasificación',
              icon: Icons.dashboard,
              color: Colors.cyan[700],
              infoTooltip:
                  'Crea una actividad de clasificación en 2 hojas: una con 2 cuadrados de categorías y otra con 10 objetos relacionados para recortar y clasificar. Requiere 2 imágenes de ARASAAC en el canvas.',
              onPressed: onClassification,
            ),
            _buildActionButton(
              context,
              label: 'Cuadrados Fonológicos',
              icon: Icons.grid_4x4,
              color: Colors.lightBlue[700],
              infoTooltip:
                  'Muestra las imágenes del canvas con un rectángulo de 10 cuadrados (2 filas x 5 columnas) debajo de cada una. El alumno pinta un cuadrado por cada letra de la palabra.',
              onPressed: onPhonologicalSquares,
            ),
            _buildActionButton(
              context,
              label: 'Crucigrama',
              icon: Icons.apps,
              color: Colors.brown[700],
              infoTooltip:
                  'Genera un crucigrama usando las palabras de las imágenes del canvas. Las imágenes sirven como pistas numeradas para completar el crucigrama.',
              onPressed: onCrossword,
            ),
            _buildActionButton(
              context,
              label: 'Sopa de Letras',
              icon: Icons.search,
              color: Colors.deepPurple[700],
              infoTooltip:
                  'Crea una sopa de letras donde el alumno debe encontrar las palabras de las imágenes del canvas escondidas en una cuadrícula de 15x15 letras.',
              onPressed: onWordSearch,
            ),
            _buildActionButton(
              context,
              label: 'Completar Frases',
              icon: Icons.edit_note,
              color: Colors.teal[700],
              infoTooltip:
                  'Genera frases simples con las imágenes del canvas. Cada página muestra un modelo de frase completa y debajo la misma frase con espacios en blanco para completar. Incluye una página con recortables.',
              onPressed: onSentenceCompletion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color? color,
    String? description,
    String? infoTooltip,
    required VoidCallback onPressed,
    bool isHighlighted = false,
  }) {
    final button = ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isHighlighted ? 24 : 20),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isHighlighted ? 16 : 14,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: isHighlighted ? 20 : 16,
          horizontal: isHighlighted ? 16 : 0,
        ),
        elevation: isHighlighted ? 6 : 2,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: infoTooltip != null
          ? Tooltip(
              message: infoTooltip,
              waitDuration: const Duration(milliseconds: 400),
              child: button,
            )
          : button,
    );
  }
}
