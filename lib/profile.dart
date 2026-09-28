import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'login.dart';
import 'home.dart';
import 'records.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'notifications.dart';
import 'help_support.dart';
import 'about.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _onNavTap(BuildContext context, int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.pushReplacement(context, fadeRoute(const HomeScreen()));
    } else {
      Navigator.pushReplacement(context, fadeRoute(const RecordsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Perfil', style: AppText.heading()),
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 24),
              const AppSectionLabel('CONTA'),
              const SizedBox(height: 8),
              AppMenuCard(items: [
                AppMenuItemData(
                    icon: Icons.person_outline_rounded,
                    label: 'Editar Perfil',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
                AppMenuItemData(
                    icon: Icons.lock_outline_rounded,
                    label: 'Alterar Senha',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
                AppMenuItemData(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notificações',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
              ]),
              const SizedBox(height: 24),
              const AppSectionLabel('SUPORTE'),
              const SizedBox(height: 8),
              AppMenuCard(items: [
                AppMenuItemData(
                    icon: Icons.help_outline_rounded,
                    label: 'Ajuda e Suporte',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
                AppMenuItemData(
                    icon: Icons.info_outline_rounded,
                    label: 'Sobre o PontoClick',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
              ]),
              const SizedBox(height: 28),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(activeIndex: 2, onTap: (i) => _onNavTap(context, i)),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.twilightViolet.withOpacity(0.2), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('JS', style: AppText.headingSm(weight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          Text('João Silva', style: AppText.body(weight: FontWeight.w600).copyWith(fontSize: 16)),
          const SizedBox(height: 2),
          Text('TechCorp • Desenvolvedor', style: AppText.caption(color: context.textSecondary).copyWith(fontSize: 13)),
          const SizedBox(height: 2),
          Text('joao.silva@gmail.com', style: AppText.caption(color: context.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded, color: AppColors.statusRed, size: 18),
        label: Text('Sair', style: AppText.body(color: AppColors.statusRed, weight: FontWeight.w600).copyWith(fontSize: 14)),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.statusRed.withOpacity(0.08),
          side: const BorderSide(color: AppColors.statusRed),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cards)),
        title: const Text('Sair da conta'),
        content: Text('Tem certeza que deseja sair?', style: TextStyle(color: dialogContext.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancelar', style: TextStyle(color: dialogContext.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
                dialogContext, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false),
            child: const Text('Sair', style: TextStyle(color: AppColors.statusRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}