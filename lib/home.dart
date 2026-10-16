import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'theme_controller.dart';
import 'location_service.dart';
import 'records.dart';
import 'profile.dart';

/// Ordem esperada dos pontos batidos num dia normal de trabalho.
enum PunchType { entrada, intervaloInicio, intervaloFim, saida, completo }

class PunchTypeInfo {
  final String label; // rótulo exibido na timeline
  final String actionLabel; // texto do botão para BATER esse ponto
  final Color color;

  const PunchTypeInfo({required this.label, required this.actionLabel, required this.color});
}

const Map<PunchType, PunchTypeInfo> punchTypeInfo = {
  PunchType.entrada: PunchTypeInfo(label: 'Entrada', actionLabel: 'Bater Ponto (Entrada)', color: AppColors.statusGreen),
  PunchType.intervaloInicio: PunchTypeInfo(
      label: 'Início Intervalo', actionLabel: 'Bater Ponto (Início Intervalo)', color: AppColors.statusOrange),
  PunchType.intervaloFim: PunchTypeInfo(
      label: 'Fim Intervalo', actionLabel: 'Bater Ponto (Retorno)', color: AppColors.statusBlue),
  PunchType.saida: PunchTypeInfo(label: 'Saída', actionLabel: 'Bater Ponto (Saída)', color: AppColors.statusRed),
};

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

  // TODO: substituir por dados reais vindos da API (GET /records de hoje).
  // Mockado já com Entrada/Intervalo/Retorno feitos, faltando só a Saída —
  // mesmo cenário do mockup aprovado.
  final List<MapEntry<PunchType, DateTime>> _todayPunches = [
    MapEntry(PunchType.entrada, DateTime.now().copyWith(hour: 8, minute: 0, second: 0)),
    MapEntry(PunchType.intervaloInicio, DateTime.now().copyWith(hour: 12, minute: 0, second: 0)),
    MapEntry(PunchType.intervaloFim, DateTime.now().copyWith(hour: 13, minute: 0, second: 0)),
  ];

  final LocationService _locationService = LocationService();
  LocationResult? _locationResult;
  bool _loadingLocation = true;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadLocation();
    _initConnectivity();
    _loadPendingSyncCount();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _locationResult = result;
      _loadingLocation = false;
    });
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
    if (online && _pendingSyncCount > 0) {
      _syncPendingRecords();
    }
  }

  Future<void> _loadPendingSyncCount() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_punches') ?? [];
    if (!mounted) return;
    setState(() => _pendingSyncCount = pending.length);
  }

  Future<void> _syncPendingRecords() async {
    if (_isSyncing || _pendingSyncCount == 0) return;
    setState(() => _isSyncing = true);

    // TODO: enviar cada ponto pendente para POST /records da API real.
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pending_punches', []);

    if (!mounted) return;
    setState(() {
      _pendingSyncCount = 0;
      _isSyncing = false;
    });
  }

  PunchType get _nextPunchType {
    if (_todayPunches.length >= 4) return PunchType.completo;
    return PunchType.values[_todayPunches.length];
  }

  Future<void> _registrarPonto() async {
    final type = _nextPunchType;
    if (type == PunchType.completo) return;

    setState(() => _todayPunches.add(MapEntry(type, DateTime.now())));

    if (!_isOnline) {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_punches') ?? [];
      pending.add('${type.name}|${DateTime.now().toIso8601String()}');
      await prefs.setStringList('pending_punches', pending);
      if (!mounted) return;
      setState(() => _pendingSyncCount = pending.length);
    }
  }

  Duration get _workedToday {
    final entrada = _todayPunches.where((p) => p.key == PunchType.entrada).firstOrNull;
    if (entrada == null) return Duration.zero;

    Duration worked = _now.difference(entrada.value);

    final breakStart = _todayPunches.where((p) => p.key == PunchType.intervaloInicio).firstOrNull;
    final breakEnd = _todayPunches.where((p) => p.key == PunchType.intervaloFim).firstOrNull;
    if (breakStart != null) {
      final breakEndTime = breakEnd?.value ?? _now;
      worked -= breakEndTime.difference(breakStart.value);
    }
    return worked;
  }

  /// Se o usuário está em intervalo agora (bateu início, ainda não bateu volta).
  bool get _isOnBreak => _todayPunches.any((p) => p.key == PunchType.intervaloInicio) &&
      !_todayPunches.any((p) => p.key == PunchType.intervaloFim);

  int get _breakRemainingMinutes {
    final breakStart = _todayPunches.where((p) => p.key == PunchType.intervaloInicio).firstOrNull;
    if (breakStart == null) return 0;
    final elapsed = _now.difference(breakStart.value).inMinutes;
    return _breakLimitMinutes - elapsed;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final gpsOff = _locationResult?.status == LocationStatus.serviceDisabled ||
        _locationResult?.status == LocationStatus.permissionDenied ||
        _locationResult?.status == LocationStatus.permissionDeniedForever;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (gpsOff) _buildGpsAlert(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow(context),
                    const SizedBox(height: 20),
                    _buildClock(context),
                    const SizedBox(height: 16),
                    _buildLocationCard(context),
                    const SizedBox(height: 20),
                    _buildMainCta(context),
                    const SizedBox(height: 20),
                    _buildTimeline(context),
                    const SizedBox(height: 16),
                    _buildHoursBankCard(context),
                    const SizedBox(height: 12),
                    _buildSyncRow(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildGpsAlert(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.statusRed.withOpacity(0.15),
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
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isOnline ? AppColors.statusGreen : AppColors.statusRed,
          ),
        ),
        const SizedBox(width: 6),
        Text(_isOnline ? 'Online' : 'Offline', style: AppText.caption(color: context.textSecondary)),
        const Spacer(),
        IconButton(
          tooltip: 'Alternar tema',
          icon: Icon(context.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.textSecondary, size: 20),
          onPressed: ThemeController.toggle,
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).cardColor),
          alignment: Alignment.center,
          child: Text('JS', style: AppText.caption(weight: FontWeight.w600)),
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
    final horaFormatada =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dataFormatada, style: AppText.caption(color: context.textSecondary).copyWith(fontSize: 13)),
        Text(horaFormatada, style: AppText.headingLg().copyWith(fontFeatures: [const FontFeature.tabularFigures()])),
      ],
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    String label;
    Color labelColor = context.accentPeach;
    if (_loadingLocation) {
      label = 'Buscando localização...';
      labelColor = context.textSecondary;
    } else if (_locationResult?.status == LocationStatus.serviceDisabled) {
      label = 'GPS desativado';
      labelColor = AppColors.statusRed;
    } else if (_locationResult?.status == LocationStatus.permissionDenied ||
        _locationResult?.status == LocationStatus.permissionDeniedForever) {
      label = 'Permissão de localização negada';
      labelColor = AppColors.statusRed;
    } else if (_locationResult?.matchedLocation != null) {
      label = _locationResult!.matchedLocation!.name;
    } else if (_locationResult?.isOk == true) {
      label = 'Local não identificado';
      labelColor = context.textSecondary;
    } else {
      label = 'Não foi possível obter a localização';
      labelColor = context.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 15, color: context.accentPeach),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppText.caption(color: Theme.of(context).colorScheme.onSurface).copyWith(fontSize: 13),
                    children: [
                      const TextSpan(text: 'Você está em: '),
                      TextSpan(text: label, style: TextStyle(color: labelColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, size: 16, color: context.textTertiary),
                onPressed: () {
                  setState(() => _loadingLocation = true);
                  _loadLocation();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 72,
            decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(AppRadius.images)),
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.twilightViolet.withOpacity(0.18), shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(color: AppColors.twilightViolet, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          ),
          if (_locationResult?.accuracyMeters != null) ...[
            const SizedBox(height: 8),
            Text('Precisão do GPS: ${_locationResult!.accuracyMeters!.toStringAsFixed(0)}m',
                style: AppText.caption(color: context.textTertiary)),
          ],
        ],
      ),
    );
  }

  Widget _buildMainCta(BuildContext context) {
    final type = _nextPunchType;
    final isDone = type == PunchType.completo;
    final info = isDone
        ? const PunchTypeInfo(label: '', actionLabel: 'Jornada Concluída', color: AppColors.statusGreen)
        : punchTypeInfo[type]!;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isDone ? null : _registrarPonto,
            style: ElevatedButton.styleFrom(
              backgroundColor: info.color,
              disabledBackgroundColor: info.color.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
            ),
            child: Text(info.actionLabel, style: AppText.body(color: Colors.white, weight: FontWeight.w700).copyWith(fontSize: 14)),
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: AppText.caption(color: context.textSecondary).copyWith(fontSize: 13),
            children: [
              const TextSpan(text: 'Tempo trabalhado hoje: '),
              TextSpan(
                text: _formatDuration(_workedToday),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (_isOnBreak) ...[
          const SizedBox(height: 4),
          Text(
            _breakRemainingMinutes >= 0
                ? 'Retorno do intervalo em ${_breakRemainingMinutes}min'
                : 'Intervalo excedido em ${-_breakRemainingMinutes}min',
            style: AppText.caption(color: _breakRemainingMinutes >= 0 ? context.textTertiary : AppColors.statusRed),
          ),
        ],
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pills),
          child: LinearProgressIndicator(
            value: (_workedToday.inSeconds / _dailyGoal.inSeconds).clamp(0, 1).toDouble(),
            minHeight: 4,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation(context.accentPeach),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context) {
    final now = DateTime.now();
    final saidaPendingLate = _nextPunchType == PunchType.saida && now.hour >= 20;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RESUMO DO DIA', style: AppText.caption(color: context.textTertiary, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final type in [PunchType.entrada, PunchType.intervaloInicio, PunchType.intervaloFim, PunchType.saida])
            _buildTimelineRow(context, type, saidaPendingLate && type == PunchType.saida),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(BuildContext context, PunchType type, bool showLateWarning) {
    final punch = _todayPunches.where((p) => p.key == type).firstOrNull;
    final info = punchTypeInfo[type]!;
    final done = punch != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? info.color : Colors.transparent,
              border: done ? null : Border.all(color: context.textTertiary, width: 1.5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(info.label,
                style: AppText.body(color: done ? Theme.of(context).colorScheme.onSurface : context.textTertiary)
                    .copyWith(fontSize: 14)),
          ),
          if (showLateWarning) ...[
            const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.statusRed),
            const SizedBox(width: 4),
          ],
          Text(
            done ? _formatTime(punch.value) : '--:--',
            style: AppText.body(color: done ? Theme.of(context).colorScheme.onSurface : context.textTertiary, weight: FontWeight.w600)
                .copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursBankCard(BuildContext context) {
    // TODO: vir do backend (soma de horas extra/faltantes do mês).
    const saldoMes = '+02:15';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Banco de horas (mês)', style: AppText.caption(color: context.textSecondary).copyWith(fontSize: 13)),
          Text(saldoMes, style: AppText.body(color: context.accentPeach, weight: FontWeight.w600).copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSyncRow(BuildContext context) {
    if (_pendingSyncCount == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text('0 registros pendentes de sincronização', style: AppText.caption(color: context.textTertiary)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$_pendingSyncCount ${_pendingSyncCount == 1 ? "registro salvo" : "registros salvos"} no dispositivo. Sincronizando quando houver internet...',
              style: AppText.caption(color: context.textTertiary),
            ),
          ),
          TextButton(
            onPressed: _isOnline && !_isSyncing ? _syncPendingRecords : null,
            child: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar', style: AppText.caption(color: AppColors.twilightViolet, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Route _fadeRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(60, 0, 60, 20),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.pills),
        boxShadow: [BoxShadow(color: const Color(0xFF68410D).withOpacity(0.23), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Ponto', style: AppText.caption(color: Theme.of(context).colorScheme.onSurface, weight: FontWeight.w600)),
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, _fadeRoute(const RecordsScreen()));
            },
            child: Text('Registros', style: AppText.caption(color: context.textTertiary, weight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, _fadeRoute(const ProfileScreen()));
            },
            child: Text('Perfil', style: AppText.caption(color: context.textTertiary, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
