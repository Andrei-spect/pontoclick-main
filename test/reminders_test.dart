import 'package:flutter_test/flutter_test.dart';

import 'package:pontoclick/notification_service.dart';

void main() {
  // 10/11/2026 é uma terça-feira.
  final tuesday0700 = DateTime(2026, 11, 10, 7, 0);

  group('plannedReminders', () {
    test('lembretes desligados: nada agendado', () {
      final settings = ReminderSettings.defaults.copyWith(enabled: false);
      expect(plannedReminders(settings, tuesday0700, {}), isEmpty);
    });

    test('padrão: 4 lembretes por dia útil nos próximos 14 dias', () {
      final list = plannedReminders(ReminderSettings.defaults, tuesday0700, {});
      expect(list.length, 10 * 4); // 10 dias úteis em 14 dias corridos a partir de terça
      expect(list.first.key, 'entrada');
      expect(list.first.when, DateTime(2026, 11, 10, 8, 0));
      expect(list.every((r) => r.when.weekday <= 5), isTrue);
    });

    test('horários que já passaram hoje não são agendados', () {
      final list = plannedReminders(ReminderSettings.defaults, DateTime(2026, 11, 10, 12, 30), {});
      final today = list.where((r) => r.when.day == 10).map((r) => r.key).toList();
      expect(today, ['volta', 'saida']);
    });

    test('ponto já batido hoje não gera lembrete hoje (mas gera nos próximos dias)', () {
      final list = plannedReminders(ReminderSettings.defaults, tuesday0700, {'entrada'});
      final todayKeys = list.where((r) => r.when.day == 10).map((r) => r.key);
      expect(todayKeys, isNot(contains('entrada')));
      expect(list.any((r) => r.when.day == 11 && r.key == 'entrada'), isTrue);
    });

    test('turno da noite: a saída cai no dia seguinte ao da entrada', () {
      final settings = ReminderSettings.defaults.copyWith(
        days: [2],
        reminders: {
          'entrada': const ReminderItem(enabled: true, time: '22:00'),
          'intervalo': const ReminderItem(enabled: false, time: '02:00'),
          'volta': const ReminderItem(enabled: false, time: '03:00'),
          'saida': const ReminderItem(enabled: true, time: '06:00'),
        },
      );
      final list = plannedReminders(settings, tuesday0700, {}, days: 1);
      expect(list.map((r) => (r.key, r.when)).toList(), [
        ('entrada', DateTime(2026, 11, 10, 22, 0)),
        ('saida', DateTime(2026, 11, 11, 6, 0)),
      ]);
    });

    test('ids únicos (o aparelho substitui avisos com o mesmo id)', () {
      final list = plannedReminders(ReminderSettings.defaults.copyWith(days: [1, 2, 3, 4, 5, 6, 7]), tuesday0700, {});
      expect(list.map((r) => r.id).toSet().length, list.length);
    });

    test('preferências vão e voltam da API sem perder nada', () {
      final settings = ReminderSettings.defaults.withReminder('saida', const ReminderItem(enabled: false, time: '18:30'));
      expect(ReminderSettings.fromJson(settings.toJson()), settings);
    });
  });
}
