import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _lembreteEntrada = true;
  bool _lembreteIntervalo = false;
  bool _lembreteSaida = true;
  bool _alertaAtraso = true;
  bool _resumoSemanal = false;
  bool _notificacaoPush = true;
  bool _notificacaoEmail = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text('Notificações', style: AppText.body(weight: FontWeight.w600))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            const AppSectionLabel('LEMBRETES DE PONTO'),
            const SizedBox(height: 8),
            _buildSwitchCard(context, [
              _SwitchItem('Lembrete de entrada', 'Avisar no horário de início do expediente', _lembreteEntrada,
                  (v) => setState(() => _lembreteEntrada = v)),
              _SwitchItem('Lembrete de intervalo', 'Avisar na hora do intervalo', _lembreteIntervalo,
                  (v) => setState(() => _lembreteIntervalo = v)),
              _SwitchItem('Lembrete de saída', 'Avisar no horário de fim do expediente', _lembreteSaida,
                  (v) => setState(() => _lembreteSaida = v)),
            ]),
            const SizedBox(height: 24),
            const AppSectionLabel('ALERTAS'),
            const SizedBox(height: 8),
            _buildSwitchCard(context, [
              _SwitchItem('Alerta de atraso', 'Avisar quando um ponto não for registrado no horário', _alertaAtraso,
                  (v) => setState(() => _alertaAtraso = v)),
              _SwitchItem('Resumo semanal', 'Receber um resumo das horas trabalhadas', _resumoSemanal,
                  (v) => setState(() => _resumoSemanal = v)),
            ]),
            const SizedBox(height: 24),
            const AppSectionLabel('CANAIS'),
            const SizedBox(height: 8),
            _buildSwitchCard(context, [
              _SwitchItem('Notificações push', 'Receber notificações no dispositivo', _notificacaoPush,
                  (v) => setState(() => _notificacaoPush = v)),
              _SwitchItem('Notificações por e-mail', 'Receber avisos também por e-mail', _notificacaoEmail,
                  (v) => setState(() => _notificacaoEmail = v)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard(BuildContext context, List<_SwitchItem> items) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label, style: AppText.body(weight: FontWeight.w500).copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(item.subtitle, style: AppText.caption(color: context.textTertiary).copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    Switch(value: item.value, onChanged: item.onChanged, activeColor: AppColors.twilightViolet),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: Theme.of(context).dividerColor, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

class _SwitchItem {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  _SwitchItem(this.label, this.subtitle, this.value, this.onChanged);
}
