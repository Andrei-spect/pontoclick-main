import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Ordem dos pontos em um dia normal de trabalho.
enum PunchType { entrada, intervaloInicio, intervaloFim, saida, completo }

class PunchTypeInfo {
  final String label; // rótulo exibido na timeline
  final String actionLabel; // texto do botão para BATER esse ponto
  final Color color; // marcador na timeline / calendário
  final Color buttonColor; // fundo do botão (tom mais fechado, legível com texto branco)

  const PunchTypeInfo({required this.label, required this.actionLabel, required this.color, required this.buttonColor});
}

const Map<PunchType, PunchTypeInfo> punchTypeInfo = {
  PunchType.entrada: PunchTypeInfo(
      label: 'Entrada',
      actionLabel: 'Bater ponto · Entrada',
      color: AppColors.statusGreen,
      buttonColor: AppColors.statusGreenStrong),
  PunchType.intervaloInicio: PunchTypeInfo(
      label: 'Início intervalo',
      actionLabel: 'Bater ponto · Início do intervalo',
      color: AppColors.statusOrange,
      buttonColor: AppColors.statusOrangeStrong),
  PunchType.intervaloFim: PunchTypeInfo(
      label: 'Fim intervalo',
      actionLabel: 'Bater ponto · Retorno',
      color: AppColors.statusBlue,
      buttonColor: AppColors.statusBlueStrong),
  PunchType.saida: PunchTypeInfo(
      label: 'Saída', actionLabel: 'Bater ponto · Saída', color: AppColors.statusRed, buttonColor: AppColors.statusRedStrong),
};

extension PunchTypeWire on PunchType {
  /// Nome do tipo como a API usa.
  String get wire {
    switch (this) {
      case PunchType.entrada:
        return 'entrada';
      case PunchType.intervaloInicio:
        return 'intervalo';
      case PunchType.intervaloFim:
        return 'volta_intervalo';
      case PunchType.saida:
        return 'saida';
      case PunchType.completo:
        return 'completo';
    }
  }
}

PunchType? punchTypeFromWire(String? value) {
  for (final type in PunchType.values) {
    if (type != PunchType.completo && type.wire == value) return type;
  }
  return null;
}

/// Data local no formato da API: "2026-10-25".
String workDateOf(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

String two(int n) => n.toString().padLeft(2, '0');

/// "08:05"
String formatClock(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

/// "6h 32m"
String formatHours(Duration d) => '${d.inHours}h ${two(d.inMinutes.remainder(60))}m';

/// Um ponto batido. Pode já estar no servidor ([id] preenchido) ou ainda só
/// no aparelho, esperando internet ([pending] = true).
class TimeRecord {
  final int? id;
  final PunchType type;
  final DateTime recordedAt; // horário local
  final String workDate;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? locationName;
  final bool edited;
  final DateTime? originalRecordedAt;
  final String? clientId;
  final bool pending;

  const TimeRecord({
    this.id,
    required this.type,
    required this.recordedAt,
    required this.workDate,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.locationName,
    this.edited = false,
    this.originalRecordedAt,
    this.clientId,
    this.pending = false,
  });

  /// Lê o formato da API (também usado no cache local e na fila offline).
  factory TimeRecord.fromJson(Map<String, dynamic> json) {
    final type = punchTypeFromWire(json['type'] as String?);
    if (type == null) throw const FormatException('Tipo de ponto desconhecido');
    final recordedAt = DateTime.parse(json['recordedAt'] as String).toLocal();
    final original = json['originalRecordedAt'] as String?;
    return TimeRecord(
      id: (json['id'] as num?)?.toInt(),
      type: type,
      recordedAt: recordedAt,
      workDate: json['workDate'] as String? ?? workDateOf(recordedAt),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      locationName: json['locationName'] as String?,
      edited: json['edited'] == true,
      originalRecordedAt: original == null ? null : DateTime.parse(original).toLocal(),
      clientId: json['clientId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.wire,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'workDate': workDate,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'locationName': locationName,
        'edited': edited,
        'originalRecordedAt': originalRecordedAt?.toUtc().toIso8601String(),
        'clientId': clientId,
      };

  TimeRecord copyWith({bool? pending}) => TimeRecord(
        id: id,
        type: type,
        recordedAt: recordedAt,
        workDate: workDate,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        locationName: locationName,
        edited: edited,
        originalRecordedAt: originalRecordedAt,
        clientId: clientId,
        pending: pending ?? this.pending,
      );
}

/// Tempo trabalhado em um dia = (saída - entrada) - intervalo.
///
/// Dia de hoje, ainda em andamento: passe [now] e o cálculo usa a hora atual
/// no lugar da saída que ainda não existe. Dia antigo sem saída: devolve zero
/// (não dá para saber quanto foi trabalhado).
Duration workedDuration(List<TimeRecord> dayRecords, {DateTime? now}) {
  TimeRecord? find(PunchType type) {
    for (final r in dayRecords) {
      if (r.type == type) return r;
    }
    return null;
  }

  final entrada = find(PunchType.entrada);
  if (entrada == null) return Duration.zero;

  final end = find(PunchType.saida)?.recordedAt ?? now;
  if (end == null) return Duration.zero;

  var worked = end.difference(entrada.recordedAt);

  final breakStart = find(PunchType.intervaloInicio);
  if (breakStart != null) {
    final breakEnd = find(PunchType.intervaloFim)?.recordedAt ?? end;
    worked -= breakEnd.difference(breakStart.recordedAt);
  }
  return worked.isNegative ? Duration.zero : worked;
}
