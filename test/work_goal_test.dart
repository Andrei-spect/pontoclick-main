import 'package:flutter_test/flutter_test.dart';

import 'package:pontoclick/time_record.dart';

void main() {
  test('meta do dia: sábado tem 4h (turno da manhã), demais dias 8h', () {
    expect(workGoalFor(DateTime(2026, 11, 14)), saturdayWorkGoal); // sábado
    expect(workGoalFor(DateTime(2026, 11, 13)), dailyWorkGoal); // sexta
    expect(workGoalFor(DateTime(2026, 11, 15)), dailyWorkGoal); // domingo
    expect(workGoalForWorkDate('2026-11-14'), const Duration(hours: 4));
    expect(workGoalForWorkDate('2026-11-16'), const Duration(hours: 8));
  });

  test('horas extras no sábado contam a partir de 4h trabalhadas', () {
    final goalSabado = workGoalForWorkDate('2026-11-14');
    expect(overtimeOf(const Duration(hours: 3, minutes: 30), goal: goalSabado), Duration.zero);
    expect(overtimeOf(const Duration(hours: 4), goal: goalSabado), Duration.zero);
    expect(
      overtimeOf(const Duration(hours: 6), goal: goalSabado),
      const Duration(hours: 2),
    );

    // Num dia de semana as mesmas 6h não geram extra.
    final goalSemana = workGoalForWorkDate('2026-11-13');
    expect(overtimeOf(const Duration(hours: 6), goal: goalSemana), Duration.zero);
  });
}
