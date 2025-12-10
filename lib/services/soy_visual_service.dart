import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/soy_visual.dart';

enum SoyVisualCategory { photos, sheets }

extension _SoyVisualCategoryX on SoyVisualCategory {
  String get apiType => this == SoyVisualCategory.photos ? 'photo' : 'sheet';
}

class SoyVisualService {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kDebugMode ? 'http://localhost:3000' : 'https://activi-production.up.railway.app',
  );

  Future<List<SoyVisualElement>> search(
    String query, {
    SoyVisualCategory category = SoyVisualCategory.photos,
  }) async {
    // Limpiar el query de espacios y caracteres extraños
    final cleanQuery = query.trim().replaceAll(RegExp(r'[^\w\s]'), '');

    if (cleanQuery.isEmpty) return [];

    try {
      final params = <String, String>{
        'query': cleanQuery,
        'type': category.apiType,
        'items_per_page': '20',
      };

      final url = Uri.parse('$_apiBaseUrl/soyvisual/search').replace(queryParameters: params);

      debugPrint('SoyVisual URL: $url');

      final response = await http.get(url);

      debugPrint('SoyVisual Status Code: ${response.statusCode}');
      final bodyPreview = response.body.substring(0, response.body.length > 200 ? 200 : response.body.length);
      debugPrint('SoyVisual Response: $bodyPreview');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('SoyVisual Found ${data.length} results');
        return data.map((item) => SoyVisualElement.fromJson(item)).toList();
      }
      debugPrint('SoyVisual Error: Status ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('SoyVisual Exception: $e');
      return [];
    }
  }
}
