import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'home.dart';
import 'profile.dart';

class RegistroPonto {
  final String label;
  final String horario;
  final Color cor;
  const RegistroPonto({required this.label, required this.horario, required this.cor});
}

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  // TODO: substituir por dados reais vindos do banco/API (GET /records).
  final Map<String, List<RegistroPonto>> _mockRegistros = {
    _keyFor(DateTime.now()): const [
      RegistroPonto(label: 'Entrada', horario: '08:00', cor: AppColors.statusGreen),
      RegistroPonto(label: 'Intervalo', horario: '12:00', cor: AppColors.statusOrange),
      RegistroPonto(label: 'Volta do Intervalo', horario: '13:00', cor: AppColors.statusBlue),
    ],
    _keyFor(DateTime.now().subtract(const Duration(days: 1))): const [
      RegistroPonto(label: 'Entrada', horario: '08:05', cor: AppColors.statusGreen),
      RegistroPonto(label: 'Intervalo', horario: '12:10', cor: AppColors.statusOrange),
      RegistroPonto(label: 'Volta do Intervalo', horario: '13:35', cor: AppColors.statusBlue),
      RegistroPonto(label: 'Fim do expediente', horario: '17:58', cor: AppColors.statusRed),
    ],
  };

  static String _keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  List<RegistroPonto> get _registrosDoDia => _mockRegistros[_keyFor(_selectedDate)] ?? [];
  bool _temRegistro(DateTime d) => _mockRegistros.containsKey(_keyFor(d));

  Future<void> _editarRegistro(RegistroPonto registro, int index) async {
    final partes = registro.horario.split(':');
    final horaInicial = TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
    final novaHora = await showTimePicker(context: context, initialTime: horaInicial);
    if (novaHora == null || !mounted) return;

    final horarioFormatado = '${novaHora.hour.toString().padLeft(2, '0')}:${novaHora.minute.toString().padLeft(2, '0')}';
    setState(() {
      final lista = List<RegistroPonto>.from(_registrosDoDia);
      lista[index] = RegistroPonto(label: registro.label, horario: horarioFormatado, cor: registro.cor);
      _mockRegistros[_keyFor(_selectedDate)] = lista;
    });
    // TODO: enviar a correção para PUT /records/:id na API real.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ponto atualizado.')));
    }
  }

  Future<void> _exportarMesEmPdf() async {
    final doc = pw.Document();
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    final tituloMes = '${meses[_focusedMonth.month - 1]} de ${_focusedMonth.year}';

    // Reúne os dias do mês focado que têm registro.
    final diasDoMes = <MapEntry<String, List<RegistroPonto>>>[];
    for (final entry in _mockRegistros.entries) {
      final data = DateTime.parse(entry.key);
      if (data.year == _focusedMonth.year && data.month == _focusedMonth.month) {
        diasDoMes.add(entry);
      }
    }
    diasDoMes.sort((a, b) => a.key.compareTo(b.key));

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('PontoClick — Registros de $tituloMes', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            for (final dia in diasDoMes) ...[
              pw.Text(dia.key, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              for (final r in dia.value) pw.Text('${r.label}: ${r.horario}', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 10),
            ],
            if (diasDoMes.isEmpty) pw.Text('Nenhum registro neste mês.', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  void _onNavTap(int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.pushReplacement(context, fadeRoute(const HomeScreen()));
    } else {
      Navigator.pushReplacement(context, fadeRoute(const ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registros', style: AppText.heading()),
              const SizedBox(height: 16),
              _buildCalendarCard(context),
              const SizedBox(height: 20),
              _buildRegistrosDoDia(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(activeIndex: 1, onTap: _onNavTap),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final today = DateTime.now();
    final isCurrentMonth = today.year == _focusedMonth.year && today.month == _focusedMonth.month;
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: context.textSecondary),
                onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
              ),
              Text('${meses[_focusedMonth.month - 1]} de ${_focusedMonth.year}',
                  style: AppText.body(weight: FontWeight.w600).copyWith(fontSize: 14)),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
                onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
              ),
            ],
          ),
          Align(alignment: Alignment.centerRight, child: AppOutlineButton(label: 'Exportar mês (PDF)', icon: Icons.ios_share_rounded, onPressed: _exportarMesEmPdf)),
          const SizedBox(height: 6),
          Row(
            children: ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']
                .map((d) => Expanded(child: Center(child: Text(d, style: AppText.caption(color: context.textTertiary, weight: FontWeight.w600)))))
                .toList(),
          ),
          const SizedBox(height: 6),
          Column(
            children: List.generate(((leadingEmpty + daysInMonth) / 7).ceil(), (row) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: List.generate(7, (col) {
                    final cellIndex = row * 7 + col;
                    if (cellIndex < leadingEmpty || cellIndex >= leadingEmpty + daysInMonth) {
                      return const Expanded(child: SizedBox(height: 34));
                    }
                    final day = cellIndex - leadingEmpty + 1;
                    final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                    final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
                    final isToday = isCurrentMonth && day == today.day;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: Container(
                          height: 34,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.twilightViolet : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isToday && !isSelected ? Border.all(color: AppColors.twilightViolet, width: 1) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$day',
                                  style: AppText.caption(
                                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                      weight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400)),
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _temRegistro(date) ? (isSelected ? Colors.white : context.textTertiary) : Colors.transparent),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrosDoDia(BuildContext context) {
    final registros = _registrosDoDia;
    const dias = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
    final dataFormatada = '${dias[_selectedDate.weekday - 1]}, ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dataFormatada, style: AppText.body(weight: FontWeight.w600).copyWith(fontSize: 14)),
          Divider(height: 24, color: Theme.of(context).dividerColor),
          if (registros.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded, color: context.textTertiary, size: 30),
                    const SizedBox(height: 8),
                    Text('Nenhum ponto registrado nesse dia', style: AppText.caption(color: context.textTertiary)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(registros.length, (i) {
              final r = registros[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: r.cor)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r.label, style: AppText.body(color: context.textSecondary).copyWith(fontSize: 14))),
                    Text(r.horario, style: AppText.body(weight: FontWeight.w600).copyWith(fontSize: 14)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _editarRegistro(r, i),
                      child: Icon(Icons.edit_outlined, size: 16, color: context.textTertiary),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}