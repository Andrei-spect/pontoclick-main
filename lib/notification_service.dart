import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'api_client.dart';
import 'auth_service.dart';

/// Os 4 lembretes, na ordem do dia. As chaves são as mesmas da API.
const reminderKeys = ['entrada', 'intervalo', 'volta', 'saida'];

const reminderLabels = {
  'entrada': 'Entrada',
  'intervalo': 'Início do intervalo',
  'volta': 'Volta do intervalo',
  'saida': 'Saída',
};

class ReminderItem {
  final bool enabled;
  final String time; // "HH:MM", horário local do aparelho

  const ReminderItem({required this.enabled, required this.time});

  TimeOfDay get timeOfDay {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  ReminderItem copyWith({bool? enabled, String? time}) =>
      ReminderItem(enabled: enabled ?? this.enabled, time: time ?? this.time);

  Map<String, dynamic> toJson() => {'enabled': enabled, 'time': time};

  factory ReminderItem.fromJson(Map<String, dynamic> json) =>
      ReminderItem(enabled: json['enabled'] == true, time: json['time'] as String? ?? '08:00');

  @override
  bool operator ==(Object other) => other is ReminderItem && other.enabled == enabled && other.time == time;

  @override
  int get hashCode => Object.hash(enabled, time);
}

/// Preferências dos lembretes de bater o ponto (GET/PUT /users/me/notifications).
class ReminderSettings {
  final bool enabled;
  final List<int> days; // 1 = segunda ... 7 = domingo (igual a DateTime.weekday)
  final Map<String, ReminderItem> reminders;

  const ReminderSettings({required this.enabled, required this.days, required this.reminders});

  static const defaults = ReminderSettings(
    enabled: true,
    days: [1, 2, 3, 4, 5],
    reminders: {
      'entrada': ReminderItem(enabled: true, time: '08:00'),
      'intervalo': ReminderItem(enabled: true, time: '12:00'),
      'volta': ReminderItem(enabled: true, time: '13:00'),
      'saida': ReminderItem(enabled: true, time: '17:00'),
    },
  );

  ReminderSettings copyWith({bool? enabled, List<int>? days, Map<String, ReminderItem>? reminders}) => ReminderSettings(
        enabled: enabled ?? this.enabled,
        days: days ?? this.days,
        reminders: reminders ?? this.reminders,
      );

  ReminderSettings withReminder(String key, ReminderItem item) => copyWith(reminders: {...reminders, key: item});

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'days': days,
        'reminders': {for (final k in reminderKeys) k: reminders[k]!.toJson()},
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    final raw = (json['reminders'] as Map?)?.cast<String, dynamic>() ?? {};
    return ReminderSettings(
      enabled: json['enabled'] != false,
      days: ((json['days'] as List?) ?? defaults.days).map((d) => (d as num).toInt()).toList()..sort(),
      reminders: {
        for (final k in reminderKeys)
          k: raw[k] is Map ? ReminderItem.fromJson((raw[k] as Map).cast<String, dynamic>()) : defaults.reminders[k]!,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      listEquals(other.days, days) &&
      mapEquals(other.reminders, reminders);

  @override
  int get hashCode => Object.hash(enabled, Object.hashAll(days), Object.hashAll(reminders.values));
}

/// Um lembrete que será agendado no aparelho.
class PlannedReminder {
  final int id;
  final String key;
  final DateTime when;
  const PlannedReminder({required this.id, required this.key, required this.when});
}

/// Calcula os lembretes dos próximos [days] dias a partir de [now].
///
/// - Só nos dias da semana escolhidos e só horários ainda no futuro.
/// - Hoje, pula os pontos que já foram batidos ([doneToday], chaves da API).
/// - Turno da noite: se a saída é mais cedo que a entrada (ex: 22:00 → 06:00),
///   o lembrete da saída cai no dia seguinte ao da entrada.
List<PlannedReminder> plannedReminders(ReminderSettings settings, DateTime now, Set<String> doneToday, {int days = 14}) {
  if (!settings.enabled) return const [];
  final result = <PlannedReminder>[];
  final entrada = settings.reminders['entrada']!;

  for (var d = 0; d < days; d++) {
    final date = DateTime(now.year, now.month, now.day + d);
    if (!settings.days.contains(date.weekday)) continue;

    for (var i = 0; i < reminderKeys.length; i++) {
      final key = reminderKeys[i];
      final item = settings.reminders[key]!;
      if (!item.enabled) continue;
      if (d == 0 && doneToday.contains(key)) continue;

      final t = item.timeOfDay;
      var when = DateTime(date.year, date.month, date.day, t.hour, t.minute);
      final overnight = key != 'entrada' && entrada.enabled && item.time.compareTo(entrada.time) < 0;
      if (overnight) when = when.add(const Duration(days: 1));
      if (!when.isAfter(now)) continue;

      result.add(PlannedReminder(id: d * 10 + i, key: key, when: when));
    }
  }
  return result;
}

/// Lembretes locais (agendados no próprio aparelho, sem servidor de push).
/// Funcionam no Android e no iPhone; nas outras plataformas só as preferências são salvas.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Pontos do turno atual já batidos (a Home informa), para não lembrar à toa.
  static Set<String> doneToday = {};

  static bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Chamado uma vez no main(). Não faz nada nas plataformas sem suporte.
  static Future<void> init() async {
    if (!isSupported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Fuso desconhecido: segue com UTC (os horários podem sair deslocados).
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // A permissão é pedida depois, na hora certa (requestPermission).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Pede ao sistema permissão para mostrar notificações (Android 13+ e iPhone).
  static Future<bool> requestPermission() async {
    if (!isSupported || !_ready) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'lembretes_ponto',
      'Lembretes de ponto',
      channelDescription: 'Avisos para bater o ponto nos horários da sua jornada',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static (String, String) _texts(String key, String time) => switch (key) {
        'entrada' => ('Hora de bater a entrada', 'Seu expediente começa às $time. Toque para registrar o ponto.'),
        'intervalo' => ('Hora do intervalo', 'Registre o início do intervalo ($time).'),
        'volta' => ('Fim do intervalo', 'Registre a volta do intervalo ($time).'),
        _ => ('Hora de bater a saída', 'Seu expediente termina às $time. Não esqueça de registrar a saída.'),
      };

  /// Refaz todos os agendamentos a partir das preferências atuais.
  static Future<void> reschedule([ReminderSettings? settings]) async {
    if (!isSupported || !_ready) return;
    final current = settings ?? ReminderStore.settings.value;
    try {
      await _plugin.cancelAll();
      for (final r in plannedReminders(current, DateTime.now(), doneToday)) {
        final (title, body) = _texts(r.key, current.reminders[r.key]!.time);
        await _plugin.zonedSchedule(
          id: r.id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(r.when, tz.local),
          notificationDetails: _details,
          // Horário aproximado (pode atrasar alguns minutos para economizar bateria);
          // não precisa da permissão especial de "alarmes exatos".
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Não foi possível agendar os lembretes: $e');
    }
  }

  /// Remove todos os lembretes (ex: ao sair da conta).
  static Future<void> cancelAll() async {
    if (!isSupported || !_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

/// Preferências do usuário logado: cópia no aparelho + API.
class ReminderStore {
  ReminderStore._();

  static const _cacheBase = 'notification_settings_v1';
  static final ValueNotifier<ReminderSettings> settings = ValueNotifier(ReminderSettings.defaults);

  static Future<String> _cacheKey() async {
    final user = await AuthService.getUser();
    return '$_cacheBase:${user?['id'] ?? 'anon'}';
  }

  static Future<void> _saveCache(ReminderSettings value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _cacheKey(), jsonEncode(value.toJson()));
  }

  /// Mostra na hora a cópia salva e atualiza com a API (sem internet, fica com a cópia).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _cacheKey());
    ReminderSettings value = ReminderSettings.defaults;
    if (raw != null) {
      try {
        value = ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    settings.value = value;
    try {
      final data = await ApiClient.get('/users/me/notifications');
      settings.value = ReminderSettings.fromJson(data['settings'] as Map<String, dynamic>);
      await _saveCache(settings.value);
    } on ApiException catch (_) {
      // Sem conexão: segue com a cópia salva.
    }
  }

  /// PUT /users/me/notifications — salva e reagenda os lembretes.
  static Future<void> save(ReminderSettings value) async {
    final data = await ApiClient.put('/users/me/notifications', value.toJson());
    settings.value = ReminderSettings.fromJson(data['settings'] as Map<String, dynamic>);
    await _saveCache(settings.value);
    await NotificationService.reschedule(settings.value);
  }
}
