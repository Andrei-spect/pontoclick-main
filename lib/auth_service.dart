import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Erro vindo da API (mensagem já pronta para mostrar ao usuário) ou de
/// problema de conexão (servidor fora do ar, sem internet, etc.).
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
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

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {required int expectedStatus}) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
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
      throw ApiException(data['error'] as String? ?? 'Ocorreu um erro. Tente novamente.');
    }
    return data;
  }

  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
