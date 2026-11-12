import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

/// Cliente para as rotas que exigem login: envia o token JWT em todo
/// pedido e trata o caso de sessão expirada.
class ApiClient {
  ApiClient._();

  /// Chamado quando a API responde 401 (token inválido/expirado). O main.dart
  /// define o que fazer: limpar a sessão e voltar para a tela de Login.
  static Future<void> Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 10);
  static const _uploadTimeout = Duration(seconds: 40);

  static Future<Map<String, dynamic>> get(String path) =>
      _request(path, (uri, headers) => http.get(uri, headers: headers));

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) => _request(
        path,
        (uri, headers) => http.post(
          uri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ),
      );

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) => _request(
        path,
        (uri, headers) => http.put(
          uri,
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ),
      );

  /// [body] opcional (ex: senha para confirmar a exclusão da conta).
  static Future<Map<String, dynamic>> delete(String path, [Map<String, dynamic>? body]) => _request(
        path,
        (uri, headers) => body == null
            ? http.delete(uri, headers: headers)
            : http.delete(uri, headers: {...headers, 'Content-Type': 'application/json'}, body: jsonEncode(body)),
      );

  /// Envia um arquivo (multipart/form-data). [field] é o nome do campo que a API espera.
  /// Usa bytes (e não um caminho de arquivo) para funcionar também no navegador.
  static Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
  }) =>
      _request(
        path,
        (uri, headers) async {
          final request = http.MultipartRequest('POST', uri)
            ..headers.addAll(headers)
            ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
          return http.Response.fromStream(await request.send());
        },
        timeout: _uploadTimeout,
      );

  static Future<Map<String, dynamic>> _request(
    String path,
    Future<http.Response> Function(Uri uri, Map<String, String> headers) send, {
    Duration timeout = _timeout,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      await onUnauthorized?.call();
      throw ApiException('Sessão expirada. Faça login novamente.', statusCode: 401);
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    http.Response response;
    try {
      response = await send(uri, {'Authorization': 'Bearer $token'}).timeout(timeout);
    } on TimeoutException {
      throw ApiException('Tempo de conexão esgotado. Tente novamente.');
    } catch (_) {
      throw ApiException('Não foi possível conectar ao servidor. Verifique sua internet e se a API está rodando.');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode == 404) {
        throw ApiException(
          'A API não reconheceu esta rota. Atualize os arquivos do backend e reinicie com "npm run dev".',
          statusCode: 404,
        );
      }
      throw ApiException('Resposta inesperada do servidor.', statusCode: response.statusCode);
    }

    if (response.statusCode == 401) {
      await onUnauthorized?.call();
      throw ApiException(data['error'] as String? ?? 'Sessão expirada. Faça login novamente.', statusCode: 401);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error'] as String? ?? 'Ocorreu um erro. Tente novamente.',
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
