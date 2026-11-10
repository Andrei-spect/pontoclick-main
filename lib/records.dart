import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'main_shell.dart';
import 'records_service.dart';
import 'time_record.dart';
import 'user_profile.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  static const _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
  static const _dias = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
  static const _diasCurtos = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  final RecordsService _recordsService = RecordsService();
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  /// Pontos do mês exibido, agrupados pelo dia ("2026-10-25").
  Map<String, List<TimeRecord>> _byDay = {};
  bool _loading = true;
  bool _loadedOnce = false;
  String? _error; // não foi possível carregar o mês
  String? _notice; // aviso discreto (ex: mostrando dados salvos)
  bool _saving = false;
  bool _exporting = false;
  int _loadToken = 0; // impede que uma resposta antiga (de outro mês) sobrescreva a atual

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    // A aba fica montada desde o início (IndexedStack): só busca os dados quando
    // ela aparece, e busca de novo a cada vez que o usuário volta para ela.
    MainShell.tab.addListener(_onTabChanged);
    if (MainShell.tab.value == 1) _loadMonth();
  }

  @override
  void dispose() {
    MainShell.tab.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (MainShell.tab.value == 1 && mounted) _loadMonth();
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    AppFeedback.show(context, text, type: isError ? AppFeedbackType.error : AppFeedbackType.success);
  }

  String _monthPrefix(DateTime month) => '${month.year.toString().padLeft(4, '0')}-${two(month.month)}';

  Future<void> _loadMonth() async {
    final token = ++_loadToken;
    final month = _focusedMonth;
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    var server = <TimeRecord>[];
    String? error;
    String? notice;
    try {
      server = await _recordsService.fetchRange(DateTime(month.year, month.month, 1), DateTime(month.year, month.month + 1, 0));
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        if (mounted && token == _loadToken) setState(() => _loading = false);
        return; // sessão expirada: o main.dart leva para o Login
      }
      if (e.statusCode == null) {
        // Sem conexão: tenta o que ficou salvo no aparelho.
        final cached = await _recordsService.loadCache();
        server = cached.where((r) => r.workDate.startsWith(_monthPrefix(month))).toList();
        if (server.isNotEmpty) {
          notice = 'Sem conexão: mostrando os dados salvos no aparelho.';
        } else {
          error = e.message;
        }
      } else {
        error = e.message;
      }
    }

    final pending = await _recordsService.loadPending();
    if (!mounted || token != _loadToken) return;
    setState(() {
      _byDay = _group(server, pending, month);
      _loading = false;
      _loadedOnce = true;
      _error = error;
      _notice = notice;
    });
  }

  /// Junta o que veio do servidor com o que está só no aparelho (sem repetir o
  /// mesmo tipo no mesmo dia) e agrupa por dia.
  Map<String, List<TimeRecord>> _group(List<TimeRecord> server, List<TimeRecord> pending, DateTime month) {
    final byKey = <String, TimeRecord>{};
    for (final r in server) {
      byKey['${r.workDate}|${r.type.wire}'] = r;
    }
    for (final r in pending) {
      byKey.putIfAbsent('${r.workDate}|${r.type.wire}', () => r);
    }
    final result = <String, List<TimeRecord>>{};
    for (final r in byKey.values) {
      if (r.workDate.startsWith(_monthPrefix(month))) result.putIfAbsent(r.workDate, () => []).add(r);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    }
    return result;
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
      _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDate.day.clamp(1, lastDay).toInt());
    });
    _loadMonth();
  }

  Future<void> _editRecord(TimeRecord record) async {
    final id = record.id;
    if (id == null || _saving) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: record.recordedAt.hour, minute: record.recordedAt.minute),
      helpText: 'Alterar ${punchTypeInfo[record.type]?.label.toLowerCase() ?? 'ponto'}',
      cancelText: 'Cancelar',
      confirmText: 'Salvar',
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked == null || !mounted) return;
    if (picked.hour == record.recordedAt.hour && picked.minute == record.recordedAt.minute) return;

    final d = record.recordedAt;
    final newTime = DateTime(d.year, d.month, d.day, picked.hour, picked.minute);

    setState(() => _saving = true);
    try {
      final updated = await _recordsService.updateTime(id, newTime);
      if (!mounted) return;
      setState(() {
        final list = List<TimeRecord>.from(_byDay[updated.workDate] ?? []);
        final index = list.indexWhere((r) => r.id == updated.id);
        if (index >= 0) list[index] = updated;
        _byDay = {..._byDay, updated.workDate: list};
      });
      RecordsEvents.notifyChanged(); // a Home mostra os mesmos pontos
      _showMessage('Horário atualizado para ${formatClock(updated.recordedAt)}.');
    } on ApiException catch (e) {
      if (e.statusCode != 401) _showMessage(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportMonthPdf() async {
    if (_loading || _exporting) return;
    if (_error != null && _byDay.isEmpty) {
      _showMessage('Não foi possível carregar os pontos deste mês. Tente de novo.', isError: true);
      return;
    }

    setState(() => _exporting = true);
    try {
      final user = UserSession.current.value;
      final keys = _byDay.keys.toList()..sort();
      var monthTotal = Duration.zero;
      final body = <pw.Widget>[];

      for (final key in keys) {
        final list = _byDay[key]!;
        final worked = workedDuration(list);
        monthTotal += worked;
        final date = DateTime.parse(key);
        body.addAll(<pw.Widget>[
          pw.Text('${two(date.day)}/${two(date.month)}/${date.year} - ${_dias[date.weekday - 1]}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
          for (final r in list)
            pw.Text(
              '${punchTypeInfo[r.type]?.label ?? ''}: ${formatClock(r.recordedAt)}'
              '${r.edited ? ' (editado)' : ''}${r.locationName != null ? ' - ${r.locationName}' : ''}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          if (worked > Duration.zero)
            pw.Text('Total do dia: ${formatHours(worked)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
        ]);
      }

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (context) => <pw.Widget>[
            pw.Text('PontoClick - Registros de ponto', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('${_meses[_focusedMonth.month - 1]} de ${_focusedMonth.year}', style: const pw.TextStyle(fontSize: 12)),
            if (user != null) pw.Text('Funcionário: ${user.name} (${user.email})', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 16),
            if (keys.isEmpty) pw.Text('Nenhum registro neste mês.', style: const pw.TextStyle(fontSize: 12)),
            ...body,
            if (keys.isNotEmpty) ...<pw.Widget>[
              pw.Divider(),
              pw.Text('Total de horas no mês (dias com entrada e saída): ${formatHours(monthTotal)}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => doc.save());
    } catch (_) {
      _showMessage('Não foi possível gerar o PDF.', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Resumo do mês (calculado a partir dos pontos já carregados)
  // ---------------------------------------------------------------------------

  String get _todayKey => workDateOf(DateTime.now());

  /// Dia do turno em andamento (hoje, ou ontem se o turno da noite ainda está aberto).
  String get _openShiftKey => currentWorkDate(_byDay.values.expand((list) => list).toList(), DateTime.now());

  bool _isInProgress(String key) => key == _todayKey || key == _openShiftKey;

  bool _hasExit(List<TimeRecord> list) => list.any((r) => r.type == PunchType.saida);

  /// Dia passado com entrada e sem saída (o turno em andamento não conta).
  bool _isMissingExit(String key, List<TimeRecord> list) =>
      !_isInProgress(key) && list.any((r) => r.type == PunchType.entrada) && !_hasExit(list);

  Duration get _monthTotal {
    var total = Duration.zero;
    for (final list in _byDay.values) {
      if (_hasExit(list)) total += workedDuration(list);
    }
    return total;
  }

  int get _missingExitDays => _byDay.entries.where((e) => _isMissingExit(e.key, e.value)).length;

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadMonth,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(AppSpace.page, 12, AppSpace.page, MediaQuery.paddingOf(context).bottom + AppSpace.xxl),
            child: AppContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageTitle(
                    'Registros',
                    trailing: AppOutlineButton(
                      label: _exporting ? 'Gerando PDF...' : 'Exportar PDF',
                      icon: Icons.download_rounded,
                      onPressed: _exporting || _loading ? null : _exportMonthPdf,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildCalendarCard(context),
                  const SizedBox(height: 14),
                  _buildDayCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(BuildContext context, String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: context.cardRaised, borderRadius: BorderRadius.circular(AppRadius.inner)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption(color: context.textTertiary).copyWith(fontSize: 11)),
            const SizedBox(height: 2),
            _loading && !_loadedOnce
                ? const Padding(padding: EdgeInsets.only(top: 4), child: AppSkeleton(width: 48, height: 14))
                : Text(value,
                    maxLines: 1,
                    style: AppText.numeric(AppText.body(color: valueColor ?? context.textPrimary, weight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final today = DateTime.now();
    final todayKey = workDateOf(today);
    final missing = _missingExitDays;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mês anterior',
                icon: Icon(Icons.chevron_left_rounded, color: context.textSecondary),
                onPressed: () => _changeMonth(-1),
              ),
              Expanded(
                child: Text('${_meses[_focusedMonth.month - 1]} de ${_focusedMonth.year}',
                    textAlign: TextAlign.center, style: AppText.bodySm(weight: FontWeight.w600)),
              ),
              IconButton(
                tooltip: 'Próximo mês',
                icon: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _buildSummaryTile(context, 'Horas no mês', formatHours(_monthTotal), valueColor: context.accentPeach),
                const SizedBox(width: 8),
                _buildSummaryTile(context, 'Dias com ponto', '${_byDay.length}'),
                const SizedBox(width: 8),
                _buildSummaryTile(context, 'Sem saída', '$missing',
                    valueColor: missing > 0 ? AppColors.statusOrange : null),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: _diasCurtos
                .map((d) => Expanded(
                    child: Center(
                        child: Text(d, style: AppText.caption(color: context.textTertiary, weight: FontWeight.w500).copyWith(fontSize: 11)))))
                .toList(),
          ),
          const SizedBox(height: 6),
          Column(
            children: List.generate(((leadingEmpty + daysInMonth) / 7).ceil(), (row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    if (cellIndex < leadingEmpty || cellIndex >= leadingEmpty + daysInMonth) {
                      return const Expanded(child: SizedBox(height: 44));
                    }
                    final day = cellIndex - leadingEmpty + 1;
                    final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                    final key = workDateOf(date);
                    return Expanded(child: _buildDayCell(context, date, key, todayKey));
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _legendDot(context, context.textSecondary, 'Dia completo'),
                _legendDot(context, AppColors.statusOrange, 'Sem saída'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: AppText.caption(color: context.textTertiary)),
      ],
    );
  }

  Widget _buildDayCell(BuildContext context, DateTime date, String key, String todayKey) {
    final isSelected = key == workDateOf(_selectedDate);
    final isToday = key == todayKey;
    final isFuture = date.isAfter(DateTime.now());
    final list = _byDay[key];
    final hasRecords = list?.isNotEmpty ?? false;
    final missingExit = hasRecords && _isMissingExit(key, list!);

    final Color marker = !hasRecords
        ? Colors.transparent
        : isSelected
            ? Colors.white
            : (missingExit ? AppColors.statusOrange : context.textSecondary);

    final textColor = isSelected ? Colors.white : (isFuture ? context.textTertiary : context.textPrimary);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${date.day} de ${_meses[date.month - 1]}${isToday ? ', hoje' : ''}'
          '${hasRecords ? (missingExit ? ', sem registro de saída' : ', com registros') : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: isSelected ? AppColors.twilightViolet : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.inner),
            side: isToday && !isSelected
                ? const BorderSide(color: AppColors.twilightViolet, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.inner),
            onTap: () => setState(() => _selectedDate = date),
            child: SizedBox(
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    child: Text('${date.day}',
                        style: AppText.numeric(AppText.label(
                            color: textColor, weight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400).copyWith(fontSize: 14))),
                  ),
                  const SizedBox(height: 3),
                  Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: marker)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context) {
    final key = workDateOf(_selectedDate);
    final list = _byDay[key] ?? [];
    final hasExit = _hasExit(list);
    final missingExit = list.isNotEmpty && _isMissingExit(key, list);
    final dateText = '${_dias[_selectedDate.weekday - 1]}, ${two(_selectedDate.day)}/${two(_selectedDate.month)}';

    String? totalText;
    if (hasExit) {
      totalText = 'Total ${formatHours(workedDuration(list))}';
    } else if (_isInProgress(key) && list.isNotEmpty) {
      totalText = 'Em andamento';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Semantics(header: true, child: Text(dateText, style: AppText.bodySm(weight: FontWeight.w600)))),
              if (totalText != null && !_loading)
                Text(totalText, style: AppText.numeric(AppText.label(color: context.accentPeach, weight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const AppSkeleton(width: 10, height: 10, radius: 5),
                      const SizedBox(width: 12),
                      const Expanded(child: AppSkeleton(height: 14)),
                      const SizedBox(width: 40),
                      const AppSkeleton(width: 40, height: 14),
                    ],
                  ),
                ),
              ),
            )
          else if (_error != null && list.isEmpty)
            AppEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Não foi possível carregar os pontos',
              message: _error,
              actionLabel: 'Tentar de novo',
              onAction: _loadMonth,
            )
          else if (list.isEmpty)
            const AppEmptyState(
              icon: Icons.event_busy_rounded,
              title: 'Nenhum ponto neste dia',
              message: 'Os registros aparecem aqui assim que você bate o ponto.',
            )
          else
            ...list.map((r) => _buildRecordRow(context, r)),
          if (missingExit && !_loading) ...[
            const SizedBox(height: 8),
            const AppNotice(icon: Icons.warning_amber_rounded, text: 'Dia sem registro de saída.', color: AppColors.statusOrange),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 10),
            Text(_notice!, style: AppText.caption(color: context.textTertiary)),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordRow(BuildContext context, TimeRecord r) {
    final info = punchTypeInfo[r.type]!;
    final editable = r.id != null && !r.pending;

    final details = <String>[
      if (r.pending) 'Salvo no aparelho' else (r.locationName ?? 'Local não identificado'),
      if (r.edited && r.originalRecordedAt != null) 'original ${formatClock(r.originalRecordedAt!)}',
    ];

    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: context.hairline))),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: info.color)),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(info.label, style: AppText.label(color: context.textPrimary).copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(details.join(' · '), style: AppText.caption(color: context.textTertiary)),
                ],
              ),
            ),
          ),
          if (r.pending) ...[
            Tooltip(message: 'Aguardando sincronização', child: Icon(Icons.cloud_off_rounded, size: 15, color: context.textTertiary)),
            const SizedBox(width: 8),
          ],
          if (r.edited) ...[
            Tooltip(
              message: r.originalRecordedAt == null ? 'Horário editado' : 'Horário original: ${formatClock(r.originalRecordedAt!)}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: context.violetSoft, borderRadius: BorderRadius.circular(AppRadius.pills)),
                child: Text('Editado', style: AppText.caption(color: context.violetText, weight: FontWeight.w600).copyWith(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(formatClock(r.recordedAt), style: AppText.numeric(AppText.bodySm(weight: FontWeight.w600))),
          if (editable)
            IconButton(
              tooltip: 'Editar horário de ${info.label.toLowerCase()}',
              icon: Icon(Icons.edit_outlined, size: 18, color: context.textTertiary),
              onPressed: _saving ? null : () => _editRecord(r),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
