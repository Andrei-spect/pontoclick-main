import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla o tema (claro/escuro) do app inteiro, agora com persistência:
/// a escolha do usuário sobrevive ao fechar e reabrir o app.
class ThemeController {
  ThemeController._();

  static const _prefsKey = 'pontoclick_theme_mode';

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);

  /// Chamado uma vez, no início do main(), para carregar a preferência salva.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'light') {
      mode.value = ThemeMode.light;
    } else if (saved == 'dark') {
      mode.value = ThemeMode.dark;
    }
    // Se nada foi salvo ainda, mantém o padrão (escuro).
  }

  static Future<void> toggle() async {
    mode.value = mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.value == ThemeMode.dark ? 'dark' : 'light');
  }

  static bool get isDark => mode.value == ThemeMode.dark;
}
