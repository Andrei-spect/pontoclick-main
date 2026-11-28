import 'package:flutter_test/flutter_test.dart';

import 'package:pontoclick/day_line.dart';
import 'package:pontoclick/time_record.dart';

TimeRecord _r(PunchType type, int h, int m, {int day = 27}) =>
    TimeRecord(type: type, recordedAt: DateTime(2026, 11, day, h, m), workDate: '2026-11-27');

String _fmt(List<DayBlock> blocks) => blocks.map((b) => b.toString()).join(' | ');

void main() {
  const meta8h = Duration(hours: 8);

  test('dia completo: a extra começa quando o trabalho passa de 8h', () {
    final day = [
      _r(PunchType.entrada, 7, 50),
      _r(PunchType.intervaloInicio, 12, 0),
      _r(PunchType.intervaloFim, 13, 0),
      _r(PunchType.saida, 17, 38),
    ];
    final blocks = dayBlocks(day, meta8h, DateTime(2026, 11, 27, 21));
    expect(_fmt(blocks), 'DayBlockKind.work 07:50-12:00 | DayBlockKind.pause 12:00-13:00 | '
        'DayBlockKind.work 13:00-16:50 | DayBlockKind.extra 16:50-17:38');
  });

  test('dia em andamento: o trecho aberto vai até agora', () {
    final day = [_r(PunchType.entrada, 8, 0), _r(PunchType.intervaloInicio, 12, 0)];
    final blocks = dayBlocks(day, meta8h, DateTime(2026, 11, 27, 12, 20));
    expect(_fmt(blocks), 'DayBlockKind.work 08:00-12:00 | DayBlockKind.pause 12:00-12:20');
  });

  test('folga (meta zero): todo o trabalho é hora extra', () {
    final day = [_r(PunchType.entrada, 9, 0), _r(PunchType.saida, 11, 30)];
    final blocks = dayBlocks(day, Duration.zero, DateTime(2026, 11, 27, 20));
    expect(_fmt(blocks), 'DayBlockKind.extra 09:00-11:30');
  });

  test('turno da noite atravessa a meia-noite', () {
    final day = [
      _r(PunchType.entrada, 22, 0),
      _r(PunchType.intervaloInicio, 2, 0, day: 28),
      _r(PunchType.intervaloFim, 3, 0, day: 28),
      _r(PunchType.saida, 7, 30, day: 28),
    ];
    final blocks = dayBlocks(day, meta8h, DateTime(2026, 11, 28, 9));
    expect(blocks.map((b) => b.kind).toList(),
        [DayBlockKind.work, DayBlockKind.pause, DayBlockKind.work, DayBlockKind.extra]);
    expect(blocks.last.duration, const Duration(minutes: 30));
  });

  test('sem entrada não há trechos', () {
    expect(dayBlocks(const [], meta8h, DateTime(2026, 11, 27, 9)), isEmpty);
  });
}
