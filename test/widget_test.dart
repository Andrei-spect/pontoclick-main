import 'package:flutter_test/flutter_test.dart';

import 'package:pontoclick/time_record.dart';

TimeRecord _r(PunchType type, int hour, int minute) => TimeRecord(
      type: type,
      recordedAt: DateTime(2026, 11, 9, hour, minute),
      workDate: '2026-11-09',
    );

TimeRecord _at(PunchType type, DateTime when, String workDate) =>
    TimeRecord(type: type, recordedAt: when, workDate: workDate);

void main() {
  group('currentWorkDate (turno da noite)', () {
    test('sem pontos, o dia é hoje', () {
      expect(currentWorkDate([], DateTime(2026, 11, 10, 9, 0)), '2026-11-10');
    });

    test('entrada às 22h: a saída depois da meia-noite fica no dia da entrada', () {
      final records = [_at(PunchType.entrada, DateTime(2026, 11, 9, 22, 0), '2026-11-09')];
      expect(currentWorkDate(records, DateTime(2026, 11, 10, 6, 0)), '2026-11-09');
    });

    test('entrada esquecida há mais de 16 h: abre um dia novo', () {
      final records = [_at(PunchType.entrada, DateTime(2026, 11, 9, 8, 0), '2026-11-09')];
      expect(currentWorkDate(records, DateTime(2026, 11, 10, 8, 0)), '2026-11-10');
    });

    test('turno de ontem já fechado: o dia é hoje', () {
      final records = [
        _at(PunchType.entrada, DateTime(2026, 11, 9, 22, 0), '2026-11-09'),
        _at(PunchType.intervaloInicio, DateTime(2026, 11, 10, 1, 0), '2026-11-09'),
        _at(PunchType.intervaloFim, DateTime(2026, 11, 10, 2, 0), '2026-11-09'),
        _at(PunchType.saida, DateTime(2026, 11, 10, 6, 0), '2026-11-09'),
      ];
      expect(currentWorkDate(records, DateTime(2026, 11, 10, 7, 0)), '2026-11-10');
    });

    test('se hoje já tem ponto, o dia é hoje', () {
      final records = [
        _at(PunchType.entrada, DateTime(2026, 11, 9, 22, 0), '2026-11-09'),
        _at(PunchType.entrada, DateTime(2026, 11, 10, 7, 0), '2026-11-10'),
      ];
      expect(currentWorkDate(records, DateTime(2026, 11, 10, 8, 0)), '2026-11-10');
    });

    test('horas de um turno que atravessa a meia-noite', () {
      final day = [
        _at(PunchType.entrada, DateTime(2026, 11, 9, 22, 0), '2026-11-09'),
        _at(PunchType.intervaloInicio, DateTime(2026, 11, 10, 2, 0), '2026-11-09'),
        _at(PunchType.intervaloFim, DateTime(2026, 11, 10, 3, 0), '2026-11-09'),
        _at(PunchType.saida, DateTime(2026, 11, 10, 6, 0), '2026-11-09'),
      ];
      expect(workedDuration(day), const Duration(hours: 7));
    });
  });

  group('workedDuration', () {
    test('dia completo desconta o intervalo', () {
      final day = [
        _r(PunchType.entrada, 8, 2),
        _r(PunchType.intervaloInicio, 12, 0),
        _r(PunchType.intervaloFim, 13, 1),
        _r(PunchType.saida, 17, 5),
      ];
      expect(workedDuration(day), const Duration(hours: 8, minutes: 2));
    });

    test('dia em andamento usa a hora atual', () {
      final day = [_r(PunchType.entrada, 8, 0)];
      expect(workedDuration(day, now: DateTime(2026, 11, 9, 10, 30)), const Duration(hours: 2, minutes: 30));
    });

    test('dia antigo sem saída conta zero', () {
      expect(workedDuration([_r(PunchType.entrada, 8, 0)]), Duration.zero);
    });
  });

  test('formatação de horários', () {
    expect(formatHours(const Duration(hours: 5, minutes: 9)), '5h 09m');
    expect(formatClock(DateTime(2026, 1, 1, 7, 5)), '07:05');
    expect(workDateOf(DateTime(2026, 3, 4)), '2026-03-04');
  });

  test('tipos de ponto usam os nomes da API', () {
    expect(PunchType.intervaloInicio.wire, 'intervalo');
    expect(punchTypeFromWire('volta_intervalo'), PunchType.intervaloFim);
    expect(punchTypeFromWire('completo'), isNull);
  });
}
