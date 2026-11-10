import 'package:flutter/material.dart';
import 'home.dart';
import 'records.dart';
import 'profile.dart';
import 'widgets.dart';

/// Estrutura das três abas principais (Ponto, Registros, Perfil).
///
/// As abas ficam vivas num IndexedStack: trocar de aba não recria a tela nem
/// empilha rotas (antes cada troca abria uma Home nova por cima da anterior).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Aba visível (0 = Ponto, 1 = Registros, 2 = Perfil). As telas escutam
  /// para atualizar os dados quando passam a ser exibidas.
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);

  static void goTo(int index) => tab.value = index;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    MainShell.tab.value = 0; // sempre abre no Ponto (após login, cadastro ou reabrir o app)
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainShell.tab,
      builder: (context, index, _) => PopScope(
        // Botão voltar do Android: numa aba que não é o Ponto, volta para o Ponto.
        canPop: index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) MainShell.goTo(0);
        },
        child: Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: index,
            children: const [HomeScreen(), RecordsScreen(), ProfileScreen()],
          ),
          bottomNavigationBar: AppBottomNav(activeIndex: index, onTap: MainShell.goTo),
        ),
      ),
    );
  }
}
