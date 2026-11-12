import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'api_config.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const appVersion = '1.0.0';
  static const _linkedinUrl = 'https://www.linkedin.com/in/andrei-barbosa-7ba99a22a/';
  static const _email = 'andrei.barbosa009@gmail.com';

  Future<void> _abrir(BuildContext context, Uri uri) async {
    final ok = await canLaunchUrl(uri);
    if (ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      AppFeedback.error(context, 'Não foi possível abrir o link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appSecondaryBar('Sobre'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 8, AppSpace.page, 28),
          child: AppContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(child: AppLogo(iconSize: 34, textStyle: AppText.heading(weight: FontWeight.w700))),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.pills)),
                    child: Text('Versão $appVersion', style: AppText.caption(color: context.textSecondary, weight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'O PontoClick é um app de controle de ponto simples e seguro, pensado para profissionais que estão sempre em movimento. Registre entradas, intervalos e saídas em poucos toques, de onde você estiver.',
                    style: AppText.bodySm(color: context.textSecondary).copyWith(height: 1.55),
                  ),
                ),
                const SizedBox(height: 22),
                const AppSectionLabel('Desenvolvedor'),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppIconTile(icon: Icons.person_outline_rounded),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Andrei Barbosa', style: AppText.bodySm(weight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                              'Desenvolvedor mobile, focado em criar experiências simples, rápidas e bem cuidadas em Flutter.',
                              style: AppText.label(color: context.textSecondary, weight: FontWeight.w400).copyWith(height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppMenuCard(items: [
                  AppMenuItemData(
                    icon: Icons.email_outlined,
                    label: _email,
                    onTap: () => _abrir(context, Uri(scheme: 'mailto', path: _email)),
                  ),
                  AppMenuItemData(
                    icon: Icons.link_rounded,
                    label: 'linkedin.com/in/andrei-barbosa',
                    accent: context.accentPeach,
                    onTap: () => _abrir(context, Uri.parse(_linkedinUrl)),
                  ),
                ]),
                const SizedBox(height: 22),
                const AppSectionLabel('Privacidade'),
                const SizedBox(height: 8),
                AppMenuCard(items: [
                  AppMenuItemData(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Política de privacidade',
                    onTap: () => _abrir(context, Uri.parse(ApiConfig.privacyPolicyUrl)),
                  ),
                ]),
                const SizedBox(height: 28),
                Text('© ${DateTime.now().year} PontoClick. Todos os direitos reservados.',
                    textAlign: TextAlign.center, style: AppText.caption(color: context.textTertiary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
