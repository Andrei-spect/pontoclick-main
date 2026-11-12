import 'dart:typed_data';
import 'package:pdf/pdf.dart' show PdfColors;
import 'package:pdf/widgets.dart' as pw;
import 'time_record.dart';

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];
const _dias = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];

/// Relatório mensal em PDF (tela Registros > Exportar PDF).
///
/// [byDay]: pontos do mês agrupados pelo dia ("2026-11-10"), em ordem de horário.
/// Mostra cada dia com os pontos, o total trabalhado e as horas extras, um
/// resumo do mês no topo e, no final, o total de horas e a soma das horas extras.
Future<Uint8List> buildMonthReportPdf({
  required int year,
  required int month,
  required Map<String, List<TimeRecord>> byDay,
  String? userName,
  String? userEmail,
}) {
  final keys = byDay.keys.toList()..sort();
  var monthTotal = Duration.zero;
  var overtimeTotal = Duration.zero; // soma das horas extras de cada dia (além da meta diária)
  var overtimeDays = 0;
  final body = <pw.Widget>[];

  for (final key in keys) {
    final list = byDay[key]!;
    final worked = workedDuration(list);
    final overtime = overtimeOf(worked);
    monthTotal += worked;
    overtimeTotal += overtime;
    if (overtime > Duration.zero) overtimeDays++;
    final date = DateTime.parse(key);
    body.addAll(<pw.Widget>[
      pw.Text('${two(date.day)}/${two(date.month)}/${date.year} - ${_dias[date.weekday - 1]}',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 3),
      for (final r in list)
        pw.Text(
          '${punchTypeInfo[r.type]?.label ?? ''}: ${formatClock(r.recordedAt)}'
          '${r.edited ? ' (editado)' : ''}${r.locationName != null ? ' - ${r.locationName}' : ''}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      if (worked > Duration.zero)
        pw.Text(
          'Total do dia: ${formatHours(worked)}'
          '${overtime > Duration.zero ? '   |   Horas extras: ${formatOvertime(overtime)}' : ''}',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      pw.SizedBox(height: 10),
    ]);
  }

  // Quadro de resumo do mês (aparece no topo do relatório).
  pw.Widget summaryCell(String label, String value) => pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
  final summary = pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Row(children: [
      summaryCell('Horas trabalhadas', formatHours(monthTotal)),
      summaryCell('Horas extras', formatOvertime(overtimeTotal)),
      summaryCell('Dias com hora extra', '$overtimeDays'),
    ]),
  );

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => <pw.Widget>[
        pw.Text('PontoClick - Registros de ponto', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('${_meses[month - 1]} de $year', style: const pw.TextStyle(fontSize: 12)),
        if (userName != null) pw.Text('Funcionário: $userName ($userEmail)', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 12),
        if (keys.isEmpty) pw.Text('Nenhum registro neste mês.', style: const pw.TextStyle(fontSize: 12)),
        if (keys.isNotEmpty) ...<pw.Widget>[
          summary,
          pw.SizedBox(height: 4),
          pw.Text(
            'Horas extras: tempo trabalhado além da meta de ${dailyWorkGoal.inHours}h em cada dia com entrada e saída.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
        ],
        ...body,
        if (keys.isNotEmpty) ...<pw.Widget>[
          pw.Divider(),
          pw.Text('Total de horas no mês (dias com entrada e saída): ${formatHours(monthTotal)}',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
          pw.Text(
            'Total de horas extras no mês: ${formatOvertime(overtimeTotal)} '
            '(${overtimeDays == 1 ? '1 dia' : '$overtimeDays dias'} com hora extra)',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ],
    ),
  );
  return doc.save();
}
