import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/project_data.dart';
import '../models/user_account.dart';

class UserService {
  static const _tokenKey = 'auth_token';
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://activi-production.up.railway.app',
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Restaura la sesión desde el token guardado
  Future<UserAccount?> restoreSession() async {
    if (kDebugMode) {
      print('DEBUG restoreSession: Obteniendo token...');
    }
    final token = await _getToken();
    if (token == null) {
      if (kDebugMode) {
        print('DEBUG restoreSession: No hay token guardado');
      }
      return null;
    }

    if (kDebugMode) {
      print('DEBUG restoreSession: Token encontrado, validando con /projects...');
    }

    try {
      // Validar el token intentando obtener los proyectos
      final resp = await http.get(
        _buildUri('/projects'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('DEBUG restoreSession: Status code: ${resp.statusCode}');
      }

      if (resp.statusCode != 200) {
        // Token inválido o expirado, eliminarlo
        if (kDebugMode) {
          print('DEBUG restoreSession: Token inválido (status ${resp.statusCode}), eliminando...');
        }
        await logout();
        return null;
      }

      // Decodificar JWT para obtener email e ID del usuario
      String? email;
      String? userId;

      try {
        // JWT tiene formato: header.payload.signature
        final parts = token.split('.');
        if (parts.length == 3) {
          // Decodificar el payload (segunda parte)
          final payload = parts[1];
          // Agregar padding si es necesario para Base64
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

          email = payloadMap['email'] as String?;
          userId = payloadMap['id'] as String? ?? payloadMap['sub'] as String?;

          if (kDebugMode) {
            print('DEBUG restoreSession: Email del token: $email');
            print('DEBUG restoreSession: ID del token: $userId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('DEBUG restoreSession: Error decodificando JWT: $e');
        }
      }

      // Token válido - crear UserAccount con datos del JWT
      if (kDebugMode) {
        print('DEBUG restoreSession: Token válido, sesión restaurada');
      }

      return UserAccount(
        id: userId ?? 'restored',
        username: email ?? 'Usuario',
        password: '',
        projects: [],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Restore session error: $e');
      }
      // Si hay error de conexión, mantener el token y devolver usuario
      // para que la app funcione offline
      return UserAccount(
        id: 'offline',
        username: 'Usuario',
        password: '',
        projects: [],
      );
    }
  }

  Uri _buildUri(String path) => Uri.parse('$_apiBaseUrl$path');

  Future<UserAccount?> login(String username, String password) async {
    try {
      if (kDebugMode) {
        print('DEBUG login: Iniciando login para $username');
      }
      final resp = await http.post(
        _buildUri('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': username, 'password': password}),
      );
      if (kDebugMode) {
        print('DEBUG login: Status code: ${resp.statusCode}');
      }
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;
      if (kDebugMode) {
        print('DEBUG login: Token recibido: ${token != null ? token.substring(0, 20) : "NULL"}...');
        print('DEBUG login: UserData: ${userData != null ? "OK" : "NULL"}');
      }
      if (token == null || userData == null) return null;
      if (kDebugMode) {
        print('DEBUG login: Guardando token...');
      }
      await _saveToken(token);
      if (kDebugMode) {
        print('DEBUG login: Token guardado exitosamente');
      }
      return UserAccount(
        id: userData['id'] as String,
        username: userData['email'] as String? ?? username,
        password: '',
        projects: [],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return null;
    }
  }

  String? lastError;

  Future<UserAccount?> register(String username, String password) async {
    lastError = null;
    try {
      final resp = await http.post(
        _buildUri('/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': username, 'password': password}),
      );
      if (resp.statusCode != 201) {
        try {
          final errorData = jsonDecode(resp.body) as Map<String, dynamic>;
          lastError = errorData['message'] as String? ?? 'Error desconocido';
        } catch (_) {
          lastError = 'Error en el servidor (${resp.statusCode})';
        }
        if (kDebugMode) {
          print('Register failed: $lastError');
        }
        return null;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;
      if (token == null || userData == null) return null;
      await _saveToken(token);
      return UserAccount(
        id: userData['id'] as String,
        username: userData['email'] as String? ?? username,
        password: '',
        projects: [],
      );
    } catch (e) {
      lastError = 'Error de conexión: $e';
      if (kDebugMode) {
        print('Register error: $e');
      }
      return null;
    }
  }

  Future<List<ProjectData>> fetchProjects() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final resp = await http.get(
        _buildUri('/projects'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode != 200) return [];
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.map((item) {
        final map = item as Map<String, dynamic>;
        final projectData = (map['data'] as Map<String, dynamic>? ?? {});
        projectData['id'] = map['id'];
        projectData['name'] = map['name'];
        projectData['updatedAt'] =
            projectData['updatedAt'] ?? map['updated_at']?.toString();

        // Si hay cover_image_url del backend, crear coverImage con esa URL o path
        final coverImageUrl = map['cover_image_url'] as String?;
        if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
          // Determinar si es un asset local o una URL de red
          final isAsset = coverImageUrl.startsWith('assets/');

          if (isAsset) {
            // Es una etiqueta (asset local)
            projectData['coverImage'] = {
              'id': 'cover',
              'type': 'localImage',
              'imagePath': coverImageUrl,
              'position': {'dx': 0.0, 'dy': 0.0},
              'scale': 1.0,
            };
            if (kDebugMode) {
              print('=== DEBUG: Cargando coverImage desde asset: $coverImageUrl');
            }
          } else {
            // Es una URL de red (ARASAAC)
            projectData['coverImage'] = {
              'id': 'cover',
              'type': 'networkImage',
              'imageUrl': coverImageUrl,
              'position': {'dx': 0.0, 'dy': 0.0},
              'scale': 1.0,
            };
            if (kDebugMode) {
              print('=== DEBUG: Cargando coverImage desde URL: $coverImageUrl');
            }
          }
        }

        return ProjectData.fromJson(projectData);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Fetch projects error: $e');
      }
      return [];
    }
  }

  Future<ProjectData?> saveProject(ProjectData project) async {
    final token = await _getToken();
    if (kDebugMode) {
      print('DEBUG saveProject: token = ${token != null ? "exists" : "null"}');
    }
    if (token == null) {
      if (kDebugMode) {
        print('DEBUG saveProject: No token, returning null');
      }
      return null;
    }
    try {
      final url = _buildUri('/projects');
      if (kDebugMode) {
        print('DEBUG saveProject: URL = $url');
        print('DEBUG saveProject: Project ID = ${project.id}, Name = ${project.name}');
      }

      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id': project.id,
          'name': project.name,
          'data': project.toJson(),
        }),
      );

      if (kDebugMode) {
        print('DEBUG saveProject: Response status = ${resp.statusCode}');
        print('DEBUG saveProject: Response body = ${resp.body}');
      }

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        if (kDebugMode) {
          print('DEBUG saveProject: Bad status code ${resp.statusCode}, returning null');
        }
        return null;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final projectData = (data['data'] as Map<String, dynamic>? ?? {});
      projectData['id'] = data['id'];
      projectData['name'] = data['name'];
      projectData['updatedAt'] =
          projectData['updatedAt'] ?? data['updated_at']?.toString();
      return ProjectData.fromJson(projectData);
    } catch (e) {
      if (kDebugMode) {
        print('Save project error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteProject(String projectId) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final resp = await http.delete(
        _buildUri('/projects/$projectId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('DEBUG deleteProject: Status code: ${resp.statusCode}');
      }

      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      if (kDebugMode) {
        print('Delete project error: $e');
      }
      return false;
    }
  }
}
