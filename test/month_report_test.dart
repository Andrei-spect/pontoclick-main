import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:pontoclick/month_report.dart';
import 'package:pontoclick/time_record.dart';

TimeRecord _r(PunchType type, String day, int hour, int minute) =>
    TimeRecord(type: type, recordedAt: DateTime.parse('${day}T${two(hour)}:${two(minute)}:00'), workDate: day);

List<TimeRecord> _day(String day, (int, int) entrada, (int, int) saida) => [
      _r(PunchType.entrada, day, entrada.$1, entrada.$2),
      _r(PunchType.intervaloInicio, day, 12, 0),
      _r(PunchType.intervaloFim, day, 13, 0),
      _r(PunchType.saida, day, saida.$1, saida.$2),
    ];

void main() {
  test('relatório mensal em PDF é gerado com horas extras', () async {
    final byDay = {
      '2026-11-09': _day('2026-11-09', (8, 0), (17, 0)), // 8h00 — sem extra
      '2026-11-10': _day('2026-11-10', (8, 0), (18, 30)), // 9h30 — +1h30
      '2026-11-11': _day('2026-11-11', (7, 45), (17, 30)), // 8h45 — +0h45
      '2026-11-12': [_r(PunchType.entrada, '2026-11-12', 8, 0)], // sem saída — não conta
    };

    final bytes = await buildMonthReportPdf(
      year: 2026,
      month: 11,
      byDay: byDay,
      userName: 'Teste Extras',
      userEmail: 'teste@pontoclick.test',
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    // Para conferir visualmente: flutter test --dart-define=REPORT_OUT=<caminho.pdf>
    const out = String.fromEnvironment('REPORT_OUT');
    if (out.isNotEmpty) await File(out).writeAsBytes(bytes);
  });
}
