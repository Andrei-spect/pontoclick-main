import 'package:flutter_test/flutter_test.dart';

import 'package:pontoclick/time_record.dart';
import 'package:pontoclick/work_schedule.dart';

void main() {
  const padrao = WorkSchedule.defaults;

  test('horário padrão: seg-sex 8h, sábado 4h (turno da manhã), domingo folga', () {
    expect(padrao.goalForWorkDate('2026-11-13'), const Duration(hours: 8)); // sexta
    expect(padrao.goalForWorkDate('2026-11-14'), const Duration(hours: 4)); // sábado
    expect(padrao.goalForWorkDate('2026-11-15'), Duration.zero); // domingo
  });

  test('meta segue o horário cadastrado pela pessoa', () {
    final meu = padrao.copyWith(
      weekdays: const ShiftHours(entrada: '07:00', saida: '16:48', intervaloMin: 60), // 8h48
      weekend: const ShiftHours(entrada: '06:00', saida: '12:00', intervaloMin: 30), // 5h30
      saturday: false,
      sunday: true,
    );
    expect(meu.goalForWorkDate('2026-11-16'), const Duration(hours: 8, minutes: 48)); // segunda
    expect(meu.goalForWorkDate('2026-11-14'), Duration.zero); // sábado: folga
    expect(meu.goalForWorkDate('2026-11-15'), const Duration(hours: 5, minutes: 30)); // domingo
  });

  test('turno da noite: saída mais cedo que a entrada termina no dia seguinte', () {
    const noite = ShiftHours(entrada: '22:00', saida: '06:00', intervaloMin: 60);
    expect(noite.isOvernight, isTrue);
    expect(noite.span, const Duration(hours: 8));
    expect(noite.workDuration, const Duration(hours: 7));
    expect(noite.validate('x'), isNull);
  });

  test('validação igual à da API', () {
    expect(const ShiftHours(entrada: '08:00', saida: '08:00', intervaloMin: 0).validate('x'), isNotNull);
    expect(const ShiftHours(entrada: '08:00', saida: '09:00', intervaloMin: 60).validate('x'), isNotNull);
    expect(const ShiftHours(entrada: '05:00', saida: '22:00', intervaloMin: 60).validate('x'), isNotNull); // 17h
    expect(const ShiftHours(entrada: '08:00', saida: '17:00', intervaloMin: 60).validate('x'), isNull);
  });

  test('horas extras contam a partir da meta do dia; na folga tudo é extra', () {
    expect(overtimeOf(const Duration(hours: 6), goal: padrao.goalForWorkDate('2026-11-14')), const Duration(hours: 2));
    expect(overtimeOf(const Duration(hours: 6), goal: padrao.goalForWorkDate('2026-11-13')), Duration.zero);
    expect(overtimeOf(const Duration(hours: 3), goal: padrao.goalForWorkDate('2026-11-15')), const Duration(hours: 3));
  });

  test('JSON da API ida e volta', () {
    final json = padrao.copyWith(sunday: true).toJson();
    expect(WorkSchedule.fromJson(json), padrao.copyWith(sunday: true));
    expect(WorkSchedule.fromJson(const {}), padrao); // resposta incompleta cai no padrão
  });

  test('formatGoal', () {
    expect(formatGoal(const Duration(hours: 8)), '8h');
    expect(formatGoal(const Duration(hours: 8, minutes: 48)), '8h 48m');
    expect(formatGoal(const Duration(minutes: 30)), '30m');
  });
}
