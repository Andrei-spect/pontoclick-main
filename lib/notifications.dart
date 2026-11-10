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
      appBar: appSecondaryBar('Notificações'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 8, AppSpace.page, 28),
          children: [
            AppContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionLabel('Lembretes de ponto'),
                  const SizedBox(height: 8),
                  _buildSwitchCard(context, [
                    _SwitchItem('Lembrete de entrada', 'Avisar no horário de início do expediente', _lembreteEntrada,
                        (v) => setState(() => _lembreteEntrada = v)),
                    _SwitchItem('Lembrete de intervalo', 'Avisar na hora do intervalo', _lembreteIntervalo,
                        (v) => setState(() => _lembreteIntervalo = v)),
                    _SwitchItem('Lembrete de saída', 'Avisar no horário de fim do expediente', _lembreteSaida,
                        (v) => setState(() => _lembreteSaida = v)),
                  ]),
                  const SizedBox(height: 22),
                  const AppSectionLabel('Alertas'),
                  const SizedBox(height: 8),
                  _buildSwitchCard(context, [
                    _SwitchItem('Alerta de atraso', 'Avisar quando um ponto não for registrado no horário', _alertaAtraso,
                        (v) => setState(() => _alertaAtraso = v)),
                    _SwitchItem('Resumo semanal', 'Receber um resumo das horas trabalhadas', _resumoSemanal,
                        (v) => setState(() => _resumoSemanal = v)),
                  ]),
                  const SizedBox(height: 22),
                  const AppSectionLabel('Canais'),
                  const SizedBox(height: 8),
                  _buildSwitchCard(context, [
                    _SwitchItem('Notificações push', 'Receber avisos neste aparelho', _notificacaoPush,
                        (v) => setState(() => _notificacaoPush = v)),
                    _SwitchItem('Notificações por e-mail', 'Receber avisos também por e-mail', _notificacaoEmail,
                        (v) => setState(() => _notificacaoEmail = v)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard(BuildContext context, List<_SwitchItem> items) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.cards),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              MergeSemantics(
                child: InkWell(
                  onTap: () => item.onChanged(!item.value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.label, style: AppText.bodySm(weight: FontWeight.w500)),
                                const SizedBox(height: 3),
                                Text(item.subtitle,
                                    style: AppText.label(color: context.textTertiary, weight: FontWeight.w400)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(value: item.value, onChanged: item.onChanged),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, thickness: 1, color: context.hairline, indent: 16, endIndent: 16),
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
