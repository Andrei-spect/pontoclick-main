import 'package:flutter/foundation.dart';

/// URL base da API do PontoClick (pontoclick-api).
///
/// "localhost" dentro de um emulador/celular aponta para o próprio
/// aparelho, não para o seu computador. Por isso a URL muda conforme
/// onde o app está rodando — isso é escolhido automaticamente:
///
/// - Navegador (web):                  mesmo endereço da página, porta 3000
///   (ex: página em http://192.168.15.6:8080 -> API em http://192.168.15.6:3000;
///   assim o app web funciona no PC e também no celular pela rede Wi-Fi)
/// - Windows desktop:                  http://localhost:3000
/// - Emulador Android:                 http://10.0.2.2:3000
/// - Simulador iOS:                    http://localhost:3000
///
/// CELULAR FÍSICO (mesma rede Wi-Fi do PC): troque o valor abaixo em
/// [_physicalDeviceUrl] pelo IP do seu computador (rode "ipconfig" e
/// procure "Endereço IPv4", algo como 192.168.0.x) e coloque
/// [_usePhysicalDevice] como true.
///
/// Ao publicar, troque pela URL do servidor hospedado (https://...).
class ApiConfig {
  static const bool _usePhysicalDevice = false;
  static const String _physicalDeviceUrl = 'http://192.168.0.10:3000';

  /// PRODUÇÃO: a URL da API hospedada é passada na hora de compilar, sem mexer
  /// no código. Ex:
  ///   flutter build appbundle --dart-define=API_URL=https://api.pontoclick.com.br
  ///   flutter build ipa       --dart-define=API_URL=https://api.pontoclick.com.br
  /// Sem API_URL, vale a escolha automática de desenvolvimento abaixo.
  static const String _productionUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_productionUrl.isNotEmpty) return _productionUrl;
    if (_usePhysicalDevice) return _physicalDeviceUrl;
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return '${Uri.base.scheme == 'https' ? 'https' : 'http'}://$host:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  /// Páginas públicas servidas pela API (exigidas pelas lojas).
  static String get privacyPolicyUrl => '$baseUrl/privacidade';
  static String get accountDeletionUrl => '$baseUrl/excluir-conta';
}
