import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/canvas_image.dart';

class SentenceCompletionConfig {
  final List<SentenceData> sentences;

  SentenceCompletionConfig({
    required this.sentences,
  });
}

class SentenceData {
  final String sentence;
  final List<int> wordsToComplete;
  final List<CanvasImage> wordImages;

  SentenceData({
    required this.sentence,
    required this.wordsToComplete,
    required this.wordImages,
  });
}

class SentenceCompletionConfigDialog extends StatefulWidget {
  const SentenceCompletionConfigDialog({super.key});

  @override
  State<SentenceCompletionConfigDialog> createState() =>
      _SentenceCompletionConfigDialogState();
}

class _SentenceCompletionConfigDialogState
    extends State<SentenceCompletionConfigDialog> {
  final _sentenceController = TextEditingController();
  final List<bool> _selectedWords = [];
  final List<String> _words = [];
  final List<CanvasImage?> _wordImages = [];
  final List<SentenceData> _addedSentences = [];

  @override
  void initState() {
    super.initState();
    _sentenceController.addListener(_updateWords);
  }

  @override
  void dispose() {
    _sentenceController.removeListener(_updateWords);
    _sentenceController.dispose();
    super.dispose();
  }

  void _updateWords() {
    final sentence = _sentenceController.text.trim();
    final words = sentence.split(' ').where((w) => w.isNotEmpty).toList();

    setState(() {
      _words.clear();
      _words.addAll(words);

      while (_selectedWords.length < words.length) {
        _selectedWords.add(false);
        _wordImages.add(null);
      }
      while (_selectedWords.length > words.length) {
        _selectedWords.removeLast();
        _wordImages.removeLast();
      }
    });
  }

  Future<void> _autoAssignImage(int wordIndex) async {
    final word = _words[wordIndex].toLowerCase();

    try {
      // Buscar directamente en ARASAAC
      final response = await http.get(
        Uri.parse(
            'https://api.arasaac.org/v1/pictograms/es/search/$word'),
      );

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List<dynamic>;
        if (results.isNotEmpty) {
          final firstResult = results[0];
          final pictogramId = firstResult['_id'] as int;
          final imageUrl =
              'https://api.arasaac.org/v1/pictograms/$pictogramId?download=false';

          setState(() {
            _wordImages[wordIndex] = CanvasImage(
              id: 'arasaac_$pictogramId',
              type: CanvasElementType.networkImage,
              position: Offset.zero,
              width: 100,
              height: 100,
              imageUrl: imageUrl,
            );
          });
          return;
        }
      }
    } catch (e) {
      print('Error buscando en ARASAAC: $e');
    }

    setState(() {
      _wordImages[wordIndex] = null;
    });
  }

  void _addCurrentSentence() {
    final selectedIndices = <int>[];
    final selectedImages = <CanvasImage>[];

    for (int i = 0; i < _selectedWords.length; i++) {
      if (_selectedWords[i] && _wordImages[i] != null) {
        selectedIndices.add(i);
        selectedImages.add(_wordImages[i]!);
      }
    }

    if (selectedIndices.isEmpty) return;

    setState(() {
      _addedSentences.add(SentenceData(
        sentence: _sentenceController.text.trim(),
        wordsToComplete: selectedIndices,
        wordImages: selectedImages,
      ));

      // Limpiar para añadir nueva frase
      _sentenceController.clear();
      _words.clear();
      _selectedWords.clear();
      _wordImages.clear();
    });
  }

  void _removeSentence(int index) {
    setState(() {
      _addedSentences.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurar Completa la Frase',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Frases añadidas
            if (_addedSentences.isNotEmpty) ...[
              Text(
                'Frases añadidas: ${_addedSentences.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _addedSentences.length,
                  itemBuilder: (context, index) {
                    final sentence = _addedSentences[index];
                    return ListTile(
                      dense: true,
                      leading: Text('${index + 1}.'),
                      title: Text(
                        sentence.sentence,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _removeSentence(index),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text(
              'Nueva frase:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sentenceController,
              decoration: const InputDecoration(
                hintText: 'Ej: El perro rojo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (_words.isNotEmpty) ...[
              const Text(
                'Selecciona palabras a completar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selectedWords[index],
                              onChanged: (value) async {
                                setState(() {
                                  _selectedWords[index] = value ?? false;
                                  if (!value!) {
                                    _wordImages[index] = null;
                                  }
                                });
                                if (value == true) {
                                  await _autoAssignImage(index);
                                }
                              },
                            ),
                            Text(
                              _words[index],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            if (_selectedWords[index]) ...[
                              if (_wordImages[index] != null) ...[
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.green),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _buildImagePreview(_wordImages[index]!),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ] else ...[
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text(
                    'Escribe una frase arriba',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                Row(
                  children: [
                    if (_canAddSentence())
                      ElevatedButton.icon(
                        onPressed: _addCurrentSentence,
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir frase'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addedSentences.isNotEmpty ? _generate : null,
                      child: const Text('Generar'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canAddSentence() {
    if (_words.isEmpty) return false;
    for (int i = 0; i < _selectedWords.length; i++) {
      if (_selectedWords[i]) {
        if (_wordImages[i] == null) return false;
        return true;
      }
    }
    return false;
  }

  void _generate() {
    final config = SentenceCompletionConfig(
      sentences: _addedSentences,
    );
    Navigator.pop(context, config);
  }

  Widget _buildImagePreview(CanvasImage image) {
    if (image.type == CanvasElementType.networkImage && image.imageUrl != null) {
      return Image.network(
        image.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else if (image.cachedImageBytes != null) {
      return Image.memory(
        image.cachedImageBytes!,
        fit: BoxFit.contain,
      );
    }
    return const Icon(Icons.image);
  }
}
