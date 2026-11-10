import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'user_profile.dart';
import 'notification_service.dart';

/// Erro vindo da API (mensagem já pronta para mostrar ao usuário) ou de
/// problema de conexão (servidor fora do ar, sem internet, etc.).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    final data = await _post('/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    }, expectedStatus: 201);

    await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
    return data;
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final data = await _post('/auth/login', {'email': email, 'password': password}, expectedStatus: 200);
    await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
    return data;
  }

  /// POST /auth/forgot-password — pede um código de 6 dígitos, enviado para o e-mail.
  /// A API responde sucesso mesmo se o e-mail não tiver conta (não revela cadastros).
  /// Prazo maior que o normal: o servidor só responde depois de enviar o e-mail.
  Future<void> requestPasswordReset(String email) async {
    await _post('/auth/forgot-password', {'email': email}, expectedStatus: 200, timeout: const Duration(seconds: 30));
  }

  /// POST /auth/reset-password — confirma o código recebido por e-mail e define a nova senha.
  Future<void> resetPassword({required String email, required String code, required String newPassword}) async {
    await _post('/auth/reset-password', {'email': email, 'code': code, 'newPassword': newPassword}, expectedStatus: 200);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {required int expectedStatus, Duration timeout = _timeout}) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw ApiException('Tempo de conexão esgotado. Tente novamente.');
    } catch (_) {
      throw ApiException('Não foi possível conectar ao servidor. Verifique sua internet e se a API está rodando.');
    }

    late final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Resposta inesperada do servidor.');
    }

    if (response.statusCode != expectedStatus) {
      throw ApiException(data['error'] as String? ?? 'Ocorreu um erro. Tente novamente.', statusCode: response.statusCode);
    }
    return data;
  }

  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
    UserSession.current.value = UserProfile.fromJson(user);
    UserSession.syncedWithServer.value = true; // acabou de vir da API (login/cadastro)
  }

  /// Guarda o perfil atualizado (usado após editar o perfil).
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Troca o token salvo (a API emite um novo ao trocar a senha; o antigo deixa de valer).
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Usado no início do app para saber se já existe uma sessão salva.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    // Quem saiu não deve continuar recebendo lembretes neste aparelho.
    await NotificationService.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    UserSession.current.value = null;
    UserSession.syncedWithServer.value = false;
  }
}
