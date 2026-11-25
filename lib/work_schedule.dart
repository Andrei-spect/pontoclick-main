import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Entrada, saída e intervalo de um tipo de dia (segunda a sexta, ou fim de semana).
class ShiftHours {
  final String entrada; // "HH:MM", horário local
  final String saida; // mais cedo que a entrada = turno da noite (termina no dia seguinte)
  final int intervaloMin;

  const ShiftHours({required this.entrada, required this.saida, required this.intervaloMin});

  static int _minutes(String hhmm) => int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3, 5));

  static TimeOfDay toTimeOfDay(String hhmm) =>
      TimeOfDay(hour: int.parse(hhmm.substring(0, 2)), minute: int.parse(hhmm.substring(3, 5)));

  /// Da entrada até a saída, contando a virada da meia-noite.
  Duration get span {
    var diff = _minutes(saida) - _minutes(entrada);
    if (diff <= 0) diff += 24 * 60;
    return Duration(minutes: diff);
  }

  bool get isOvernight => _minutes(saida) <= _minutes(entrada);

  /// Tempo de trabalho esperado no dia: jornada menos o intervalo.
  Duration get workDuration {
    final d = span - Duration(minutes: intervaloMin);
    return d.isNegative ? Duration.zero : d;
  }

  /// Mesmas regras da API (PUT /users/me/schedule). Devolve a mensagem de erro ou null.
  String? validate(String label) {
    if (entrada == saida) return 'A entrada e a saída $label não podem ser iguais.';
    if (span > const Duration(hours: 16)) return 'A jornada $label pode ter no máximo 16 horas.';
    if (Duration(minutes: intervaloMin) >= span) return 'O intervalo $label precisa ser menor que a jornada.';
    return null;
  }

  ShiftHours copyWith({String? entrada, String? saida, int? intervaloMin}) => ShiftHours(
        entrada: entrada ?? this.entrada,
        saida: saida ?? this.saida,
        intervaloMin: intervaloMin ?? this.intervaloMin,
      );

  Map<String, dynamic> toJson() => {'entrada': entrada, 'saida': saida, 'intervaloMin': intervaloMin};

  factory ShiftHours.fromJson(Map<String, dynamic> json, ShiftHours fallback) => ShiftHours(
        entrada: json['entrada'] as String? ?? fallback.entrada,
        saida: json['saida'] as String? ?? fallback.saida,
        intervaloMin: (json['intervaloMin'] as num?)?.toInt() ?? fallback.intervaloMin,
      );

  @override
  bool operator ==(Object other) =>
      other is ShiftHours && other.entrada == entrada && other.saida == saida && other.intervaloMin == intervaloMin;

  @override
  int get hashCode => Object.hash(entrada, saida, intervaloMin);
}

/// Horário de trabalho do usuário (GET/PUT /users/me/schedule).
/// Define a meta de cada dia e, com ela, as horas extras.
class WorkSchedule {
  final ShiftHours weekdays;
  final ShiftHours weekend;
  final bool saturday; // trabalha no sábado
  final bool sunday; // trabalha no domingo

  const WorkSchedule({required this.weekdays, required this.weekend, required this.saturday, required this.sunday});

  /// Igual ao padrão da API: seg–sex 08:00–17:00 com 1 h de intervalo (8 h),
  /// sábado 08:00–12:00 (4 h), domingo de folga.
  static const defaults = WorkSchedule(
    weekdays: ShiftHours(entrada: '08:00', saida: '17:00', intervaloMin: 60),
    weekend: ShiftHours(entrada: '08:00', saida: '12:00', intervaloMin: 0),
    saturday: true,
    sunday: false,
  );

  bool get worksWeekend => saturday || sunday;

  /// Horário do dia, ou null quando é folga.
  ShiftHours? shiftFor(DateTime day) => switch (day.weekday) {
        DateTime.saturday => saturday ? weekend : null,
        DateTime.sunday => sunday ? weekend : null,
        _ => weekdays,
      };

  /// Meta de trabalho do dia. Na folga é zero: tudo o que for trabalhado conta como extra.
  Duration goalFor(DateTime day) => shiftFor(day)?.workDuration ?? Duration.zero;

  /// Igual a [goalFor], a partir do work_date da API ("2026-11-14"). O turno da noite
  /// segue o dia em que começou (work_date), não o dia em que termina.
  Duration goalForWorkDate(String workDate) => goalFor(DateTime.parse(workDate));

  WorkSchedule copyWith({ShiftHours? weekdays, ShiftHours? weekend, bool? saturday, bool? sunday}) => WorkSchedule(
        weekdays: weekdays ?? this.weekdays,
        weekend: weekend ?? this.weekend,
        saturday: saturday ?? this.saturday,
        sunday: sunday ?? this.sunday,
      );

  Map<String, dynamic> toJson() =>
      {'weekdays': weekdays.toJson(), 'weekend': weekend.toJson(), 'saturday': saturday, 'sunday': sunday};

  factory WorkSchedule.fromJson(Map<String, dynamic> json) => WorkSchedule(
        weekdays: json['weekdays'] is Map
            ? ShiftHours.fromJson((json['weekdays'] as Map).cast<String, dynamic>(), defaults.weekdays)
            : defaults.weekdays,
        weekend: json['weekend'] is Map
            ? ShiftHours.fromJson((json['weekend'] as Map).cast<String, dynamic>(), defaults.weekend)
            : defaults.weekend,
        saturday: json['saturday'] is bool ? json['saturday'] as bool : defaults.saturday,
        sunday: json['sunday'] is bool ? json['sunday'] as bool : defaults.sunday,
      );

  @override
  bool operator ==(Object other) =>
      other is WorkSchedule &&
      other.weekdays == weekdays &&
      other.weekend == weekend &&
      other.saturday == saturday &&
      other.sunday == sunday;

  @override
  int get hashCode => Object.hash(weekdays, weekend, saturday, sunday);
}

/// Horário do usuário logado: cópia no aparelho + API.
class ScheduleStore {
  ScheduleStore._();

  static const _cacheBase = 'work_schedule_v1';
  static final ValueNotifier<WorkSchedule> schedule = ValueNotifier(WorkSchedule.defaults);

  static Future<String> _cacheKey() async {
    final user = await AuthService.getUser();
    return '$_cacheBase:${user?['id'] ?? 'anon'}';
  }

  static Future<void> _saveCache(WorkSchedule value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _cacheKey(), jsonEncode(value.toJson()));
  }

  /// Mostra na hora a cópia salva e atualiza com a API (sem internet, fica com a cópia).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _cacheKey());
    var value = WorkSchedule.defaults;
    if (raw != null) {
      try {
        value = WorkSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    schedule.value = value;
    try {
      final data = await ApiClient.get('/users/me/schedule');
      schedule.value = WorkSchedule.fromJson(data['schedule'] as Map<String, dynamic>);
      await _saveCache(schedule.value);
    } on ApiException catch (_) {
      // Sem conexão: segue com a cópia salva.
    }
  }

  /// PUT /users/me/schedule.
  static Future<void> save(WorkSchedule value) async {
    final data = await ApiClient.put('/users/me/schedule', value.toJson());
    schedule.value = WorkSchedule.fromJson(data['schedule'] as Map<String, dynamic>);
    await _saveCache(schedule.value);
  }
}
