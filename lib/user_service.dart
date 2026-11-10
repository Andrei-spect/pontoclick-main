import 'api_client.dart';
import 'auth_service.dart';
import 'user_profile.dart';

class UserService {
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
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await ApiClient.put('/users/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
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
