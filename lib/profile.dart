import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_config.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'login.dart';
import 'main_shell.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'notifications.dart';
import 'work_locations.dart';
import 'help_support.dart';
import 'about.dart';
import 'auth_service.dart';
import 'app_avatar.dart';
import 'user_profile.dart';
import 'user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    // A aba fica montada desde o início (IndexedStack): atualiza o perfil
    // quando ela aparece, não ao abrir o app (a Home já faz isso).
    MainShell.tab.addListener(_onTabChanged);
    if (MainShell.tab.value == 2) _loadProfile();
  }

  @override
  void dispose() {
    MainShell.tab.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (MainShell.tab.value == 2 && mounted) _loadProfile();
  }

  /// Mostra na hora o que já está salvo e atualiza com a API em seguida.
  Future<void> _loadProfile() async {
    await _userService.loadCached();
    try {
      await _userService.fetchMe();
    } on ApiException catch (e) {
      // 401 já é tratado globalmente (volta para o Login).
      if (!mounted || e.statusCode == 401) return;
      AppFeedback.error(context, 'Não foi possível atualizar o perfil: ${e.message}');
    }
  }

  void _open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpace.page, 12, AppSpace.page, MediaQuery.paddingOf(context).bottom + AppSpace.xxl),
          child: AppContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppPageTitle('Perfil'),
                const SizedBox(height: 14),
                _buildHeader(context),
                if (kDebugMode) _buildDebugInfo(context),
                const SizedBox(height: 22),
                const AppSectionLabel('Conta'),
                const SizedBox(height: 8),
                AppMenuCard(items: [
                  AppMenuItemData(
                      icon: Icons.person_outline_rounded, label: 'Editar perfil', onTap: () => _open(const EditProfileScreen())),
                  AppMenuItemData(
                      icon: Icons.lock_outline_rounded, label: 'Alterar senha', onTap: () => _open(const ChangePasswordScreen())),
                  AppMenuItemData(
                      icon: Icons.location_on_outlined,
                      label: 'Locais de trabalho',
                      onTap: () => _open(const WorkLocationsScreen())),
                  AppMenuItemData(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notificações',
                      onTap: () => _open(const NotificationsScreen())),
                ]),
                const SizedBox(height: 22),
                const AppSectionLabel('Suporte'),
                const SizedBox(height: 8),
                AppMenuCard(items: [
                  AppMenuItemData(
                      icon: Icons.help_outline_rounded,
                      label: 'Ajuda e suporte',
                      accent: context.accentPeach,
                      onTap: () => _open(const HelpSupportScreen())),
                  AppMenuItemData(
                      icon: Icons.info_outline_rounded,
                      label: 'Sobre o PontoClick',
                      accent: context.accentPeach,
                      onTap: () => _open(const AboutScreen())),
                ]),
                const SizedBox(height: 28),
                AppDangerButton(label: 'Sair da conta', icon: Icons.logout_rounded, onPressed: () => _confirmLogout(context)),
                const SizedBox(height: 14),
                Center(child: Text('PontoClick versão ${AboutScreen.appVersion}', style: AppText.caption(color: context.textTertiary))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: UserSession.current,
      builder: (context, user, _) {
        final subtitle = user?.subtitle ?? '';
        return AppCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              AppAvatar(initials: user?.initials ?? '', imageUrl: user?.photoFullUrl, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? '', style: AppText.body(weight: FontWeight.w600).copyWith(fontSize: 17)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(subtitle, style: AppText.label(color: context.textSecondary, weight: FontWeight.w400)),
                    ],
                    const SizedBox(height: 3),
                    Text(user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(color: context.textTertiary, weight: FontWeight.w400)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Editar perfil',
                style: IconButton.styleFrom(backgroundColor: context.cardRaised, minimumSize: const Size(44, 44)),
                icon: Icon(Icons.edit_outlined, size: 18, color: context.textPrimary),
                onPressed: () => _open(const EditProfileScreen()),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Só aparece em modo debug (flutter run): mostra de onde vieram os dados do perfil.
  Widget _buildDebugInfo(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UserSession.syncedWithServer,
      builder: (context, synced, _) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          synced
              ? 'DEBUG • Perfil carregado do servidor (${ApiConfig.baseUrl})'
              : 'DEBUG • Mostrando dados salvos no aparelho: o servidor (${ApiConfig.baseUrl}) não respondeu',
          textAlign: TextAlign.center,
          style: AppText.caption(color: synced ? context.textTertiary : AppColors.statusRed),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: const Text(
              'Pontos ainda não sincronizados continuam salvos neste aparelho e são enviados quando você entrar de novo nesta conta.'),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dialogContext.textPrimary,
                    minimumSize: const Size(0, 48),
                    side: BorderSide(color: Theme.of(dialogContext).dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
                  ),
                  child: Text('Cancelar', style: AppText.bodySm(weight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().logout();
                    if (!dialogContext.mounted) return;
                    Navigator.pushAndRemoveUntil(
                        dialogContext, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusRedStrong,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
                  ),
                  child: Text('Sair', style: AppText.bodySm(color: Colors.white, weight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
