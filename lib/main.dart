import 'package:flutter/material.dart';
import 'login.dart';
import 'main_shell.dart';
import 'theme_controller.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'api_client.dart';
import 'user_service.dart';
import 'widgets.dart';

/// Chaves globais: permitem trocar de tela e mostrar avisos de fora de um
/// widget (usado quando a sessão expira no meio de uma chamada à API).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

bool _loggingOut = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();

  final token = await AuthService.getToken();
  if (token != null) {
    // Já deixa o usuário salvo carregado para a Home abrir com o avatar certo.
    await UserService().loadCached();
  }

  // Qualquer chamada autenticada que receba 401 (token expirado/inválido)
  // cai aqui: limpa a sessão e volta para o Login.
  ApiClient.onUnauthorized = () async {
    if (_loggingOut) return; // várias chamadas podem falhar ao mesmo tempo
    _loggingOut = true;
    await AuthService().logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    final messengerContext = messengerKey.currentContext;
    if (messengerContext != null && messengerContext.mounted) {
      messengerKey.currentState?.showSnackBar(
        AppFeedback.build(messengerContext, 'Sua sessão expirou. Faça login novamente.', type: AppFeedbackType.info),
      );
    }
    _loggingOut = false;
  };

  runApp(PontoClickApp(startLoggedIn: token != null));
}

class PontoClickApp extends StatelessWidget {
  final bool startLoggedIn;
  const PontoClickApp({super.key, required this.startLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'PontoClick',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: messengerKey,
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: startLoggedIn ? const MainShell() : const LoginScreen(),
        );
      },
    );
  }
}
