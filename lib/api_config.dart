import 'package:flutter/foundation.dart';

/// URL base da API do PontoClick (pontoclick-api).
///
/// "localhost" dentro de um emulador/celular aponta para o próprio
/// aparelho, não para o seu computador. Por isso a URL muda conforme
/// onde o app está rodando — isso é escolhido automaticamente:
///
/// - Chrome / Edge / Windows desktop:  http://localhost:3000
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

  static String get baseUrl {
    if (_usePhysicalDevice) return _physicalDeviceUrl;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }
}
