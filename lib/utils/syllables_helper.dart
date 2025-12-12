import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SyllablesHelper {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://activi-production.up.railway.app',
  );

  static Future<String> obtenerSilabas(String palabra) async {
    // Usar el backend como proxy para evitar CORS
    final url = Uri.parse(
      '$_apiBaseUrl/syllables?word=${Uri.encodeComponent(palabra)}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['syllables'] != null && data['syllables'] is List) {
          // Reemplaza los signos de interrogación por la vocal acentuada si la palabra original la tiene
          List<String> syllables = (data['syllables'] as List)
              .map((s) => s is String ? s : s.toString())
              .toList();

          // Si la palabra original tiene una vocal acentuada, intenta corregir la sílaba
          for (int i = 0; i < syllables.length; i++) {
            if (syllables[i].contains('?')) {
              // Busca la sílaba correcta en la palabra original
              for (int j = 0; j < palabra.length; j++) {
                if ('áéíóúÁÉÍÓÚ'.contains(palabra[j])) {
                  syllables[i] = syllables[i].replaceAll('?', palabra[j]);
                  break;
                }
              }
            }
          }
          return syllables.join('*');
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo sílabas de "$palabra": $e');
    }
    return '';
  }

  static List<String> separarSilabas(String silabasConAsteriscos) {
    if (silabasConAsteriscos.isEmpty) return [];
    return silabasConAsteriscos.split('*');
  }
}
