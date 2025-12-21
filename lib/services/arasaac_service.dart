import 'dart:convert';
import 'package:http/http.dart' as http;

// Configuración para personalización de pictogramas ARASAAC
class ArasaacConfig {
  final String language; // Idioma (es, en, fr, etc.)
  final bool color; // Color (true) o blanco y negro (false)
  final bool skin; // Mostrar piel (true) o sin piel (false)
  final bool hair; // Mostrar pelo (true) o sin pelo (false)
  final bool plural; // Plural (true) o singular (false)
  final bool past; // Tiempo pasado (true) o presente (false)
  final bool action; // Mostrar acción (true) o estático (false)
  final String? backgroundColor; // Color de fondo en hexadecimal (sin #)
  final bool identifier; // Mostrar identificador/número (true) o sin identificador (false)

  const ArasaacConfig({
    this.language = 'es',
    this.color = true,
    this.skin = true,
    this.hair = true,
    this.plural = false,
    this.past = false,
    this.action = false,
    this.backgroundColor,
    this.identifier = false,
  });

  ArasaacConfig copyWith({
    String? language,
    bool? color,
    bool? skin,
    bool? hair,
    bool? plural,
    bool? past,
    bool? action,
    String? backgroundColor,
    bool? identifier,
  }) {
    return ArasaacConfig(
      language: language ?? this.language,
      color: color ?? this.color,
      skin: skin ?? this.skin,
      hair: hair ?? this.hair,
      plural: plural ?? this.plural,
      past: past ?? this.past,
      action: action ?? this.action,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      identifier: identifier ?? this.identifier,
    );
  }
}

class ArasaacService {
  static const String baseUrl = 'https://api.arasaac.org/v1';
  ArasaacConfig config;

  ArasaacService({this.config = const ArasaacConfig()});

  Future<List<ArasaacImage>> searchPictograms(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pictograms/${config.language}/search/$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => ArasaacImage.fromJson(item, this)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  String getPictogramUrl(int id) {
    final params = <String, String>{
      'download': 'false',
    };

    if (!config.color) params['color'] = 'false';
    if (!config.skin) params['skin'] = 'false';
    if (!config.hair) params['hair'] = 'false';
    if (config.plural) params['plural'] = 'true';
    if (config.past) params['past'] = 'true';
    if (config.action) params['action'] = 'true';
    if (config.identifier) params['identifier'] = 'true';
    if (config.backgroundColor != null) {
      params['backgroundColor'] = config.backgroundColor!;
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    return '$baseUrl/pictograms/$id?$queryString';
  }

  // Buscar pictogramas relacionados por ID
  Future<List<ArasaacImage>> searchRelatedPictograms(int pictogramId) async {
    try {
      print('DEBUG ArasaacService: Buscando relacionados para ID $pictogramId');

      // Obtener información del pictograma incluyendo categorías
      final detailUrl = '$baseUrl/pictograms/${config.language}/$pictogramId';
      print('DEBUG ArasaacService: URL de detalles: $detailUrl');

      final response = await http.get(Uri.parse(detailUrl));

      if (response.statusCode != 200) {
        print('DEBUG ArasaacService: Error status ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);

      // Obtener categorías
      final categories = (data['categories'] as List<dynamic>?)?.cast<String>() ?? [];
      print('DEBUG ArasaacService: Categorías encontradas: $categories');

      if (categories.isEmpty) {
        print('DEBUG ArasaacService: No hay categorías para este pictograma');
        return [];
      }

      // Buscar pictogramas usando las categorías
      final relatedImages = <ArasaacImage>[];

      // Usar las primeras 2 categorías más específicas
      final searchCategories = categories
          .where((cat) => !cat.contains('core vocabulary'))
          .take(2)
          .toList();

      print('DEBUG ArasaacService: Buscando con categorías: $searchCategories');

      for (final category in searchCategories) {
        try {
          print('DEBUG ArasaacService: Buscando categoría "$category"');
          final categoryResults = await searchPictograms(category);
          print('DEBUG ArasaacService: Encontrados ${categoryResults.length} resultados para "$category"');

          // Filtrar el pictograma original y tomar hasta 10 por categoría
          final filtered = categoryResults
              .where((img) => img.id != pictogramId)
              .take(10)
              .toList();

          print('DEBUG ArasaacService: Añadiendo ${filtered.length} imágenes filtradas');
          relatedImages.addAll(filtered);
        } catch (e) {
          print('DEBUG ArasaacService: Error buscando categoría "$category": $e');
        }
      }

      print('DEBUG ArasaacService: Total imágenes relacionadas: ${relatedImages.length}');
      return relatedImages;
    } catch (e) {
      print('DEBUG ArasaacService: Error general: $e');
      return [];
    }
  }

  // Obtener palabras relacionadas buscando por categorías compartidas
  Future<List<String>> getRelatedWords(String word) async {
    try {
      // Primero, buscar el pictograma
      final searchResults = await searchPictograms(word);
      if (searchResults.isEmpty) {
        print('DEBUG: No se encontró pictograma para: $word');
        return [];
      }

      final pictogramId = searchResults.first.id;
      print('DEBUG: Pictograma ID: $pictogramId para palabra: $word');

      // Obtener información del pictograma incluyendo categorías
      final detailUrl = '$baseUrl/pictograms/${config.language}/$pictogramId';
      print('DEBUG: URL detalles: $detailUrl');

      final response = await http.get(Uri.parse(detailUrl));

      if (response.statusCode != 200) {
        print('DEBUG: Error al obtener detalles: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      print('DEBUG: Datos del pictograma: ${data.keys}');

      // Obtener categorías
      final categories = (data['categories'] as List<dynamic>?)?.cast<String>() ?? [];

      print('DEBUG: Categories: $categories');

      if (categories.isEmpty) {
        print('DEBUG: No hay categorías');
        return [];
      }

      // Buscar pictogramas usando las categorías más específicas
      final relatedWords = <String>{};

      // Usar las primeras 2-3 categorías para buscar (priorizando las más específicas)
      final searchCategories = categories
          .where((cat) => !cat.contains('core vocabulary'))
          .take(3)
          .toList();

      print('DEBUG: Buscando con categorías: $searchCategories');

      for (final category in searchCategories) {
        try {
          // Buscar pictogramas por categoría
          final categoryResults = await searchPictograms(category);
          print('DEBUG: Categoría "$category" encontró ${categoryResults.length} resultados');

          for (final result in categoryResults.take(20)) {
            // Añadir la primera keyword de cada resultado
            if (result.keywords.isNotEmpty) {
              final keyword = result.keywords.first.toLowerCase();
              // No añadir la palabra original
              if (keyword != word.toLowerCase()) {
                relatedWords.add(keyword);
              }
            }
          }
        } catch (e) {
          print('DEBUG: Error buscando categoría $category: $e');
        }
      }

      print('DEBUG: Palabras relacionadas encontradas: ${relatedWords.length}');
      return relatedWords.toList();
    } catch (e) {
      print('DEBUG: Error en getRelatedWords: $e');
      return [];
    }
  }

  // Obtener todas las keywords disponibles en ARASAAC
  Future<List<String>> getAllKeywords() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/keywords/${config.language}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // La API devuelve un objeto con una propiedad "words" que contiene el array
        final List<dynamic> words = data['words'] as List<dynamic>? ?? [];
        return words.cast<String>();
      }
      return [];
    } catch (e) {
      print('DEBUG: Error obteniendo keywords: $e');
      return [];
    }
  }

  // Filtrar keywords por sílaba
  Future<List<String>> getWordsBySyllable({
    required String syllable,
    required String position, // 'start' o 'end'
    int limit = 50,
    bool coreVocabularyOnly = false, // Filtrar solo vocabulario nuclear
  }) async {
    print('DEBUG getWordsBySyllable: syllable=$syllable, position=$position, limit=$limit, coreVocabularyOnly=$coreVocabularyOnly');

    final allKeywords = await getAllKeywords();
    print('DEBUG getWordsBySyllable: Total keywords disponibles: ${allKeywords.length}');

    final syllableLower = syllable.toLowerCase();
    final matchingWords = <String>[];
    int checkedCount = 0;
    int matchedBySyllable = 0;

    for (final keyword in allKeywords) {
      final wordLower = keyword.toLowerCase();
      bool matches = false;

      if (position == 'start' && wordLower.startsWith(syllableLower)) {
        matches = true;
        matchedBySyllable++;
      } else if (position == 'end' && wordLower.endsWith(syllableLower)) {
        matches = true;
        matchedBySyllable++;
      }

      if (!matches) continue;

      // Si se requiere vocabulario nuclear, verificar que la palabra tenga la categoría
      if (coreVocabularyOnly) {
        checkedCount++;
        if (checkedCount % 10 == 0) {
          print('DEBUG getWordsBySyllable: Verificadas $checkedCount palabras, encontradas ${matchingWords.length} con core vocabulary');
        }

        final hasCoreVocabulary = await _hasCoreVocabularyTag(keyword);
        if (!hasCoreVocabulary) continue;

        print('DEBUG getWordsBySyllable: ✓ "$keyword" tiene core vocabulary');
      }

      // Verificar que no sea demasiado similar a palabras ya añadidas
      // (para evitar maestro/maestra, niño/niña, etc.)
      if (_isSimilarToExisting(wordLower, matchingWords)) {
        print('DEBUG getWordsBySyllable: ✗ "$keyword" es muy similar a una palabra ya añadida');
        continue;
      }

      matchingWords.add(keyword);

      if (matchingWords.length >= limit) break;
    }

    print('DEBUG getWordsBySyllable: Total palabras con sílaba: $matchedBySyllable');
    print('DEBUG getWordsBySyllable: Palabras verificadas: $checkedCount');
    print('DEBUG getWordsBySyllable: Palabras encontradas con core vocabulary: ${matchingWords.length}');

    return matchingWords;
  }

  // Verificar si una palabra es muy similar a las ya existentes
  // para evitar duplicados como maestro/maestra, niño/niña, etc.
  bool _isSimilarToExisting(String word, List<String> existingWords) {
    final wordLower = word.toLowerCase();

    for (final existing in existingWords) {
      final existingLower = existing.toLowerCase();

      // Obtener la longitud mínima para comparar
      final minLen = wordLower.length < existingLower.length ? wordLower.length : existingLower.length;

      // Si comparten al menos los primeros 5 caracteres (o el 80% de la palabra más corta)
      final compareLength = minLen > 5 ? 5 : (minLen * 0.8).ceil();

      if (minLen >= compareLength) {
        final wordPrefix = wordLower.substring(0, compareLength);
        final existingPrefix = existingLower.substring(0, compareLength);

        if (wordPrefix == existingPrefix) {
          return true; // Son muy similares
        }
      }
    }

    return false;
  }

  // Verificar si una palabra tiene el tag "core vocabulary"
  Future<bool> _hasCoreVocabularyTag(String word) async {
    try {
      // Buscar el pictograma
      final searchResults = await searchPictograms(word);
      if (searchResults.isEmpty) {
        print('DEBUG _hasCoreVocabularyTag: No se encontró pictograma para "$word"');
        return false;
      }

      final pictogramId = searchResults.first.id;

      // Obtener detalles del pictograma
      final detailUrl = '$baseUrl/pictograms/${config.language}/$pictogramId';
      final response = await http.get(Uri.parse(detailUrl));

      if (response.statusCode != 200) {
        print('DEBUG _hasCoreVocabularyTag: Error HTTP ${response.statusCode} para "$word"');
        return false;
      }

      final data = json.decode(response.body);
      final categories = (data['categories'] as List<dynamic>?)?.cast<String>() ?? [];

      // Debug: Mostrar las categorías de la primera palabra
      if (categories.isNotEmpty) {
        print('DEBUG _hasCoreVocabularyTag: "$word" tiene categorías: $categories');
      }

      // Verificar si tiene "core vocabulary" en las categorías
      final hasCoreVocab = categories.any((cat) => cat.toLowerCase().contains('core vocabulary') || cat.toLowerCase().contains('vocabulario'));

      return hasCoreVocab;
    } catch (e) {
      print('DEBUG _hasCoreVocabularyTag: Error verificando "$word": $e');
      return false;
    }
  }
}

class ArasaacImage {
  final int id;
  final List<String> keywords;
  final ArasaacService service;

  ArasaacImage({
    required this.id,
    required this.keywords,
    required this.service,
  });

  factory ArasaacImage.fromJson(Map<String, dynamic> json, ArasaacService service) {
    final keywordsList = json['keywords'] as List<dynamic>? ?? [];
    final keywords = keywordsList
        .map((item) => item['keyword'] as String? ?? '')
        .where((keyword) => keyword.isNotEmpty)
        .toList();

    return ArasaacImage(
      id: json['_id'] as int,
      keywords: keywords,
      service: service,
    );
  }

  String get imageUrl => service.getPictogramUrl(id);
}
