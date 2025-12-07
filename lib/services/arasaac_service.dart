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
  }) async {
    final allKeywords = await getAllKeywords();
    final syllableLower = syllable.toLowerCase();
    final matchingWords = <String>[];

    for (final keyword in allKeywords) {
      final wordLower = keyword.toLowerCase();

      if (position == 'start' && wordLower.startsWith(syllableLower)) {
        matchingWords.add(keyword);
      } else if (position == 'end' && wordLower.endsWith(syllableLower)) {
        matchingWords.add(keyword);
      }

      if (matchingWords.length >= limit) break;
    }

    return matchingWords;
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
