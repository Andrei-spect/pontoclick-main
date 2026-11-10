import 'package:flutter/foundation.dart';
import 'api_config.dart';

/// Dados do usuário logado, como vêm da API (GET /users/me).
class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? company;
  final String? photoUrl;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.company,
    this.photoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        role: json['role'] as String?,
        company: json['company'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'company': company,
        'photoUrl': photoUrl,
      };

  /// Iniciais para o avatar: "João Silva" -> "JS", "Maria" -> "M".
  static String initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get initials => initialsFor(name);

  /// Endereço completo da foto. A API devolve só o caminho (ex: /uploads/avatars/1-ab.jpg),
  /// então juntamos com a URL da API — que muda conforme onde o app roda.
  String? get photoFullUrl {
    final url = photoUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url; // já é um endereço completo (ex: armazenamento na nuvem)
    return '${ApiConfig.baseUrl}$url';
  }

  /// "TechCorp • Desenvolvedor" (ou só um dos dois; vazio se nenhum foi preenchido).
  String get subtitle => [company, role].where((v) => v != null && v.isNotEmpty).join(' • ');
}

/// Usuário logado no momento, compartilhado entre as telas. Quem mostra
/// nome/iniciais escuta este notifier e se atualiza sozinho quando o
/// perfil é editado.
class UserSession {
  UserSession._();

  static final ValueNotifier<UserProfile?> current = ValueNotifier<UserProfile?>(null);

  /// true = o perfil mostrado veio do servidor nesta sessão do app.
  /// false = são só os dados salvos no aparelho (o servidor ainda não respondeu).
  static final ValueNotifier<bool> syncedWithServer = ValueNotifier<bool>(false);
}
