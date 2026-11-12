import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'user_profile.dart';

class UserService {
  /// DELETE /users/me — exclui a conta e todos os dados no servidor (sem volta).
  /// Depois apaga do aparelho o que era desta conta (cache de pontos, fila
  /// offline, locais, preferências) e encerra a sessão.
  Future<void> deleteAccount({required String password}) async {
    final user = await AuthService.getUser();
    await ApiClient.delete('/users/me', {'password': password});

    final id = user?['id'];
    if (id != null) {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where((k) => k.endsWith(':$id')).toList()) {
        await prefs.remove(key);
      }
    }
    await AuthService.clearLastEmail(); // conta excluída: não preencher mais o Login com esse e-mail
    await AuthService().logout();
  }

  /// Preenche o perfil com o que foi salvo no login: instantâneo e funciona
  /// mesmo sem internet. Se já houver um perfil carregado, não faz nada.
  Future<void> loadCached() async {
    if (UserSession.current.value != null) return;
    final cached = await AuthService.getUser();
    if (cached != null) UserSession.current.value = UserProfile.fromJson(cached);
  }

  /// GET /users/me — busca a versão mais atual do perfil.
  Future<UserProfile> fetchMe() async {
    final data = await ApiClient.get('/users/me');
    return _store(data['user'] as Map<String, dynamic>);
  }

  /// PUT /users/me — salva as alterações do perfil.
  Future<UserProfile> updateMe({
    required String name,
    required String email,
    String? phone,
    String? role,
    String? company,
  }) async {
    final data = await ApiClient.put('/users/me', {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'company': company,
    });
    return _store(data['user'] as Map<String, dynamic>);
  }

  /// POST /users/me/photo — envia a foto de perfil (JPG, PNG ou WebP, até 5 MB).
  Future<UserProfile> uploadPhoto({required List<int> bytes, required String filename}) async {
    final data = await ApiClient.uploadFile('/users/me/photo', field: 'photo', bytes: bytes, filename: filename);
    return _store(data['user'] as Map<String, dynamic>);
  }

  /// DELETE /users/me/photo — remove a foto de perfil.
  Future<UserProfile> removePhoto() async {
    final data = await ApiClient.delete('/users/me/photo');
    return _store(data['user'] as Map<String, dynamic>);
  }

  /// PUT /users/change-password — troca a senha de quem está logado.
  /// A API encerra as sessões dos outros aparelhos e devolve um token novo
  /// para este continuar conectado.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final data = await ApiClient.put('/users/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    final token = data['token'];
    if (token is String && token.isNotEmpty) await AuthService.saveToken(token);
  }

  /// POST /support — envia uma mensagem para o suporte (chega por e-mail para a equipe).
  Future<void> sendSupportMessage({required String message, String? appVersion, String? platform}) async {
    await ApiClient.post('/support', {
      'message': message,
      'appVersion': ?appVersion,
      'platform': ?platform,
    });
  }

  /// Atualiza o estado compartilhado (todas as telas se atualizam) e o cache local.
  Future<UserProfile> _store(Map<String, dynamic> json) async {
    final profile = UserProfile.fromJson(json);
    UserSession.current.value = profile;
    UserSession.syncedWithServer.value = true;
    await AuthService.saveUser(profile.toJson());
    return profile;
  }
}
