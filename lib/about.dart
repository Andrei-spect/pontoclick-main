import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _appVersion = '1.0.0';
  static const _linkedinUrl = 'https://www.linkedin.com/in/andrei-barbosa-7ba99a22a/';

  Future<void> _abrirLinkedin(BuildContext context) async {
    final uri = Uri.parse(_linkedinUrl);
    final ok = await canLaunchUrl(uri);
    if (ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sobre', style: AppText.headingSm()),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.twilightViolet.withOpacity(0.16), shape: BoxShape.circle),
                      child: const Icon(Icons.access_time_filled_rounded, size: 38, color: AppColors.twilightViolet),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        style: AppText.heading(),
                        children: [
                          TextSpan(text: 'Ponto', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          TextSpan(text: 'Click', style: TextStyle(color: context.accentPeach)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Versão $_appVersion', style: AppText.caption(color: context.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
                child: Text(
                  'O PontoClick é um app de controle de ponto simples e seguro, pensado para profissionais que estão sempre em movimento. Registre entradas, intervalos e saídas em poucos toques, de onde você estiver.',
                  style: AppText.body(color: context.textSecondary).copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DESENVOLVEDOR', style: AppText.caption(color: context.textTertiary, weight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, color: context.accentPeach, size: 18),
                        const SizedBox(width: 10),
                        Text('Andrei Barbosa', style: AppText.body(weight: FontWeight.w500).copyWith(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Desenvolvedor mobile, focado em criar experiências simples, rápidas e bem cuidadas em Flutter.',
                      style: AppText.body(color: context.textSecondary).copyWith(fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, color: context.textSecondary, size: 18),
                        const SizedBox(width: 10),
                        Text('andrei.barbosa009@gmail.com', style: AppText.body(color: context.textSecondary).copyWith(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _abrirLinkedin(context),
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded, color: context.accentPeach, size: 18),
                          const SizedBox(width: 10),
                          Text('linkedin.com/in/andrei-barbosa',
                              style: AppText.body(color: context.accentPeach, weight: FontWeight.w600).copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Center(
                child: Text('© ${DateTime.now().year} PontoClick. Todos os direitos reservados.',
                    textAlign: TextAlign.center, style: AppText.caption(color: context.textTertiary)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
