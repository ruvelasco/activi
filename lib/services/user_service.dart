import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/project_data.dart';
import '../models/user_account.dart';

class UserService {
  static const _storageFile = 'users_projects.json';

  Future<File> _getStorageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_storageFile');
  }

  Future<List<UserAccount>> loadUsers() async {
    final file = await _getStorageFile();
    if (!await file.exists()) {
      return [];
    }
    final content = await file.readAsString();
    if (content.isEmpty) {
      return [];
    }

    final data = jsonDecode(content) as List<dynamic>;
    return data.map((item) => UserAccount.fromJson(item)).toList();
  }

  Future<void> saveUsers(List<UserAccount> users) async {
    final file = await _getStorageFile();
    final payload = jsonEncode(users.map((u) => u.toJson()).toList());
    await file.writeAsString(payload, flush: true);
  }

  Future<UserAccount?> login(String username, String password) async {
    final users = await loadUsers();
    try {
      return users.firstWhere(
        (u) => u.username == username && u.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserAccount?> register(String username, String password) async {
    final users = await loadUsers();
    final existing =
        users.any((element) => element.username.toLowerCase() == username.toLowerCase());
    if (existing) {
      return null;
    }

    final newUser = UserAccount(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      username: username,
      password: password,
      projects: [],
    );
    users.add(newUser);
    await saveUsers(users);
    return newUser;
  }

  Future<void> upsertUser(UserAccount user) async {
    final users = await loadUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await saveUsers(users);
  }

  Future<List<ProjectData>> fetchProjects(String userId) async {
    final users = await loadUsers();
    final user = users.firstWhere((u) => u.id == userId, orElse: () => UserAccount(id: '', username: '', password: '', projects: []));
    return user.projects;
  }
}
