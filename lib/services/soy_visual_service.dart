import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/soy_visual.dart';

enum SoyVisualCategory { photos, sheets }

extension _SoyVisualCategoryX on SoyVisualCategory {
  String get apiType => this == SoyVisualCategory.photos ? 'photo' : 'sheet';
}

class SoyVisualService {
  static const String resourcesUrl = 'https://www.soyvisual.org/api/v1/resources.json';
  static const String token = '6B5165B822AE4400813CF4EC490BF6AB';

  Future<List<SoyVisualElement>> search(
    String query, {
    SoyVisualCategory category = SoyVisualCategory.photos,
  }) async {
    if (query.isEmpty) return [];

    try {
      final params = <String, String>{
        'token': token,
        'items_per_page': '20',
        'matching': 'contain',
        'type': category.apiType,
      };

      if (query.isNotEmpty) {
        params['query'] = query;
      }

      final url = Uri.parse(resourcesUrl).replace(queryParameters: params);

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
