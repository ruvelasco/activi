import 'dart:convert';
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

  Uri _buildUri(String path) => Uri.parse('$_apiBaseUrl$path');

  Future<UserAccount?> login(String username, String password) async {
    try {
      final resp = await http.post(
        _buildUri('/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': username, 'password': password}),
      );
      if (resp.statusCode != 200) return null;
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
}
