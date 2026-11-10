import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'time_record.dart' show two;

/// Perfil > Notificações: lembretes de bater o ponto nos horários da jornada.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _weekdays = [(1, 'Seg'), (2, 'Ter'), (3, 'Qua'), (4, 'Qui'), (5, 'Sex'), (6, 'Sáb'), (7, 'Dom')];
  static const _icons = {
    'entrada': Icons.login_rounded,
    'intervalo': Icons.free_breakfast_outlined,
    'volta': Icons.replay_rounded,
    'saida': Icons.logout_rounded,
  };

  late ReminderSettings _draft = ReminderStore.settings.value;
  late ReminderSettings _saved = ReminderStore.settings.value;
  bool _loading = true;
  bool _saving = false;

  bool get _dirty => _draft != _saved;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ReminderStore.load();
    if (!mounted) return;
    setState(() {
      _saved = ReminderStore.settings.value;
      if (!_dirty || _loading) _draft = _saved;
      _loading = false;
    });
  }

  /// Mesma regra da API: horários ligados em ordem (a saída pode ser no dia seguinte).
  String? _orderError(ReminderSettings s) {
    final active = reminderKeys.where((k) => s.reminders[k]!.enabled).toList();
    for (var i = 1; i < active.length; i++) {
      final prev = s.reminders[active[i - 1]]!.time;
      final cur = s.reminders[active[i]]!.time;
      final overnightExit = active[i] == 'saida' && cur.compareTo(s.reminders[active.first]!.time) < 0;
      if (cur.compareTo(prev) <= 0 && !overnightExit) {
        return 'O horário de "${reminderLabels[active[i]]}" precisa ser depois de "${reminderLabels[active[i - 1]]}".';
      }
    }
    return null;
  }

  Future<void> _pickTime(String key) async {
    final item = _draft.reminders[key]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: item.timeOfDay,
      helpText: 'Lembrete de ${reminderLabels[key]!.toLowerCase()}',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null || !mounted) return;
    setState(() => _draft = _draft.withReminder(key, item.copyWith(time: '${two(picked.hour)}:${two(picked.minute)}')));
  }

  void _toggleDay(int day) {
    final days = {..._draft.days};
    days.contains(day) ? days.remove(day) : days.add(day);
    setState(() => _draft = _draft.copyWith(days: days.toList()..sort()));
  }

  Future<void> _save() async {
    final error = _orderError(_draft);
    if (error != null) {
      AppFeedback.error(context, error);
      return;
    }
    if (_draft.enabled && _draft.days.isEmpty) {
      AppFeedback.error(context, 'Escolha pelo menos um dia da semana.');
      return;
    }
    setState(() => _saving = true);
    try {
      // Ligando os lembretes no celular: pede a permissão do sistema na hora.
      if (_draft.enabled && NotificationService.isSupported) await NotificationService.requestPermission();
      await ReminderStore.save(_draft);
      if (!mounted) return;
      setState(() {
        _saved = ReminderStore.settings.value;
        _draft = _saved;
      });
      AppFeedback.success(context, _saved.enabled ? 'Lembretes salvos.' : 'Lembretes desligados.');
    } on ApiException catch (e) {
      if (!mounted || e.statusCode == 401) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _draft.enabled;
    return Scaffold(
      appBar: appSecondaryBar('Notificações'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpace.page, 8, AppSpace.page, 16),
                children: [
                  AppContentWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!NotificationService.isSupported) ...[
                          AppNotice(
                            icon: Icons.phone_iphone_rounded,
                            text: 'Os lembretes aparecem no app de celular (Android e iPhone). Aqui você pode ajustar os horários.',
                            color: context.violetText,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildMasterSwitch(context),
                        const SizedBox(height: 22),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: enabled ? 1 : 0.45,
                          child: IgnorePointer(
                            ignoring: !enabled,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppSectionLabel('Horários'),
                                const SizedBox(height: 8),
                                _buildTimesCard(context),
                                const SizedBox(height: 22),
                                const AppSectionLabel('Dias da semana'),
                                const SizedBox(height: 8),
                                _buildDays(context),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 16, color: context.textTertiary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Se você já tiver batido o ponto, o lembrete daquele horário não aparece. '
                                        'Para turno da noite, coloque a saída mais cedo que a entrada (ex: 22:00 e 06:00).',
                                        style: AppText.caption(color: context.textTertiary).copyWith(height: 1.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, 8, AppSpace.page, 16),
              child: AppContentWidth(
                child: AppPrimaryButton(
                  label: _dirty ? 'Salvar' : 'Salvo',
                  icon: _dirty ? null : Icons.check_rounded,
                  onPressed: _dirty && !_loading ? _save : null,
                  isLoading: _saving,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterSwitch(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.cards),
      clipBehavior: Clip.antiAlias,
      child: MergeSemantics(
        child: InkWell(
          onTap: () => setState(() => _draft = _draft.copyWith(enabled: !_draft.enabled)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            child: Row(
              children: [
                const AppIconTile(icon: Icons.notifications_active_outlined, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lembretes de ponto', style: AppText.bodySm(weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Avisar nos horários da sua jornada para bater o ponto',
                          style: AppText.caption(color: context.textTertiary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(value: _draft.enabled, onChanged: (v) => setState(() => _draft = _draft.copyWith(enabled: v))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimesCard(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.cards),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < reminderKeys.length; i++) ...[
            _buildReminderRow(context, reminderKeys[i]),
            if (i < reminderKeys.length - 1) Divider(height: 1, thickness: 1, color: context.hairline, indent: 64),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderRow(BuildContext context, String key) {
    final item = _draft.reminders[key]!;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
        child: Row(
          children: [
            AppIconTile(icon: _icons[key]!, size: 32, color: item.enabled ? null : context.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(reminderLabels[key]!,
                  style: AppText.bodySm(color: item.enabled ? context.textPrimary : context.textTertiary)),
            ),
            TextButton(
              onPressed: item.enabled ? () => _pickTime(key) : null,
              style: TextButton.styleFrom(
                backgroundColor: item.enabled ? context.cardRaised : Colors.transparent,
                minimumSize: const Size(72, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
              ),
              child: Text(item.time,
                  semanticsLabel: 'Horário: ${item.time}. Toque para alterar',
                  style: AppText.numeric(AppText.bodySm(
                      color: item.enabled ? context.textPrimary : context.textTertiary, weight: FontWeight.w600))),
            ),
            const SizedBox(width: 4),
            Switch(
              value: item.enabled,
              onChanged: (v) => setState(() => _draft = _draft.withReminder(key, item.copyWith(enabled: v))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDays(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (day, label) in _weekdays)
          FilterChip(
            label: Text(label),
            selected: _draft.days.contains(day),
            onSelected: (_) => _toggleDay(day),
            showCheckmark: false,
            labelStyle: AppText.label(
                color: _draft.days.contains(day) ? Colors.white : context.textPrimary, weight: FontWeight.w600),
            selectedColor: AppColors.twilightViolet,
            backgroundColor: Theme.of(context).cardColor,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pills)),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          ),
      ],
    );
  }
}
