import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'time_record.dart';

/// Resultado de uma rodada de sincronização dos pontos salvos offline.
class SyncResult {
  final int synced; // enviados com sucesso
  final List<String> rejected; // recusados pelo servidor (descartados), com o motivo
  final int remaining; // ainda aguardando (sem conexão, por exemplo)

  const SyncResult({required this.synced, required this.rejected, required this.remaining});
}

class RecordsService {
  static const _pendingBase = 'pending_records_v2';
  static const _cacheBase = 'cached_records_v1';

  /// GET /records?from=...&to=... — datas locais, inclusive.
  Future<List<TimeRecord>> fetchRange(DateTime from, DateTime to) async {
    final data = await ApiClient.get('/records?from=${workDateOf(from)}&to=${workDateOf(to)}');
    try {
      return (data['records'] as List).map((e) => TimeRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      throw ApiException('Resposta inesperada do servidor.');
    }
  }

  /// POST /records. Sem [recordedAt], o servidor usa o relógio dele (ponto online).
  /// O [clientId] torna o envio seguro de repetir: o servidor não duplica.
  Future<TimeRecord> create({
    required PunchType type,
    required String workDate,
    required String clientId,
    DateTime? recordedAt,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationName,
  }) async {
    final data = await ApiClient.post('/records', {
      'type': type.wire,
      'workDate': workDate,
      'clientId': clientId,
      if (recordedAt != null) 'recordedAt': recordedAt.toUtc().toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (locationName != null) 'locationName': locationName,
    });
    try {
      return TimeRecord.fromJson(data['record'] as Map<String, dynamic>);
    } catch (_) {
      throw ApiException('Resposta inesperada do servidor.');
    }
  }

  /// PUT /records/:id — corrige o horário de um ponto.
  Future<TimeRecord> updateTime(int id, DateTime newTime) async {
    final data = await ApiClient.put('/records/$id', {'recordedAt': newTime.toUtc().toIso8601String()});
    try {
      return TimeRecord.fromJson(data['record'] as Map<String, dynamic>);
    } catch (_) {
      throw ApiException('Resposta inesperada do servidor.');
    }
  }

  // ---------------------------------------------------------------------------
  // Armazenamento local (cache + fila offline). As chaves levam o id do usuário
  // para que os pontos de uma conta nunca apareçam (nem sejam enviados) em outra.
  // ---------------------------------------------------------------------------

  Future<String> _key(String base) async {
    final user = await AuthService.getUser();
    return '$base:${user?['id'] ?? 'anon'}';
  }

  /// Guarda a última lista recebida do servidor, para a Home funcionar sem internet.
  Future<void> saveCache(List<TimeRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _key(_cacheBase), jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  Future<List<TimeRecord>> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _key(_cacheBase));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => TimeRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TimeRecord>> loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(await _key(_pendingBase)) ?? [];
    final list = <TimeRecord>[];
    for (final item in raw) {
      try {
        list.add(TimeRecord.fromJson(jsonDecode(item) as Map<String, dynamic>).copyWith(pending: true));
      } catch (_) {
        // item corrompido: ignora
      }
    }
    list.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return list;
  }

  Future<void> _savePending(List<TimeRecord> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(await _key(_pendingBase), list.map((r) => jsonEncode(r.toJson())).toList());
  }

  Future<void> addPending(TimeRecord record) async {
    final list = await loadPending();
    list.add(record);
    await _savePending(list);
  }

  /// Erros que valem tentar de novo mais tarde (o ponto continua guardado).
  bool _shouldRetryLater(ApiException e) {
    final code = e.statusCode;
    return code == null || code >= 500 || code == 401 || code == 408 || code == 429;
  }

  /// Envia os pontos salvos offline, do mais antigo para o mais novo.
  /// Para na primeira falha de conexão; o que o servidor recusar (ex: fora de
  /// ordem) é descartado e devolvido em [SyncResult.rejected] para avisar o usuário.
  Future<SyncResult> syncPending() async {
    final pending = await loadPending();
    final remaining = <TimeRecord>[];
    final rejected = <String>[];
    var synced = 0;

    for (var i = 0; i < pending.length; i++) {
      final p = pending[i];
      try {
        await create(
          type: p.type,
          workDate: p.workDate,
          clientId: p.clientId ?? '${p.type.wire}-${p.recordedAt.toUtc().toIso8601String()}',
          recordedAt: p.recordedAt,
          latitude: p.latitude,
          longitude: p.longitude,
          accuracy: p.accuracy,
          locationName: p.locationName,
        );
        synced++;
      } on ApiException catch (e) {
        if (_shouldRetryLater(e)) {
          remaining.addAll(pending.sublist(i));
          break;
        }
        rejected.add('${punchTypeInfo[p.type]?.label ?? 'Ponto'} das ${formatClock(p.recordedAt)}: ${e.message}');
      }
    }

    await _savePending(remaining);
    return SyncResult(synced: synced, rejected: rejected, remaining: remaining.length);
  }
}

/// Aviso interno: quando os pontos mudam em uma tela (ex: horário corrigido em
/// Registros), as outras telas que os mostram (Home) se atualizam.
class RecordsEvents {
  RecordsEvents._();

  static final ValueNotifier<int> changed = ValueNotifier<int>(0);

  static void notifyChanged() => changed.value++;
}
