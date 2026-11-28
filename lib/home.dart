import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app_theme.dart';
import 'location_service.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'time_record.dart';
import 'records_service.dart';
import 'widgets.dart';
import 'work_locations.dart';
import 'notification_service.dart';
import 'work_schedule.dart';
import 'day_line.dart';

const _defaultBreakMinutes = 60; // quando o horário do dia não tem intervalo (ou é folga)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  final RecordsService _recordsService = RecordsService();
  List<TimeRecord> _serverRecords = []; // pontos de ontem e do mês, vindos da API (ou do cache)
  List<TimeRecord> _pending = []; // pontos salvos só no aparelho, aguardando internet
  bool _isPunching = false;
  bool _loadingRecords = true; // primeira carga dos pontos ainda não terminou

  final LocationService _locationService = LocationService();
  LocationResult? _locationResult;
  bool _loadingLocation = true;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;
  bool _isSyncing = false;

  int get _pendingSyncCount => _pending.length;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadLocation();
    _loadUser();
    WorkLocations.load(); // locais de trabalho do usuário (cache + API)
    ScheduleStore.load(); // horário de trabalho: define a meta do dia (cache + API)
    ScheduleStore.schedule.addListener(_onScheduleChanged);
    _bootstrap();
    RecordsEvents.changed.addListener(_loadRecords);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _connectivitySub?.cancel();
    RecordsEvents.changed.removeListener(_loadRecords);
    ScheduleStore.schedule.removeListener(_onScheduleChanged);
    super.dispose();
  }

  void _onScheduleChanged() {
    if (mounted) setState(() {});
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    AppFeedback.show(context, text, type: isError ? AppFeedbackType.error : AppFeedbackType.success);
  }

  /// Mostra o usuário salvo no login na hora e atualiza com a API em seguida.
  Future<void> _loadUser() async {
    final service = UserService();
    await service.loadCached();
    try {
      await service.fetchMe();
    } on ApiException catch (_) {
      // Sem conexão: segue com os dados salvos no login.
    }
  }

  Future<void> _loadLocation() async {
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _locationResult = result;
      _loadingLocation = false;
    });
  }

  /// Ordem importa: primeiro a fila offline, depois a conexão (que pode disparar
  /// a sincronização) e por fim os pontos do servidor.
  Future<void> _bootstrap() async {
    await _loadPending();
    await _initConnectivity();
    await _loadRecords();
    await _setupReminders();
  }

  /// Carrega as preferências dos lembretes e, se estiverem ligadas, pede a
  /// permissão do sistema (só aparece uma vez) e agenda os próximos avisos.
  Future<void> _setupReminders() async {
    await ReminderStore.load();
    if (ReminderStore.settings.value.enabled) await NotificationService.requestPermission();
    _remindersReady = true;
    await _syncReminders();
  }

  bool _remindersReady = false; // só agenda depois de carregar as preferências do usuário

  /// Reagenda os lembretes sem os pontos que já foram batidos no turno atual.
  Future<void> _syncReminders() async {
    if (!_remindersReady) return;
    const keys = {
      PunchType.entrada: 'entrada',
      PunchType.intervaloInicio: 'intervalo',
      PunchType.intervaloFim: 'volta',
      PunchType.saida: 'saida',
    };
    NotificationService.doneToday = {for (final r in _dayRecords) ?keys[r.type]};
    await NotificationService.reschedule();
  }

  Future<void> _initConnectivity() async {
    final initial = await Connectivity().checkConnectivity();
    _updateOnlineStatus(initial);
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_updateOnlineStatus);
  }

  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!mounted) return;
    setState(() => _isOnline = online);
    if (online && _pending.isNotEmpty) _syncPending();
  }

  Future<void> _loadPending() async {
    final list = await _recordsService.loadPending();
    if (!mounted) return;
    setState(() => _pending = list);
  }

  /// Busca na API os pontos de ontem e do mês. Sem internet, usa o último
  /// resultado salvo no aparelho.
  Future<void> _loadRecords() async {
    final today = DateTime(_now.year, _now.month, _now.day);
    final yesterday = DateTime(_now.year, _now.month, _now.day - 1);
    final monthStart = DateTime(_now.year, _now.month, 1);
    final weekStart = DateTime(_now.year, _now.month, _now.day - (_now.weekday - 1)); // segunda (resumo da semana)
    final from = [yesterday, monthStart, weekStart].reduce((a, b) => a.isBefore(b) ? a : b);

    try {
      final records = await _recordsService.fetchRange(from, today);
      await _recordsService.saveCache(records);
      if (!mounted) return;
      setState(() {
        _serverRecords = records;
        _loadingRecords = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) return; // sessão expirada: o main.dart cuida
      final cached = await _recordsService.loadCache();
      if (!mounted) return;
      setState(() {
        _serverRecords = cached;
        _loadingRecords = false;
      });
      if (e.statusCode != null) _showMessage('Não foi possível atualizar os pontos: ${e.message}', isError: true);
    }
    await _syncReminders();
  }

  Future<void> _syncPending() async {
    if (_isSyncing || _pending.isEmpty) return;
    setState(() => _isSyncing = true);
    try {
      final result = await _recordsService.syncPending();
      if (!mounted) return;
      await _loadRecords();
      await _loadPending();
      if (result.rejected.isNotEmpty) {
        _showMessage('O servidor recusou ${result.rejected.length} ponto(s) salvo(s) offline: ${result.rejected.first}',
            isError: true);
      } else if (result.synced > 0) {
        _showMessage(result.synced == 1 ? 'Ponto sincronizado!' : '${result.synced} pontos sincronizados!');
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  String get _todayKey => workDateOf(_now);

  /// Dia de trabalho do turno atual: hoje, ou o dia anterior se o turno da noite
  /// ainda está aberto (entrada há no máximo 16 h, sem saída).
  String get _shiftKey => currentWorkDate(_allRecords, _now);

  /// Meta do dia de trabalho atual, pelo horário do usuário (Perfil > Meu horário).
  /// Também define as horas extras. Zero = dia de folga.
  Duration get _dailyGoal => ScheduleStore.schedule.value.goalForWorkDate(_shiftKey);

  bool get _isDayOff => _dailyGoal == Duration.zero;

  /// O turno em andamento começou num dia anterior (passou da meia-noite).
  bool get _isOvernightShift => _shiftKey != _todayKey;

  /// Todos os pontos conhecidos (servidor + só no aparelho), sem repetir o mesmo
  /// tipo no mesmo dia, em ordem de horário.
  List<TimeRecord> get _allRecords {
    final byKey = <String, TimeRecord>{};
    for (final r in _serverRecords) {
      byKey['${r.workDate}|${r.type.wire}'] = r;
    }
    for (final r in _pending) {
      byKey.putIfAbsent('${r.workDate}|${r.type.wire}', () => r);
    }
    return byKey.values.toList()..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  }

  List<TimeRecord> get _dayRecords {
    final key = _shiftKey;
    return _allRecords.where((r) => r.workDate == key).toList();
  }

  PunchType get _nextPunchType {
    final count = _dayRecords.length;
    return count >= 4 ? PunchType.completo : PunchType.values[count];
  }

  Future<void> _registrarPonto() async {
    final type = _nextPunchType;
    if (type == PunchType.completo || _isPunching) return;

    setState(() => _isPunching = true);
    final moment = DateTime.now();
    // Turno da noite: depois da meia-noite o ponto continua no dia da entrada.
    final workDate = currentWorkDate(_allRecords, moment);
    // Mesmo id em qualquer tentativa: se a primeira chegou ao servidor e a resposta
    // se perdeu, reenviar depois não duplica o ponto.
    final clientId = '${type.wire}-${moment.toUtc().toIso8601String()}';
    final loc = _locationResult?.isOk == true ? _locationResult : null;

    Future<void> saveOffline() async {
      await _recordsService.addPending(TimeRecord(
        type: type,
        recordedAt: moment,
        workDate: workDate,
        latitude: loc?.latitude,
        longitude: loc?.longitude,
        accuracy: loc?.accuracyMeters,
        locationName: loc?.matchedLocation?.name,
        clientId: clientId,
        pending: true,
      ));
      await _loadPending();
    }

    try {
      if (!_isOnline) {
        await saveOffline();
        _showMessage('Sem internet: ponto salvo no aparelho. Será enviado quando a conexão voltar.');
      } else {
        // Online: quem define o horário é o relógio do servidor.
        final record = await _recordsService.create(
          type: type,
          workDate: workDate,
          clientId: clientId,
          latitude: loc?.latitude,
          longitude: loc?.longitude,
          accuracy: loc?.accuracyMeters,
          locationName: loc?.matchedLocation?.name,
        );
        if (!mounted) return;
        setState(() {
          _serverRecords = [
            ..._serverRecords.where((r) => !(r.workDate == record.workDate && r.type == record.type)),
            record,
          ];
        });
        await _recordsService.saveCache(_serverRecords);
        HapticFeedback.mediumImpact();
        _showMessage('Ponto registrado: ${punchTypeInfo[type]!.label.toLowerCase()} às ${formatClock(record.recordedAt)}.');
      }
    } on ApiException catch (e) {
      if (e.statusCode == null) {
        // Não conseguiu falar com a API: guarda no aparelho e envia depois.
        await saveOffline();
        _showMessage('Não foi possível falar com o servidor. Ponto salvo no aparelho e enviado depois.');
      } else if (e.statusCode != 401) {
        _showMessage(e.message, isError: true);
        if (e.statusCode == 409) await _loadRecords(); // o servidor discorda da ordem: ressincroniza
      }
    } finally {
      if (mounted) setState(() => _isPunching = false);
      await _syncReminders(); // ponto batido: o lembrete dele não precisa mais aparecer hoje
    }
  }

  Duration get _workedToday => workedDuration(_dayRecords, now: _now);

  /// O usuário está em intervalo agora (bateu o início, ainda não a volta).
  bool get _isOnBreak {
    final day = _dayRecords;
    return day.any((r) => r.type == PunchType.intervaloInicio) &&
        !day.any((r) => r.type == PunchType.intervaloFim) &&
        !day.any((r) => r.type == PunchType.saida);
  }

  int get _breakRemainingMinutes {
    final start = _dayRecords.where((r) => r.type == PunchType.intervaloInicio).firstOrNull;
    if (start == null) return 0;
    return _breakLimitMinutes - _now.difference(start.recordedAt).inMinutes;
  }

  /// Duração do intervalo no horário do usuário para o dia do turno atual.
  int get _breakLimitMinutes {
    final shift = ScheduleStore.schedule.value.shiftFor(DateTime.parse(_shiftKey));
    final minutes = shift?.intervaloMin ?? 0;
    return minutes > 0 ? minutes : _defaultBreakMinutes;
  }

  /// Horas do mês: dias fechados (com saída) + o dia de hoje em andamento.
  Duration get _monthWorked {
    final prefix = _todayKey.substring(0, 7); // "2026-10"
    final shiftKey = _shiftKey; // o turno em andamento entra pelo cálculo com a hora atual, abaixo
    final byDay = <String, List<TimeRecord>>{};
    for (final r in _allRecords) {
      if (r.workDate.startsWith(prefix) && r.workDate != shiftKey) {
        byDay.putIfAbsent(r.workDate, () => []).add(r);
      }
    }
    var total = workedDuration(_dayRecords, now: _now);
    for (final day in byDay.values) {
      total += workedDuration(day);
    }
    return total;
  }

  /// Ontem tem entrada mas ficou sem saída.
  bool get _yesterdayMissingExit {
    final key = workDateOf(DateTime(_now.year, _now.month, _now.day - 1));
    if (key == _shiftKey) return false; // turno da noite ainda em andamento: não é "esquecido"
    final day = _allRecords.where((r) => r.workDate == key).toList();
    return day.any((r) => r.type == PunchType.entrada) && !day.any((r) => r.type == PunchType.saida);
  }

  // ---------------------------------------------------------------------------
  // Interface (padrão hero-01: selo + título grande + linha do dia)
  // ---------------------------------------------------------------------------

  static const _meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  static const _dias = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];

  TimeRecord? _punch(PunchType type) => _dayRecords.where((r) => r.type == type).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final gpsOff = _locationResult?.status == LocationStatus.serviceDisabled ||
        _locationResult?.status == LocationStatus.permissionDenied ||
        _locationResult?.status == LocationStatus.permissionDeniedForever;

    return Scaffold(
      body: Column(
        children: [
          if (gpsOff) _buildGpsAlert(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(AppSpace.page, 18, AppSpace.page, MediaQuery.paddingOf(context).bottom + AppSpace.xxl),
              child: AppContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEyebrowRow(context),
                    const SizedBox(height: 16),
                    _buildHero(context),
                    const SizedBox(height: 18),
                    _buildMainCta(context),
                    if (_yesterdayMissingExit) ...[
                      const SizedBox(height: 12),
                      const AppNotice(
                        icon: Icons.warning_amber_rounded,
                        text: 'Ontem ficou sem registro de saída.',
                        color: AppColors.statusOrange,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildWeek(context),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildWorkedCard(context)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildOvertimeCard(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDayLineCard(context),
                    const SizedBox(height: 12),
                    _buildHoursBankCard(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsAlert(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.statusRed.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.location_off_rounded, color: context.dangerText, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GPS desativado: ative a localização para registrar o ponto',
              style: AppText.caption(color: context.dangerText, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Selo do local (abre "Locais de trabalho") + situação da conexão.
  Widget _buildEyebrowRow(BuildContext context) {
    final result = _locationResult;
    String text;
    Color dot;
    if (_loadingLocation) {
      text = 'Buscando localização...';
      dot = context.textTertiary;
    } else if (result?.status == LocationStatus.serviceDisabled) {
      text = 'GPS desativado';
      dot = AppColors.statusRed;
    } else if (result?.status == LocationStatus.permissionDenied ||
        result?.status == LocationStatus.permissionDeniedForever) {
      text = 'Permissão de localização negada';
      dot = AppColors.statusRed;
    } else if (result?.matchedLocation != null) {
      text = '${result!.matchedLocation!.name} · local identificado';
      dot = AppColors.statusGreen;
    } else if (result?.isOk == true) {
      text = WorkLocations.items.value.isEmpty ? 'Cadastre seus locais de trabalho' : 'Fora dos locais cadastrados';
      dot = AppColors.statusOrange;
    } else {
      text = 'Localização indisponível';
      dot = context.textTertiary;
    }

    return Row(
      children: [
        Expanded(
          child: AppEyebrow(
            text: text,
            dotColor: dot,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkLocationsScreen())),
          ),
        ),
        IconButton(
          tooltip: 'Atualizar localização',
          visualDensity: VisualDensity.compact,
          icon: _loadingLocation
              ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: context.textTertiary))
              : Icon(Icons.refresh_rounded, size: 18, color: context.textTertiary),
          onPressed: _loadingLocation
              ? null
              : () {
                  setState(() => _loadingLocation = true);
                  _loadLocation();
                },
        ),
        if (_pendingSyncCount > 0) ...[
          AppStatusChip(
            label: _isSyncing ? 'Sincronizando...' : '$_pendingSyncCount ${_pendingSyncCount == 1 ? "pendente" : "pendentes"}',
            icon: Icons.cloud_upload_outlined,
            tooltip: _isOnline
                ? 'Pontos salvos no aparelho. Toque para sincronizar.'
                : 'Pontos salvos no aparelho. Serão enviados quando a internet voltar.',
            onTap: _isOnline && !_isSyncing ? _syncPending : null,
          ),
          const SizedBox(width: 6),
        ],
        AppStatusChip(label: _isOnline ? 'Online' : 'Offline', dotColor: _isOnline ? AppColors.statusGreen : AppColors.statusRed),
      ],
    );
  }

  /// Data e hora ao vivo + título que muda conforme o momento da jornada.
  Widget _buildHero(BuildContext context) {
    final dateLine = '${_dias[_now.weekday - 1]}, ${_now.day} de ${_meses[_now.month - 1]} · '
        '${two(_now.hour)}:${two(_now.minute)}:${two(_now.second)}';
    final (title, lead) = _heroTexts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Agora são ${two(_now.hour)}:${two(_now.minute)}, ${_dias[_now.weekday - 1]}, ${_now.day} de ${_meses[_now.month - 1]}',
          excludeSemantics: true,
          child: Text(dateLine, style: AppText.numeric(AppText.label(color: context.textTertiary, weight: FontWeight.w500))),
        ),
        const SizedBox(height: 8),
        if (_loadingRecords)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [AppSkeleton(width: 260, height: 30), SizedBox(height: 8), AppSkeleton(width: 180, height: 30)],
          )
        else ...[
          AppHeroTitle(title, fontSize: 34),
          const SizedBox(height: 10),
          AppLead(lead),
        ],
      ],
    );
  }

  (List<(String, HeroTone)>, String) _heroTexts() {
    final entrada = _punch(PunchType.entrada);
    final intervalo = _punch(PunchType.intervaloInicio);
    final volta = _punch(PunchType.intervaloFim);
    final saida = _punch(PunchType.saida);
    final worked = _workedToday;
    final goal = _dailyGoal;
    final goalText = formatGoal(goal);
    final overtime = overtimeOf(worked, goal: goal);
    final overnight = _isOvernightShift ? 'Turno iniciado ontem. ' : '';

    if (entrada == null) {
      if (_isDayOff) {
        return ([('Hoje é ', HeroTone.plain), ('folga', HeroTone.accent), (' no seu horário.', HeroTone.plain)],
            'Se trabalhar, todo o tempo conta como hora extra.');
      }
      final shift = ScheduleStore.schedule.value.shiftFor(DateTime.parse(_shiftKey));
      return (
        [('Hora de bater a ', HeroTone.plain), ('entrada', HeroTone.accent), ('.', HeroTone.plain)],
        shift == null ? 'Sua meta hoje é de $goalText.' : 'Sua jornada hoje: ${shift.entrada} às ${shift.saida} · meta de $goalText.',
      );
    }

    if (saida != null) {
      final String lead;
      if (_isDayOff) {
        lead = 'Você trabalhou ${formatHours(worked)} numa folga: tudo conta como hora extra.';
      } else if (overtime > Duration.zero) {
        lead = 'Você trabalhou ${formatHours(worked)}, ${formatGoal(overtime)} além da meta de $goalText.';
      } else if (worked < goal) {
        lead = 'Você trabalhou ${formatHours(worked)}. Faltaram ${formatGoal(goal - worked)} para a meta de $goalText.';
      } else {
        lead = 'Você trabalhou ${formatHours(worked)}, exatamente a meta de $goalText.';
      }
      return ([('Jornada concluída às ', HeroTone.plain), (formatClock(saida.recordedAt), HeroTone.number), ('.', HeroTone.plain)], '$overnight$lead');
    }

    if (_isOnBreak) {
      final left = _breakRemainingMinutes;
      return (
        [('Em intervalo desde ', HeroTone.plain), (formatClock(intervalo!.recordedAt), HeroTone.number), ('.', HeroTone.plain)],
        '$overnight${left >= 0 ? 'Retorno do intervalo em $left min.' : 'Intervalo excedido em ${-left} min.'} '
            'Você já trabalhou ${formatHours(worked)}.',
      );
    }

    final since = volta ?? entrada;
    final String lead;
    if (_isDayOff) {
      lead = 'Dia de folga: as ${formatHours(worked)} trabalhadas contam como hora extra.';
    } else if (overtime > Duration.zero) {
      lead = 'Você já trabalhou ${formatHours(worked)}, ${formatGoal(overtime)} além da meta de $goalText.';
    } else {
      lead = 'Você já trabalhou ${formatHours(worked)}. Faltam ${formatGoal(goal - worked)} para a meta de $goalText.';
    }
    return (
      [(volta == null ? 'Trabalhando desde ' : 'De volta desde ', HeroTone.plain), (formatClock(since.recordedAt), HeroTone.number), ('.', HeroTone.plain)],
      '$overnight$lead',
    );
  }

  Widget _buildMainCta(BuildContext context) {
    final type = _nextPunchType;
    if (type == PunchType.completo) {
      // Dia fechado: é um aviso, não um botão desativado (que ficaria apagado no tema claro).
      final green = context.isDarkMode ? AppColors.statusGreen : AppColors.statusGreenStrong;
      return Semantics(
        label: 'Dia completo: os 4 pontos foram registrados',
        excludeSemantics: true,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.statusGreen.withValues(alpha: context.isDarkMode ? 0.14 : 0.12),
            borderRadius: BorderRadius.circular(AppRadius.buttons),
            border: Border.all(color: AppColors.statusGreen.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt_rounded, size: 20, color: green),
              const SizedBox(width: 10),
              Text('Dia completo · 4 de 4 pontos', style: AppText.bodySm(color: green, weight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final info = punchTypeInfo[type]!;
    return AppPrimaryButton(
      height: 54,
      label: info.actionLabel,
      icon: Icons.check_rounded,
      color: info.buttonColor,
      isLoading: _isPunching,
      onPressed: _loadingRecords ? null : _registrarPonto,
    );
  }

  /// Grupo de avatares do hero-01, aqui com os dias da semana: cheio = dia completo.
  Widget _buildWeek(BuildContext context) {
    final monday = DateTime(_now.year, _now.month, _now.day - (_now.weekday - 1));
    final schedule = ScheduleStore.schedule.value;
    const letters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    var complete = 0;
    var weekExtra = Duration.zero;
    final circles = <Widget>[];

    for (var i = 0; i < 7; i++) {
      final date = DateTime(monday.year, monday.month, monday.day + i);
      final key = workDateOf(date);
      final day = _allRecords.where((r) => r.workDate == key).toList();
      final works = schedule.shiftFor(date) != null;
      if (!works && day.isEmpty) continue; // folga sem ponto: não aparece
      final hasExit = day.any((r) => r.type == PunchType.saida);
      final isCurrent = key == _shiftKey;
      if (hasExit) {
        complete++;
        weekExtra += overtimeOf(workedDuration(day), goal: schedule.goalForWorkDate(key));
      }
      final future = date.isAfter(_now) && !isCurrent;

      final Color fill;
      final Color ring;
      final Color fg;
      if (hasExit) {
        fill = AppColors.twilightViolet;
        ring = Theme.of(context).scaffoldBackgroundColor;
        fg = Colors.white;
      } else if (day.isNotEmpty) {
        fill = Theme.of(context).cardColor;
        ring = isCurrent ? AppColors.twilightViolet : AppColors.statusOrange;
        fg = isCurrent ? context.violetText : AppColors.statusOrange;
      } else {
        fill = context.cardRaised;
        ring = context.border;
        fg = future ? context.textTertiary.withValues(alpha: 0.6) : context.textTertiary;
      }

      circles.add(Positioned(
        left: 24.0 * circles.length,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: Border.all(color: ring, width: 2)),
          child: Text(letters[i], style: AppText.caption(color: fg, weight: FontWeight.w700)),
        ),
      ));
    }

    final extraText = weekExtra > Duration.zero ? ' · ${formatOvertime(weekExtra)} de extras' : '';
    return Semantics(
      label: '$complete ${complete == 1 ? 'dia completo' : 'dias completos'} nesta semana$extraText',
      excludeSemantics: true,
      child: Row(
        children: [
          // Círculos sobrepostos, como o grupo de avatares do hero-01.
          SizedBox(
            width: circles.isEmpty ? 0 : 34.0 + 24 * (circles.length - 1),
            height: 34,
            child: Stack(children: circles),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$complete ${complete == 1 ? 'dia completo' : 'dias completos'}',
                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' nesta semana$extraText'),
              ]),
              style: AppText.numeric(AppText.label(color: context.textTertiary, weight: FontWeight.w400)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkedCard(BuildContext context) {
    final worked = _workedToday;
    final percent = _isDayOff
        ? (worked > Duration.zero ? 1.0 : 0.0)
        : (worked.inSeconds / _dailyGoal.inSeconds).clamp(0, 1).toDouble();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isOvernightShift ? 'Trabalhado no turno' : 'Trabalhado hoje',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption(color: context.textTertiary)),
          const SizedBox(height: 4),
          _loadingRecords
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: AppSkeleton(width: 80, height: 22))
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(formatHours(worked), style: AppText.numeric(AppText.headingSm(weight: FontWeight.w700).copyWith(fontSize: 24))),
                ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pills),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: percent),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: context.cardRaised,
                valueColor: AlwaysStoppedAnimation(context.accentPeach),
                semanticsLabel: 'Progresso da meta diária',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(_isDayOff ? 'dia de folga' : 'meta de ${formatGoal(_dailyGoal)} · ${(percent * 100).round()}%',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.numeric(AppText.caption(color: context.textTertiary))),
        ],
      ),
    );
  }

  Widget _buildOvertimeCard(BuildContext context) {
    final overtime = overtimeOf(_workedToday, goal: _dailyGoal);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Semantics(
        label: 'Horas extras ${_isOvernightShift ? 'no turno' : 'hoje'}: ${formatHours(overtime)}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isOvernightShift ? 'Extras no turno' : 'Horas extras hoje',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption(color: context.textTertiary)),
            const SizedBox(height: 4),
            _loadingRecords
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: AppSkeleton(width: 80, height: 22))
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatOvertime(overtime),
                      style: AppText.numeric(AppText.headingSm(
                        color: overtime > Duration.zero ? context.violetText : context.textPrimary,
                        weight: FontWeight.w700,
                      ).copyWith(fontSize: 24)),
                    ),
                  ),
            const SizedBox(height: 22),
            Text(_isDayOff ? 'folga: tudo é extra' : 'contam após ${formatGoal(_dailyGoal)}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.numeric(AppText.caption(color: context.textTertiary))),
          ],
        ),
      ),
    );
  }

  /// Marcações do dia: barra da jornada + linha do tempo com a duração de cada trecho.
  Widget _buildDayLineCard(BuildContext context) {
    final day = _dayRecords;
    final overtime = overtimeOf(_workedToday, goal: _dailyGoal);
    final done = day.any((r) => r.type == PunchType.saida);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(_isOvernightShift ? 'Turno iniciado ontem' : 'Marcações de hoje',
                          style: AppText.bodySm(weight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${done ? 'Total' : 'Até agora'} ${formatHours(_workedToday)} · ${day.length} de 4 marcações',
                      style: AppText.numeric(AppText.caption(color: context.textTertiary)),
                    ),
                  ],
                ),
              ),
              if (overtime > Duration.zero) AppBadge('extra ${formatOvertime(overtime)}'),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingRecords)
            const Column(children: [AppSkeleton(height: 16), SizedBox(height: 14), AppSkeleton(height: 14), SizedBox(height: 12), AppSkeleton(height: 14)])
          else
            DayLine(
              records: day,
              goal: _dailyGoal,
              now: _now,
              inProgress: !done,
              detailOf: (r) => r.pending ? 'Salvo no aparelho' : (r.locationName ?? 'Local não identificado'),
              trailingOf: (r) => [
                if (r.pending) ...[
                  Tooltip(message: 'Aguardando sincronização', child: Icon(Icons.cloud_off_rounded, size: 15, color: context.textTertiary)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHoursBankCard(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text('Horas trabalhadas no mês', style: AppText.label(color: context.textSecondary, weight: FontWeight.w400)),
          ),
          if (_loadingRecords)
            const AppSkeleton(width: 64, height: 16)
          else
            Text(formatHours(_monthWorked), style: AppText.numeric(AppText.body(color: context.accentPeach, weight: FontWeight.w700))),
        ],
      ),
    );
  }
}
