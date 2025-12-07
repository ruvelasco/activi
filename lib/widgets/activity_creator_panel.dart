import 'package:flutter/material.dart';

class ActivityCreatorPanel extends StatelessWidget {
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

  const ActivityCreatorPanel({
    super.key,
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
              label: 'Relacionar Sombras',
              icon: Icons.link,
              color: Colors.blue[700],
              description:
                  'Crea una actividad con imágenes en una columna y sus sombras desordenadas en otra. El alumno debe trazar líneas para relacionarlas.',
              onPressed: onShadowMatching,
            ),
            _buildActionButton(
              context,
              label: 'Puzle',
              icon: Icons.extension,
              color: Colors.orange[700],
              description:
                  'Genera un puzle de 4x4 (16 piezas) con la imagen del canvas. Perfecto para imprimir, recortar y que el alumno lo monte.',
              onPressed: onPuzzle,
            ),
            _buildActionButton(
              context,
              label: 'Práctica de Escritura',
              icon: Icons.edit_note,
              color: Colors.green[700],
              description:
                  'Organiza las imágenes en filas y columnas con doble pauta debajo de cada una para que el alumno escriba el nombre.',
              onPressed: onWritingPractice,
            ),
            _buildActionButton(
              context,
              label: 'Práctica de Conteo',
              icon: Icons.calculate,
              color: Colors.purple[700],
              description:
                  'Crea ejercicios con cada imagen repetida un número aleatorio de veces (1-10) en un cuadrado, con espacio para escribir la cantidad.',
              onPressed: onCountingPractice,
            ),
            _buildActionButton(
              context,
              label: 'Series',
              icon: Icons.auto_awesome,
              color: Colors.pink[700],
              description:
                  'Muestra una serie de dos elementos alternados (ABAB...) y deja espacios en blanco para que el alumno continúe el patrón.',
              onPressed: onSeries,
            ),
            _buildActionButton(
              context,
              label: 'Simetrías',
              icon: Icons.flip,
              color: Colors.teal[700],
              description:
                  'Muestra un objeto modelo y una cuadrícula 5x5 con el mismo objeto en diferentes orientaciones (rotado, volteado). El alumno debe encontrar los iguales al modelo.',
              onPressed: onSymmetry,
            ),
            _buildActionButton(
              context,
              label: 'Frases',
              icon: Icons.forum_outlined,
              color: Colors.blueGrey[700],
              description:
                  'Muestra una imagen grande arriba y debajo la frase convertida en pictogramas para que el alumno lea o reconstruya.',
              onPressed: onPhrases,
            ),
            _buildActionButton(
              context,
              label: 'Tarjeta',
              icon: Icons.credit_card,
              color: Colors.deepOrange[700],
              description:
                  'Genera una tarjeta con la imagen a la izquierda y texto (título + párrafo) a la derecha.',
              onPressed: onCard,
            ),
            _buildActionButton(
              context,
              label: 'Vocabulario por Sílaba',
              icon: Icons.abc,
              color: Colors.indigo[700],
              description:
                  'Genera automáticamente una lista de palabras con pictogramas de ARASAAC que empiezan con la sílaba que elijas (pa, ma, sa, etc.). No requiere añadir imágenes previamente.',
              onPressed: onSyllableVocabulary,
            ),
            _buildActionButton(
              context,
              label: 'Campo Semántico',
              icon: Icons.category,
              color: Colors.amber[700],
              description:
                  'Añade una imagen de ARASAAC con texto y genera automáticamente una cuadrícula 5x5 con palabras relacionadas del mismo campo semántico (animales, frutas, ropa, etc.).',
              onPressed: onSemanticField,
            ),
            _buildActionButton(
              context,
              label: 'Instrucciones (Rodea)',
              icon: Icons.radio_button_checked,
              color: Colors.red[700],
              description:
                  'Genera una actividad con instrucciones tipo "Rodea 2 casas, 3 árboles". Los objetos aparecen distribuidos aleatoriamente con algunos distractores.',
              onPressed: onInstructions,
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
    required String description,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
