import 'project_data.dart';

class UserAccount {
  final String id;
  final String username;
  final String password;
  final List<ProjectData> projects;

  UserAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.projects,
  });

  UserAccount copyWith({
    String? id,
    String? username,
    String? password,
    List<ProjectData>? projects,
  }) {
    return UserAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      projects: projects ?? this.projects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'projects': projects.map((p) => p.toJson()).toList(),
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      username: json['username'] as String,
      password: json['password'] as String? ?? '',
      projects: (json['projects'] as List<dynamic>? ?? [])
          .map((p) => ProjectData.fromJson(p))
          .toList(),
    );
  }
}
