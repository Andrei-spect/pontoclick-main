import 'package:flutter/material.dart';
import 'login.dart';
import 'home.dart';
import 'theme_controller.dart';
import 'app_theme.dart';
import 'auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  final token = await AuthService.getToken();
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
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: startLoggedIn ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
