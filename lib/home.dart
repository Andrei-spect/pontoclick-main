import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app_theme.dart';
import 'theme_controller.dart';
import 'location_service.dart';
import 'auth_service.dart';
import 'app_avatar.dart';
import 'user_profile.dart';
import 'user_service.dart';
import 'time_record.dart';
import 'records_service.dart';
import 'main_shell.dart';
import 'widgets.dart';

const _breakLimitMinutes = 60;
const _dailyGoal = Duration(hours: 8);

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
    _bootstrap();
    RecordsEvents.changed.addListener(_loadRecords);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _connectivitySub?.cancel();
    RecordsEvents.changed.removeListener(_loadRecords);
    super.dispose();
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
    final from = yesterday.isBefore(monthStart) ? yesterday : monthStart;

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

  List<TimeRecord> get _dayRecords => _allRecords.where((r) => r.workDate == _todayKey).toList();

  PunchType get _nextPunchType {
    final count = _dayRecords.length;
    return count >= 4 ? PunchType.completo : PunchType.values[count];
  }

  Future<void> _registrarPonto() async {
    final type = _nextPunchType;
    if (type == PunchType.completo || _isPunching) return;

    setState(() => _isPunching = true);
    final moment = DateTime.now();
    final workDate = workDateOf(moment);
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

  /// Horas do mês: dias fechados (com saída) + o dia de hoje em andamento.
  Duration get _monthWorked {
    final prefix = _todayKey.substring(0, 7); // "2026-10"
    final byDay = <String, List<TimeRecord>>{};
    for (final r in _allRecords) {
      if (r.workDate.startsWith(prefix) && r.workDate != _todayKey) {
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
    final day = _allRecords.where((r) => r.workDate == key).toList();
    return day.any((r) => r.type == PunchType.entrada) && !day.any((r) => r.type == PunchType.saida);
  }

  // ---------------------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final gpsOff = _locationResult?.status == LocationStatus.serviceDisabled ||
        _locationResult?.status == LocationStatus.permissionDenied ||
        _locationResult?.status == LocationStatus.permissionDeniedForever;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (gpsOff) _buildGpsAlert(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    AppSpace.page, 12, AppSpace.page, MediaQuery.paddingOf(context).bottom + AppSpace.xxl),
                child: AppContentWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusRow(context),
                      const SizedBox(height: 14),
                      _buildClock(context),
                      const SizedBox(height: 14),
                      _buildLocationCard(context),
                      const SizedBox(height: 12),
                      _buildMainCta(context),
                      const SizedBox(height: 12),
                      _buildWorkedCard(context),
                      if (_yesterdayMissingExit) ...[
                        const SizedBox(height: 12),
                        const AppNotice(
                          icon: Icons.warning_amber_rounded,
                          text: 'Ontem ficou sem registro de saída.',
                          color: AppColors.statusOrange,
                        ),
                      ],
                      const SizedBox(height: 12),
                      _buildTimeline(context),
                      const SizedBox(height: 12),
                      _buildHoursBankCard(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsAlert(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.statusRed.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded, color: AppColors.statusRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'GPS desativado — ative a localização para registrar o ponto',
              style: AppText.caption(color: AppColors.statusRed, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context) {
    return Row(
      children: [
        AppStatusChip(
          label: _isOnline ? 'Online' : 'Offline',
          dotColor: _isOnline ? AppColors.statusGreen : AppColors.statusRed,
        ),
        if (_pendingSyncCount > 0) ...[
          const SizedBox(width: 8),
          AppStatusChip(
            label: _isSyncing
                ? 'Sincronizando...'
                : '$_pendingSyncCount ${_pendingSyncCount == 1 ? "pendente" : "pendentes"}',
            icon: Icons.cloud_upload_outlined,
            tooltip: _isOnline
                ? 'Pontos salvos no aparelho. Toque para sincronizar.'
                : 'Pontos salvos no aparelho. Serão enviados quando a internet voltar.',
            onTap: _isOnline && !_isSyncing ? _syncPending : null,
          ),
        ],
        const Spacer(),
        IconButton(
          tooltip: 'Alternar tema',
          icon: Icon(context.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.textSecondary, size: 20),
          onPressed: ThemeController.toggle,
        ),
        ValueListenableBuilder<UserProfile?>(
          valueListenable: UserSession.current,
          builder: (context, user, _) => Semantics(
            button: true,
            label: 'Abrir perfil',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => MainShell.goTo(2),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: AppAvatar(initials: user?.initials ?? '', imageUrl: user?.photoFullUrl, size: 38),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClock(BuildContext context) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    const dias = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
    final dataFormatada = '${dias[_now.weekday - 1]}, ${_now.day} de ${meses[_now.month - 1]} de ${_now.year}';
    final horaFormatada = '${two(_now.hour)}:${two(_now.minute)}:${two(_now.second)}';

    return Semantics(
      label: 'Agora são ${two(_now.hour)}:${two(_now.minute)}, $dataFormatada',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dataFormatada, style: AppText.label(color: context.textSecondary, weight: FontWeight.w400).copyWith(fontSize: 14)),
          const SizedBox(height: 2),
          Text(horaFormatada,
              style: AppText.numeric(AppText.headingLg().copyWith(fontSize: 44, height: 1.1, letterSpacing: -1.3))),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    String title;
    String subtitle;
    Color titleColor = context.accentPeach;
    final result = _locationResult;

    if (_loadingLocation) {
      title = 'Buscando localização...';
      subtitle = 'Isso leva alguns segundos';
      titleColor = context.textSecondary;
    } else if (result?.status == LocationStatus.serviceDisabled) {
      title = 'GPS desativado';
      subtitle = 'Ative a localização do aparelho';
      titleColor = AppColors.statusRed;
    } else if (result?.status == LocationStatus.permissionDenied ||
        result?.status == LocationStatus.permissionDeniedForever) {
      title = 'Permissão de localização negada';
      subtitle = 'Libere o acesso nas configurações do app';
      titleColor = AppColors.statusRed;
    } else if (result?.matchedLocation != null) {
      title = result!.matchedLocation!.name;
      subtitle = 'Local identificado';
    } else if (result?.isOk == true) {
      title = 'Local não identificado';
      subtitle = 'Fora dos locais cadastrados';
      titleColor = context.textPrimary;
    } else {
      title = 'Não foi possível obter a localização';
      subtitle = 'Toque em atualizar para tentar de novo';
      titleColor = context.textSecondary;
    }
    if (result?.accuracyMeters != null && !_loadingLocation) {
      subtitle = '$subtitle · precisão de ${result!.accuracyMeters!.toStringAsFixed(0)} m';
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      child: Row(
        children: [
          AppIconTile(icon: Icons.location_on_outlined, color: context.accentPeach, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label(color: titleColor, weight: FontWeight.w600).copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption(color: context.textTertiary)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Atualizar localização',
            icon: _loadingLocation
                ? SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: context.textTertiary))
                : Icon(Icons.refresh_rounded, size: 20, color: context.textTertiary),
            onPressed: _loadingLocation
                ? null
                : () {
                    setState(() => _loadingLocation = true);
                    _loadLocation();
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildMainCta(BuildContext context) {
    final type = _nextPunchType;
    final isDone = type == PunchType.completo;
    final info = isDone ? null : punchTypeInfo[type]!;

    return AppPrimaryButton(
      height: 56,
      label: isDone ? 'Jornada concluída' : info!.actionLabel,
      icon: isDone ? Icons.task_alt_rounded : Icons.check_rounded,
      color: isDone ? AppColors.statusGreenStrong : info!.buttonColor,
      isLoading: _isPunching,
      onPressed: isDone || _loadingRecords ? null : _registrarPonto,
    );
  }

  Widget _buildWorkedCard(BuildContext context) {
    final worked = _workedToday;
    final percent = (worked.inSeconds / _dailyGoal.inSeconds).clamp(0, 1).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trabalhado hoje', style: AppText.label(color: context.textSecondary, weight: FontWeight.w400)),
                    const SizedBox(height: 2),
                    _loadingRecords
                        ? const Padding(padding: EdgeInsets.only(top: 6, bottom: 4), child: AppSkeleton(width: 96, height: 22))
                        : Text(formatHours(worked), style: AppText.numeric(AppText.headingSm().copyWith(fontSize: 24))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('meta de ${_dailyGoal.inHours}h · ${(percent * 100).round()}%',
                    style: AppText.numeric(AppText.label(color: context.textTertiary, weight: FontWeight.w400))),
              ),
            ],
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
                backgroundColor: Theme.of(context).dividerColor,
                valueColor: AlwaysStoppedAnimation(context.accentPeach),
                semanticsLabel: 'Progresso da meta diária',
              ),
            ),
          ),
          if (_isOnBreak) ...[
            const SizedBox(height: 10),
            Text(
              _breakRemainingMinutes >= 0
                  ? 'Retorno do intervalo em ${_breakRemainingMinutes}min'
                  : 'Intervalo excedido em ${-_breakRemainingMinutes}min',
              style: AppText.label(
                  color: _breakRemainingMinutes >= 0 ? context.textSecondary : AppColors.statusRed, weight: FontWeight.w400),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final saidaPendingLate = _nextPunchType == PunchType.saida && DateTime.now().hour >= 20;
    const types = [PunchType.entrada, PunchType.intervaloInicio, PunchType.intervaloFim, PunchType.saida];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text('Resumo do dia', style: AppText.bodySm(weight: FontWeight.w600))),
          const SizedBox(height: 6),
          for (var i = 0; i < types.length; i++)
            _buildTimelineRow(context, types[i], isLast: i == types.length - 1, showLateWarning: saidaPendingLate && types[i] == PunchType.saida),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(BuildContext context, PunchType type, {required bool isLast, required bool showLateWarning}) {
    final record = _dayRecords.where((r) => r.type == type).firstOrNull;
    final info = punchTypeInfo[type]!;
    final done = record != null;
    final isNext = !done && _nextPunchType == type;

    String detail;
    if (done) {
      detail = record.pending ? 'Salvo no aparelho' : (record.locationName ?? 'Local não identificado');
    } else {
      detail = isNext ? 'Próximo registro' : 'Aguardando';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 12,
            child: Column(
              children: [
                const SizedBox(height: 14),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? info.color : Colors.transparent,
                    border: Border.all(
                        color: done || isNext ? info.color : Theme.of(context).dividerColor, width: 1.5),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1.5, margin: const EdgeInsets.only(top: 4), color: Theme.of(context).dividerColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.label,
                            style: AppText.label(color: done ? context.textPrimary : context.textTertiary).copyWith(fontSize: 14)),
                        const SizedBox(height: 1),
                        Text(detail, style: AppText.caption(color: context.textTertiary)),
                      ],
                    ),
                  ),
                  if (showLateWarning) ...[
                    const Tooltip(
                      message: 'A saída ainda não foi registrada',
                      child: Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.statusRed),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (done && record.pending) ...[
                    Tooltip(
                      message: 'Aguardando sincronização',
                      child: Icon(Icons.cloud_off_rounded, size: 15, color: context.textTertiary),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_loadingRecords)
                    const AppSkeleton(width: 40, height: 14)
                  else
                    Text(
                      done ? formatClock(record.recordedAt) : '--:--',
                      style: AppText.numeric(AppText.bodySm(
                          color: done ? context.textPrimary : context.textTertiary, weight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
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
            Text(formatHours(_monthWorked),
                style: AppText.numeric(AppText.body(color: context.accentPeach, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}
