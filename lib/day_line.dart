import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'time_record.dart';

/// Tipo de cada trecho da barra da jornada.
enum DayBlockKind { work, extra, pause }

/// Um trecho da jornada (trabalho dentro da meta, hora extra ou intervalo).
class DayBlock {
  final DayBlockKind kind;
  final DateTime start;
  final DateTime end;
  const DayBlock(this.kind, this.start, this.end);

  Duration get duration => end.difference(start);

  @override
  String toString() => '$kind ${formatClock(start)}-${formatClock(end)}';
}

/// Trechos da jornada de um dia, a partir dos pontos batidos.
///
/// - Trabalho: entrada → início do intervalo (ou saída) e volta → saída.
/// - Intervalo: início → volta.
/// - O que ainda está aberto vai até [now] (dia em andamento).
/// - A hora extra começa quando o trabalho somado passa de [goal] (mesma regra
///   de [overtimeOf]); com meta zero (folga), todo o trabalho é extra.
List<DayBlock> dayBlocks(List<TimeRecord> day, Duration goal, DateTime now) {
  DateTime? at(PunchType t) => day.where((r) => r.type == t).firstOrNull?.recordedAt;
  final entrada = at(PunchType.entrada);
  if (entrada == null) return const [];
  final intervalo = at(PunchType.intervaloInicio);
  final volta = at(PunchType.intervaloFim);
  final saida = at(PunchType.saida);

  DateTime cap(DateTime t) => t.isAfter(now) ? now : t;
  final workSpans = <(DateTime, DateTime)>[
    (entrada, cap(intervalo ?? saida ?? now)),
    if (volta != null) (volta, cap(saida ?? now)),
  ];

  final blocks = <DayBlock>[];
  var accumulated = Duration.zero;
  for (var i = 0; i < workSpans.length; i++) {
    final (start, end) = workSpans[i];
    if (!end.isAfter(start)) continue;
    final left = goal - accumulated;
    final cut = left <= Duration.zero ? start : (start.add(left).isBefore(end) ? start.add(left) : end);
    if (cut.isAfter(start)) blocks.add(DayBlock(DayBlockKind.work, start, cut));
    if (end.isAfter(cut)) blocks.add(DayBlock(DayBlockKind.extra, cut, end));
    accumulated += end.difference(start);
    if (i == 0 && intervalo != null) {
      final pauseEnd = cap(volta ?? now);
      if (pauseEnd.isAfter(intervalo)) blocks.add(DayBlock(DayBlockKind.pause, intervalo, pauseEnd));
    }
  }
  blocks.sort((a, b) => a.start.compareTo(b.start));
  return blocks;
}

/// Hora extra dentro de um trecho de trabalho [start, end).
Duration _extraWithin(List<DayBlock> blocks, DateTime start, DateTime end) {
  var total = Duration.zero;
  for (final b in blocks.where((b) => b.kind == DayBlockKind.extra)) {
    final s = b.start.isAfter(start) ? b.start : start;
    final e = b.end.isBefore(end) ? b.end : end;
    if (e.isAfter(s)) total += e.difference(s);
  }
  return total;
}

/// "Linha do dia": barra da jornada (trabalho, intervalo e hora extra numa
/// régua de horas) + linha do tempo das 4 marcações com a duração de cada trecho.
class DayLine extends StatelessWidget {
  final List<TimeRecord> records;
  final Duration goal;
  final DateTime now;

  /// Dia ainda em andamento (os trechos abertos vão até agora).
  final bool inProgress;

  /// Texto abaixo do nome de cada marcação (local, "Salvo no aparelho"...).
  final String Function(TimeRecord record) detailOf;

  /// Selos antes do horário de cada marcação (ex: "Editado", não sincronizado).
  final List<Widget> Function(TimeRecord record)? trailingOf;

  /// Ação depois do horário (ex: lápis para corrigir o horário).
  final Widget? Function(TimeRecord record)? actionOf;

  const DayLine({
    super.key,
    required this.records,
    required this.goal,
    required this.now,
    required this.inProgress,
    required this.detailOf,
    this.trailingOf,
    this.actionOf,
  });

  static const _types = [PunchType.entrada, PunchType.intervaloInicio, PunchType.intervaloFim, PunchType.saida];

  @override
  Widget build(BuildContext context) {
    final blocks = dayBlocks(records, goal, now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (blocks.isNotEmpty) ...[
          _JourneyBar(blocks: blocks),
          const SizedBox(height: 8),
          _legend(context),
          const SizedBox(height: 16),
        ],
        ..._timeline(context, blocks),
      ],
    );
  }

  Widget _legend(BuildContext context) {
    Widget item(Widget swatch, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          swatch,
          const SizedBox(width: 6),
          Text(label, style: AppText.caption(color: context.textTertiary).copyWith(fontSize: 11.5)),
        ]);
    Widget box(Color c) => Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)));
    return Wrap(spacing: 14, runSpacing: 4, children: [
      item(box(AppColors.twilightViolet), 'Trabalho'),
      item(SizedBox(width: 10, height: 10, child: CustomPaint(painter: _StripesPainter(context.textTertiary))), 'Intervalo'),
      item(box(context.accentPeach), 'Hora extra'),
    ]);
  }

  List<Widget> _timeline(BuildContext context, List<DayBlock> blocks) {
    final byType = {for (final r in records) r.type: r};
    final nextType = _types.where((t) => !byType.containsKey(t)).firstOrNull;
    final rows = <Widget>[];

    for (var i = 0; i < _types.length; i++) {
      final type = _types[i];
      final record = byType[type];
      final info = punchTypeInfo[type]!;
      final isNext = inProgress && type == nextType;
      rows.add(_row(context, info, record, isNext));
      if (i == _types.length - 1) break;

      // Trecho entre esta marcação e a próxima.
      final nextRecord = byType[_types[i + 1]];
      final isPause = type == PunchType.intervaloInicio;
      String? chip;
      Duration extra = Duration.zero;
      var ongoing = false;
      if (record != null && nextRecord != null) {
        chip = '${formatGoal(nextRecord.recordedAt.difference(record.recordedAt))} de ${isPause ? 'intervalo' : 'trabalho'}';
        if (!isPause) extra = _extraWithin(blocks, record.recordedAt, nextRecord.recordedAt);
      } else if (record != null && inProgress && _types[i + 1] == nextType && now.isAfter(record.recordedAt)) {
        chip = '${isPause ? 'Em intervalo' : 'Trabalhando'} há ${formatGoal(now.difference(record.recordedAt))}';
        if (!isPause) extra = _extraWithin(blocks, record.recordedAt, now);
        ongoing = true;
      }
      rows.add(_gap(context, chip: chip, extra: extra, pause: isPause, ongoing: ongoing, active: record != null));
    }
    return rows;
  }

  Widget _row(BuildContext context, PunchTypeInfo info, TimeRecord? record, bool isNext) {
    final done = record != null;
    return Semantics(
      label: '${info.label}: ${done ? formatClock(record.recordedAt) : (isNext ? 'próximo registro' : 'aguardando')}',
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: done || isNext ? info.color : context.border, width: 3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.label,
                    style: AppText.label(color: done ? context.textPrimary : context.textTertiary, weight: FontWeight.w600)
                        .copyWith(fontSize: 14)),
                const SizedBox(height: 1),
                Text(done ? detailOf(record) : (isNext ? 'Próximo registro' : 'Aguardando'),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption(color: context.textTertiary)),
              ],
            ),
          ),
          if (done) ...?trailingOf?.call(record),
          Text(
            done ? formatClock(record.recordedAt) : '--:--',
            style: AppText.numeric(AppText.headingSm(color: done ? context.textPrimary : context.textTertiary, weight: FontWeight.w700)
                .copyWith(fontSize: 19, letterSpacing: -0.4)),
          ),
          if (actionOf != null) (done ? actionOf!(record) : null) ?? const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _gap(BuildContext context,
      {String? chip, required Duration extra, required bool pause, required bool ongoing, required bool active}) {
    final lineColor = AppColors.twilightViolet.withValues(alpha: active ? 0.45 : 0.15);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Center(
              child: pause
                  ? CustomPaint(size: const Size(2, double.infinity), painter: _DashPainter(context.textTertiary.withValues(alpha: 0.7)))
                  : Container(width: 2, color: lineColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: chip == null
                    ? const SizedBox(height: 14)
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.cardRaised,
                          borderRadius: BorderRadius.circular(AppRadius.pills),
                          border: ongoing ? Border.all(color: context.border) : null,
                        ),
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: chip),
                            if (extra > Duration.zero)
                              TextSpan(
                                text: ' · ${formatGoal(extra)} extra',
                                style: TextStyle(color: context.accentPeach, fontWeight: FontWeight.w600),
                              ),
                          ]),
                          style: AppText.numeric(AppText.caption(color: context.textSecondary, weight: FontWeight.w500)),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra horizontal da jornada com a régua de horas embaixo.
class _JourneyBar extends StatelessWidget {
  final List<DayBlock> blocks;
  const _JourneyBar({required this.blocks});

  @override
  Widget build(BuildContext context) {
    // Régua: da hora cheia antes do primeiro trecho até a hora cheia depois do último,
    // com pelo menos 8 h de largura para os trechos não ficarem espremidos.
    final first = blocks.first.start;
    final last = blocks.map((b) => b.end).reduce((a, b) => a.isAfter(b) ? a : b);
    var start = DateTime(first.year, first.month, first.day, first.hour);
    var end = DateTime(last.year, last.month, last.day, last.hour).add(const Duration(hours: 1));
    if (end.difference(start) < const Duration(hours: 8)) end = start.add(const Duration(hours: 8));
    final totalMin = end.difference(start).inMinutes;
    final step = totalMin <= 10 * 60 ? 2 : (totalMin <= 16 * 60 ? 3 : 4);
    final ticks = <DateTime>[
      for (var t = start; !t.isAfter(end); t = t.add(Duration(hours: step))) t,
    ];

    double frac(DateTime t) => (t.difference(start).inMinutes / totalMin).clamp(0, 1).toDouble();

    final label = blocks
        .map((b) => '${switch (b.kind) { DayBlockKind.work => 'trabalho', DayBlockKind.extra => 'hora extra', DayBlockKind.pause => 'intervalo' }} '
            'das ${formatClock(b.start)} às ${formatClock(b.end)}')
        .join(', ');

    return Semantics(
      label: 'Jornada: $label',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pills),
                child: Container(
                  height: 16,
                  color: context.cardRaised,
                  child: Stack(
                    children: [
                      for (final b in blocks)
                        Positioned(
                          left: w * frac(b.start),
                          width: (w * (frac(b.end) - frac(b.start))).clamp(1.0, w),
                          top: 0,
                          bottom: 0,
                          child: b.kind == DayBlockKind.pause
                              ? CustomPaint(painter: _StripesPainter(context.textTertiary))
                              : ColoredBox(color: b.kind == DayBlockKind.work ? AppColors.twilightViolet : context.accentPeach),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final t in ticks)
                      Positioned(
                        left: (w * frac(t) - 12).clamp(0.0, w - 24),
                        width: 24,
                        child: Text(
                          '${two(t.hour)}h',
                          textAlign: t == ticks.first ? TextAlign.left : (t == ticks.last ? TextAlign.right : TextAlign.center),
                          style: AppText.numeric(AppText.caption(color: context.textTertiary).copyWith(fontSize: 10.5)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Listras diagonais do intervalo.
class _StripesPainter extends CustomPainter {
  final Color color;
  _StripesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (double x = -size.height; x < size.width + size.height; x += 6) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripesPainter old) => old.color != color;
}

/// Linha tracejada vertical (trecho do intervalo na linha do tempo).
class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, (y + 4).clamp(0, size.height)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}
