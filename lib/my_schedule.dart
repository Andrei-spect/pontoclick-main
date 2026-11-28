import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'time_record.dart' show two, formatGoal;
import 'work_schedule.dart';

/// Perfil > Meu horário: entrada, saída e intervalo de segunda a sexta e do fim de semana.
/// Define a meta de cada dia e, com ela, quando as horas extras começam a contar.
class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

enum _Part { weekdays, weekend }

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  static const _breakOptions = [0, 15, 30, 45, 60, 90, 120];

  late WorkSchedule _draft = ScheduleStore.schedule.value;
  late WorkSchedule _saved = ScheduleStore.schedule.value;
  bool _loading = true;
  bool _saving = false;

  bool get _dirty => _draft != _saved;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ScheduleStore.load();
    if (!mounted) return;
    setState(() {
      _saved = ScheduleStore.schedule.value;
      if (!_dirty || _loading) _draft = _saved;
      _loading = false;
    });
  }

  ShiftHours _shift(_Part part) => part == _Part.weekdays ? _draft.weekdays : _draft.weekend;

  void _setShift(_Part part, ShiftHours value) => setState(() {
        _draft = part == _Part.weekdays ? _draft.copyWith(weekdays: value) : _draft.copyWith(weekend: value);
      });

  static String _breakLabel(int minutes) => minutes == 0 ? 'Sem intervalo' : formatGoal(Duration(minutes: minutes));

  Future<void> _pickTime(_Part part, {required bool entrada}) async {
    final shift = _shift(part);
    final current = entrada ? shift.entrada : shift.saida;
    final picked = await showTimePicker(
      context: context,
      initialTime: ShiftHours.toTimeOfDay(current),
      helpText: '${entrada ? 'Entrada' : 'Saída'} ${part == _Part.weekdays ? 'de segunda a sexta' : 'no fim de semana'}',
      cancelText: 'Cancelar',
      confirmText: 'OK',
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null || !mounted) return;
    final time = '${two(picked.hour)}:${two(picked.minute)}';
    _setShift(part, entrada ? shift.copyWith(entrada: time) : shift.copyWith(saida: time));
  }

  Future<void> _pickBreak(_Part part) async {
    final shift = _shift(part);
    final options = {..._breakOptions, shift.intervaloMin}.toList()..sort();
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Duração do intervalo', style: AppText.body(weight: FontWeight.w600)),
            ),
            for (final m in options)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(_breakLabel(m), style: AppText.bodySm()),
                trailing: m == shift.intervaloMin ? Icon(Icons.check_rounded, color: sheetContext.violetText) : null,
                onTap: () => Navigator.pop(sheetContext, m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _setShift(part, shift.copyWith(intervaloMin: picked));
  }

  Future<void> _save() async {
    final error = _draft.weekdays.validate('de segunda a sexta') ??
        (_draft.worksWeekend ? _draft.weekend.validate('do fim de semana') : null);
    if (error != null) {
      AppFeedback.error(context, error);
      return;
    }
    // Sem trabalho no fim de semana o horário dele não é usado, mas a API sempre o valida:
    // se ficou inválido, volta para o último salvo em vez de bloquear o salvamento.
    var toSave = _draft;
    if (!toSave.worksWeekend && toSave.weekend.validate('') != null) toSave = toSave.copyWith(weekend: _saved.weekend);

    setState(() => _saving = true);
    try {
      await ScheduleStore.save(toSave);
      if (!mounted) return;
      setState(() {
        _saved = ScheduleStore.schedule.value;
        _draft = _saved;
      });
      AppFeedback.success(context, 'Horário salvo. As horas extras passam a seguir este horário.');
    } on ApiException catch (e) {
      if (!mounted || e.statusCode == 401) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appSecondaryBar('Meu horário'),
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
                        AppHeroHeader(
                          eyebrow: const AppEyebrow(tag: 'Meu horário', text: 'Define a meta de cada dia'),
                          title: [
                            ('Sua jornada é de ', HeroTone.plain),
                            (formatGoal(_draft.weekdays.workDuration), HeroTone.number),
                            (' por dia.', HeroTone.plain),
                          ],
                          lead: 'As horas extras começam a contar depois dessa meta. '
                              'Informe a entrada, a saída e o intervalo de cada tipo de dia.',
                        ),
                        const SizedBox(height: 24),
                        const AppSectionLabel('Segunda a sexta'),
                        const SizedBox(height: 8),
                        _buildShiftCard(context, _Part.weekdays),
                        const SizedBox(height: 8),
                        _buildSummary(context, _draft.weekdays),
                        const SizedBox(height: 26),
                        const AppSectionLabel('Fim de semana'),
                        const SizedBox(height: 8),
                        Text('Em quais dias você trabalha?', style: AppText.label(color: context.textSecondary, weight: FontWeight.w400)),
                        const SizedBox(height: 10),
                        _buildWeekendDays(context),
                        const SizedBox(height: 14),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _draft.worksWeekend ? 1 : 0.45,
                          child: IgnorePointer(
                            ignoring: !_draft.worksWeekend,
                            child: _buildShiftCard(context, _Part.weekend),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _draft.worksWeekend
                            ? _buildSummary(context, _draft.weekend)
                            : _buildInfo(context, 'Folga no sábado e no domingo. Se trabalhar nesses dias, todo o tempo conta como extra.'),
                        const SizedBox(height: 22),
                        _buildInfo(
                          context,
                          'Para turno da noite, coloque a saída mais cedo que a entrada (ex: 22:00 e 06:00). '
                          'O turno conta no dia em que começou.',
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

  Widget _buildShiftCard(BuildContext context, _Part part) {
    final shift = _shift(part);
    Widget divider() => Divider(height: 1, thickness: 1, color: context.hairline, indent: 64);
    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cards),
        side: BorderSide(color: context.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildRow(context, Icons.login_rounded, 'Entrada', shift.entrada, () => _pickTime(part, entrada: true)),
          divider(),
          _buildRow(context, Icons.logout_rounded, 'Saída', shift.saida, () => _pickTime(part, entrada: false)),
          divider(),
          _buildRow(context, Icons.free_breakfast_outlined, 'Intervalo', _breakLabel(shift.intervaloMin), () => _pickBreak(part)),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, IconData icon, String label, String value, VoidCallback onTap) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Row(
          children: [
            AppIconTile(icon: icon, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.bodySm())),
            TextButton(
              onPressed: _loading ? null : onTap,
              style: TextButton.styleFrom(
                backgroundColor: context.cardRaised,
                minimumSize: const Size(72, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
              ),
              child: Text(value,
                  semanticsLabel: '$label: $value. Toque para alterar',
                  style: AppText.numeric(AppText.bodySm(color: context.textPrimary, weight: FontWeight.w600))),
            ),
          ],
        ),
      ),
    );
  }

  /// "Jornada de 8h por dia" (ou o erro, se o horário não fecha).
  Widget _buildSummary(BuildContext context, ShiftHours shift) {
    final error = shift.validate('');
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(error.replaceAll('  ', ' '), style: AppText.caption(color: AppColors.statusRed)),
      );
    }
    final overnight = shift.isOvernight ? ' (termina no dia seguinte)' : '';
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text('Jornada de ${formatGoal(shift.workDuration)} por dia$overnight',
          style: AppText.caption(color: context.textTertiary)),
    );
  }

  Widget _buildInfo(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: context.textTertiary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppText.caption(color: context.textTertiary).copyWith(height: 1.45))),
      ],
    );
  }

  Widget _buildWeekendDays(BuildContext context) {
    Widget chip(String label, bool selected, ValueChanged<bool> onSelected) => FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: _loading ? null : onSelected,
          showCheckmark: false,
          labelStyle: AppText.label(color: selected ? Colors.white : context.textPrimary, weight: FontWeight.w600),
          selectedColor: AppColors.twilightViolet,
          backgroundColor: Theme.of(context).cardColor,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pills)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        );
    return Wrap(
      spacing: 8,
      children: [
        chip('Sábado', _draft.saturday, (v) => setState(() => _draft = _draft.copyWith(saturday: v))),
        chip('Domingo', _draft.sunday, (v) => setState(() => _draft = _draft.copyWith(sunday: v))),
      ],
    );
  }
}
