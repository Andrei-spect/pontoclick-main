import 'package:flutter/material.dart';
import 'login.dart';
import 'theme_controller.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  runApp(const PontoClickApp());
}

class PontoClickApp extends StatelessWidget {
  const PontoClickApp({super.key});

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
          home: const LoginScreen(),
        );
      },
    );
  }
}