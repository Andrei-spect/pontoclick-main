import 'package:flutter/material.dart';
import 'app_avatar.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'home.dart';
import 'login.dart';
import 'my_schedule.dart';
import 'notifications.dart';
import 'profile.dart';
import 'records.dart';
import 'theme_controller.dart';
import 'user_profile.dart';
import 'widgets.dart';
import 'work_locations.dart';

/// Estrutura das três abas principais (Ponto, Registros, Perfil).
///
/// Padrão hero-01: no topo, a marca + avatar + botão de menu e, logo abaixo,
/// as abas num menu em pílula. O botão de menu abre um painel lateral (Sheet)
/// com atalhos, tema e "Sair da conta".
///
/// As abas ficam vivas num IndexedStack: trocar de aba não recria a tela nem
/// empilha rotas.
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
          endDrawer: _MenuSheet(activeIndex: index),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.page, 8, AppSpace.page, 4),
                  child: AppContentWidth(
                    child: Column(
                      children: [
                        const _TopBar(),
                        const SizedBox(height: 12),
                        AppPillNav(activeIndex: index, onTap: MainShell.goTo),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: index,
                    children: const [HomeScreen(), RecordsScreen(), ProfileScreen()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Marca à esquerda; avatar (abre o Perfil) e menu (abre o painel) à direita.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppBrand(),
        const Spacer(),
        ValueListenableBuilder<UserProfile?>(
          valueListenable: UserSession.current,
          builder: (context, user, _) => Semantics(
            button: true,
            label: 'Abrir perfil',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => MainShell.goTo(2),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: AppAvatar(initials: user?.initials ?? '', imageUrl: user?.photoFullUrl, size: 36),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Builder(
          builder: (context) => AppSquareIconButton(
            icon: Icons.menu_rounded,
            tooltip: 'Abrir menu',
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }
}

/// Painel lateral (shadcn Sheet): usuário, atalhos, tema e sair.
class _MenuSheet extends StatelessWidget {
  final int activeIndex;
  const _MenuSheet({required this.activeIndex});

  void _goTab(BuildContext context, int index) {
    Navigator.pop(context);
    MainShell.goTo(index);
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
            'Pontos ainda não sincronizados continuam salvos neste aparelho e são enviados quando você entrar de novo nesta conta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Sair', style: TextStyle(color: dialogContext.dangerText, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    Widget link(String label, IconData icon, VoidCallback onTap, {bool active = false}) => Material(
          color: active ? context.violetSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.inner),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.inner),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 19, color: active ? context.violetText : context.textTertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        style: AppText.bodySm(
                            color: active ? context.violetText : context.textPrimary,
                            weight: active ? FontWeight.w600 : FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        );

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: Border(left: BorderSide(color: context.border)),
      width: 300,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AppBrand(size: 26),
                  const Spacer(),
                  AppSquareIconButton(icon: Icons.close_rounded, tooltip: 'Fechar menu', onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 18),
              ValueListenableBuilder<UserProfile?>(
                valueListenable: UserSession.current,
                builder: (context, user, _) => Row(
                  children: [
                    AppAvatar(initials: user?.initials ?? '', imageUrl: user?.photoFullUrl, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySm(weight: FontWeight.w600)),
                          Text(
                            (user?.subtitle.isNotEmpty ?? false) ? user!.subtitle : (user?.email ?? ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption(color: context.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              link('Ponto', Icons.schedule_rounded, () => _goTab(context, 0), active: activeIndex == 0),
              link('Registros', Icons.calendar_month_outlined, () => _goTab(context, 1), active: activeIndex == 1),
              link('Perfil', Icons.person_outline_rounded, () => _goTab(context, 2), active: activeIndex == 2),
              Divider(height: 24, color: context.hairline),
              link('Meu horário', Icons.timelapse_rounded, () => _open(context, const MyScheduleScreen())),
              link('Locais de trabalho', Icons.location_on_outlined, () => _open(context, const WorkLocationsScreen())),
              link('Notificações', Icons.notifications_none_rounded, () => _open(context, const NotificationsScreen())),
              link(context.isDarkMode ? 'Tema claro' : 'Tema escuro',
                  context.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined, ThemeController.toggle),
              const Spacer(),
              AppDangerButton(label: 'Sair da conta', icon: Icons.logout_rounded, onPressed: () => _logout(context)),
            ],
          ),
        ),
      ),
    );
  }
}
