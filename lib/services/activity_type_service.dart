import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_type.dart';

class ActivityTypeService {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://activi-production.up.railway.app',
  );

  String? lastError;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Obtener todas las actividades (ordenadas por order)
  Future<List<ActivityType>> getAll() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/activity-types'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final activities = data
            .map((item) => ActivityType.fromJson(item as Map<String, dynamic>))
            .toList();

        // Ordenar por order
        activities.sort((a, b) => a.order.compareTo(b.order));
        return activities;
      } else if (response.statusCode == 404) {
        // Si no hay actividades en el backend, retornar las por defecto
        return _getDefaultActivities();
      } else {
        lastError = 'Error al obtener actividades: ${response.statusCode}';
        return _getDefaultActivities();
      }
    } catch (e) {
      lastError = 'Error de conexión: $e';
      // Retornar actividades por defecto en caso de error
      return _getDefaultActivities();
    }
  }

  /// Obtener solo las actividades habilitadas
  Future<List<ActivityType>> getEnabled() async {
    final all = await getAll();
    return all.where((activity) => activity.isEnabled).toList();
  }

  /// Obtener una actividad por su nombre interno
  Future<ActivityType?> getByName(String name) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/activity-types/name/$name'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        return ActivityType.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      } else {
        lastError = 'Actividad no encontrada';
        return null;
      }
    } catch (e) {
      lastError = 'Error de conexión: $e';
      return null;
    }
  }

  /// Crear una nueva actividad (requiere autenticación de admin)
  Future<ActivityType?> create(ActivityType activity) async {
    try {
      final token = await _getToken();
      if (token == null) {
        lastError = 'No autenticado';
        return null;
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/activity-types'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(activity.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ActivityType.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      } else {
        lastError = 'Error al crear actividad: ${response.body}';
        return null;
      }
    } catch (e) {
      lastError = 'Error de conexión: $e';
      return null;
    }
  }

  /// Actualizar una actividad existente (requiere autenticación de admin)
  Future<bool> update(ActivityType activity) async {
    try {
      final token = await _getToken();
      if (token == null) {
        lastError = 'No autenticado';
        return false;
      }

      final response = await http.put(
        Uri.parse('$_apiBaseUrl/activity-types/${activity.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(
          activity.copyWith(updatedAt: DateTime.now()).toJson(),
        ),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        lastError = 'Error al actualizar: ${response.body}';
        return false;
      }
    } catch (e) {
      lastError = 'Error de conexión: $e';
      return false;
    }
  }

  /// Eliminar una actividad (requiere autenticación de admin)
  Future<bool> delete(String id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        lastError = 'No autenticado';
        return false;
      }

      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/activity-types/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        lastError = 'Error al eliminar: ${response.body}';
        return false;
      }
    } catch (e) {
      lastError = 'Error de conexión: $e';
      return false;
    }
  }

  /// Actualizar el orden de múltiples actividades (requiere autenticación de admin)
  Future<bool> updateOrder(List<ActivityType> activities) async {
    try {
      final token = await _getToken();
      if (token == null) {
        lastError = 'No autenticado';
        return false;
      }

      final response = await http.put(
        Uri.parse('$_apiBaseUrl/activity-types/reorder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'activities': activities.map((a) => {'id': a.id, 'order': a.order}).toList(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        lastError = 'Error al reordenar: ${response.body}';
        return false;
      }
    } catch (e) {
      lastError = 'Error de conexión: $e';
      return false;
    }
  }

  /// Obtener las actividades por defecto (datos actuales del código)
  /// Se usan cuando no hay conexión o no hay datos en el backend
  List<ActivityType> _getDefaultActivities() {
    return [
      ActivityType(
        id: 'pack',
        name: 'activity_pack',
        title: 'Pack de Actividades',
        description: 'Genera múltiples actividades de forma automática',
        infoTooltip:
            'Genera múltiples actividades de forma automática. Selecciona qué tipos de actividades quieres crear y se generarán todas usando las imágenes del canvas.',
        iconName: 'auto_awesome',
        colorValue: 0xFF6A1B9A, // deepPurple[700]
        order: 0,
        isHighlighted: true,
        category: 'pack',
      ),
      ActivityType(
        id: 'shadow_matching',
        name: 'shadow_matching',
        title: 'Relacionar Sombras',
        description: 'Une cada imagen con su sombra',
        infoTooltip:
            'Crea una actividad con imágenes y sombras en 3 columnas con puntos de unión. El alumno traza líneas entre los puntos para relacionar cada imagen con su sombra.',
        iconName: 'link',
        colorValue: 0xFF1976D2, // blue[700]
        order: 1,
        category: 'individual',
      ),
      ActivityType(
        id: 'puzzle',
        name: 'puzzle',
        title: 'Puzle',
        description: 'Puzle de 4x4 para recortar',
        infoTooltip:
            'Genera un puzle de 4x4 (16 piezas) con la imagen del canvas. Perfecto para imprimir, recortar y que el alumno lo monte.',
        iconName: 'extension',
        colorValue: 0xFFF57C00, // orange[700]
        order: 2,
        category: 'individual',
      ),
      ActivityType(
        id: 'writing_practice',
        name: 'writing_practice',
        title: 'Práctica de Escritura',
        description: 'Imágenes con pauta para escribir',
        infoTooltip:
            'Organiza las imágenes en filas y columnas con pauta debajo de cada una para que el alumno escriba el nombre.',
        iconName: 'edit_note',
        colorValue: 0xFF388E3C, // green[700]
        order: 3,
        category: 'individual',
      ),
      ActivityType(
        id: 'counting_practice',
        name: 'counting_practice',
        title: 'Práctica de Conteo',
        description: 'Contar elementos repetidos',
        infoTooltip:
            'Crea ejercicios con cada imagen repetida un número aleatorio de veces en su caja, con espacio para escribir la cantidad.',
        iconName: 'calculate',
        colorValue: 0xFF7B1FA2, // purple[700]
        order: 4,
        category: 'individual',
      ),
      ActivityType(
        id: 'phonological_awareness',
        name: 'phonological_awareness',
        title: 'Conciencia Fonológica',
        description: 'Separar palabras en sílabas',
        infoTooltip:
            'Separa las palabras en sílabas. Muestra la imagen, las sílabas separadas y líneas en pauta escolar para que el alumno repase cada sílaba.',
        iconName: 'hearing',
        colorValue: 0xFF6A1B9A, // deepPurple[700]
        order: 5,
        category: 'individual',
      ),
      ActivityType(
        id: 'phonological_board',
        name: 'phonological_board',
        title: 'Tablero Fonológico (recortable)',
        description: 'Tablero con puzle y recortables',
        infoTooltip:
            'Crea un tablero vertical con zona de puzle 2x2 y huecos para palabra, sílabas y letras, más otra hoja con las piezas y tarjetas recortables listas para imprimir.',
        iconName: 'view_column',
        colorValue: 0xFFE64A19, // deepOrange[700]
        order: 6,
        category: 'individual',
      ),
      ActivityType(
        id: 'series',
        name: 'series',
        title: 'Series',
        description: 'Continuar patrones ABAB',
        infoTooltip:
            'Muestra una serie de dos elementos alternados (ABAB...) y deja espacios en blanco para que el alumno continúe el patrón.',
        iconName: 'auto_awesome',
        colorValue: 0xFFC2185B, // pink[700]
        order: 7,
        category: 'individual',
      ),
      ActivityType(
        id: 'symmetry',
        name: 'symmetry',
        title: 'Simetrías',
        description: 'Encontrar objetos iguales al modelo',
        infoTooltip:
            'Muestra un objeto modelo y una cuadrícula 5x5 con el mismo objeto en diferentes orientaciones (rotado, volteado). El alumno debe encontrar los iguales al modelo.',
        iconName: 'flip',
        colorValue: 0xFF00796B, // teal[700]
        order: 8,
        category: 'individual',
      ),
      ActivityType(
        id: 'phrases',
        name: 'phrases',
        title: 'Frases',
        description: 'Frases con pictogramas',
        infoTooltip:
            'Muestra una imagen grande arriba y debajo la frase convertida en pictogramas para que el alumno lea o reconstruya.',
        iconName: 'forum_outlined',
        colorValue: 0xFF455A64, // blueGrey[700]
        order: 9,
        category: 'individual',
      ),
      ActivityType(
        id: 'card',
        name: 'card',
        title: 'Tarjeta',
        description: 'Tarjeta con imagen y texto',
        infoTooltip:
            'Genera una tarjeta con la imagen a la izquierda y texto (título + párrafo) a la derecha.',
        iconName: 'credit_card',
        colorValue: 0xFFE64A19, // deepOrange[700]
        order: 10,
        category: 'individual',
      ),
      ActivityType(
        id: 'syllable_vocabulary',
        name: 'syllable_vocabulary',
        title: 'Vocabulario por Sílaba',
        description: 'Palabras que empiezan con una sílaba',
        infoTooltip:
            'Genera automáticamente una lista de palabras con pictogramas de ARASAAC que empiezan con la sílaba que elijas (pa, ma, sa, etc.). No requiere añadir imágenes previamente.',
        iconName: 'abc',
        colorValue: 0xFF303F9F, // indigo[700]
        order: 11,
        category: 'individual',
      ),
      ActivityType(
        id: 'semantic_field',
        name: 'semantic_field',
        title: 'Campo Semántico',
        description: 'Palabras relacionadas temáticamente',
        infoTooltip:
            'Añade una imagen de ARASAAC con texto y genera automáticamente una cuadrícula 5x5 con palabras relacionadas del mismo campo semántico (animales, frutas, ropa, etc.).',
        iconName: 'category',
        colorValue: 0xFFFFA000, // amber[700]
        order: 12,
        category: 'individual',
      ),
      ActivityType(
        id: 'instructions',
        name: 'instructions',
        title: 'Instrucciones (Rodea)',
        description: 'Rodear elementos según instrucciones',
        infoTooltip:
            'Genera una actividad con instrucciones tipo "Rodea 2 casas, 3 árboles". Los objetos aparecen distribuidos aleatoriamente con algunos distractores.',
        iconName: 'radio_button_checked',
        colorValue: 0xFFD32F2F, // red[700]
        order: 13,
        category: 'individual',
      ),
      ActivityType(
        id: 'classification',
        name: 'classification',
        title: 'Clasificación',
        description: 'Clasificar objetos en categorías',
        infoTooltip:
            'Crea una actividad de clasificación en 2 hojas: una con 2 cuadrados de categorías y otra con 10 objetos relacionados para recortar y clasificar. Requiere 2 imágenes de ARASAAC en el canvas.',
        iconName: 'dashboard',
        colorValue: 0xFF0097A7, // cyan[700]
        order: 14,
        category: 'individual',
      ),
      ActivityType(
        id: 'phonological_squares',
        name: 'phonological_squares',
        title: 'Cuadrados Fonológicos',
        description: 'Pintar cuadrados por cada letra',
        infoTooltip:
            'Muestra las imágenes del canvas con un rectángulo de 10 cuadrados (2 filas x 5 columnas) debajo de cada una. El alumno pinta un cuadrado por cada letra de la palabra.',
        iconName: 'grid_4x4',
        colorValue: 0xFF0288D1, // lightBlue[700]
        order: 15,
        category: 'individual',
        isNew: true,
      ),
      ActivityType(
        id: 'crossword',
        name: 'crossword',
        title: 'Crucigrama',
        description: 'Crucigrama con las palabras',
        infoTooltip:
            'Genera un crucigrama usando las palabras de las imágenes del canvas. Las imágenes sirven como pistas numeradas para completar el crucigrama.',
        iconName: 'apps',
        colorValue: 0xFF5D4037, // brown[700]
        order: 16,
        category: 'individual',
        isNew: true,
      ),
      ActivityType(
        id: 'word_search',
        name: 'word_search',
        title: 'Sopa de Letras',
        description: 'Encontrar palabras escondidas',
        infoTooltip:
            'Crea una sopa de letras donde el alumno debe encontrar las palabras de las imágenes del canvas escondidas en una cuadrícula de 15x15 letras.',
        iconName: 'search',
        colorValue: 0xFF6A1B9A, // deepPurple[700]
        order: 17,
        category: 'individual',
        isNew: true,
      ),
      ActivityType(
        id: 'sentence_completion',
        name: 'sentence_completion',
        title: 'Completar Frases',
        description: 'Frases con espacios en blanco',
        infoTooltip:
            'Genera frases simples con las imágenes del canvas. Cada página muestra un modelo de frase completa y debajo la misma frase con espacios en blanco para completar. Incluye una página con recortables.',
        iconName: 'edit_note',
        colorValue: 0xFF00796B, // teal[700]
        order: 18,
        category: 'individual',
        isNew: true,
      ),
    ];
  }
}
