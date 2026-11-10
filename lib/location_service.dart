import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Um local de trabalho cadastrado pelo usuário (ex: escritório, loja, casa),
/// usado para identificar automaticamente onde ele está ao bater o ponto.
class KnownLocation {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const KnownLocation({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 150,
  });

  factory KnownLocation.fromJson(Map<String, dynamic> json) => KnownLocation(
        id: (json['id'] as num?)?.toInt(),
        name: json['name'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 150,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters.round(),
      };

  /// Distância em metros até um ponto.
  double distanceTo(double lat, double lng) => Geolocator.distanceBetween(lat, lng, latitude, longitude);
}

/// Locais de trabalho do usuário logado (API `/locations` + cópia no aparelho
/// para funcionar sem internet). As telas escutam [items] e se atualizam sozinhas.
class WorkLocations {
  WorkLocations._();

  static const _cacheBase = 'work_locations_v1';

  static final ValueNotifier<List<KnownLocation>> items = ValueNotifier<List<KnownLocation>>(const []);

  /// Local cadastrado mais próximo que contém o ponto (dentro do raio), ou null.
  static KnownLocation? match(double lat, double lng) {
    KnownLocation? best;
    double bestDistance = double.infinity;
    for (final loc in items.value) {
      final distance = loc.distanceTo(lat, lng);
      if (distance <= loc.radiusMeters && distance < bestDistance) {
        best = loc;
        bestDistance = distance;
      }
    }
    return best;
  }

  static Future<String> _cacheKey() async {
    final user = await AuthService.getUser();
    return '$_cacheBase:${user?['id'] ?? 'anon'}';
  }

  static Future<void> _saveCache(List<KnownLocation> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _cacheKey(), jsonEncode(list.map((l) => l.toJson()).toList()));
  }

  static void _set(List<KnownLocation> list) {
    final sorted = [...list]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    items.value = List.unmodifiable(sorted);
  }

  /// Mostra na hora o que está salvo no aparelho e atualiza com a API.
  /// Sem internet, fica com a cópia salva (não lança erro).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _cacheKey());
    if (raw != null) {
      try {
        _set((jsonDecode(raw) as List).map((e) => KnownLocation.fromJson(e as Map<String, dynamic>)).toList());
      } catch (_) {
        _set(const []);
      }
    } else {
      _set(const []); // outro usuário: não mostra os locais de quem saiu
    }
    try {
      await refresh();
    } on ApiException catch (_) {
      // Sem conexão ou sessão expirada: segue com a cópia salva.
    }
  }

  /// GET /locations
  static Future<void> refresh() async {
    final data = await ApiClient.get('/locations');
    final list = (data['locations'] as List).map((e) => KnownLocation.fromJson(e as Map<String, dynamic>)).toList();
    _set(list);
    await _saveCache(items.value);
  }

  /// POST /locations
  static Future<KnownLocation> create({
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    final data = await ApiClient.post('/locations', {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    });
    final created = KnownLocation.fromJson(data['location'] as Map<String, dynamic>);
    _set([...items.value, created]);
    await _saveCache(items.value);
    return created;
  }

  /// PUT /locations/:id — envia só o que mudou (posição nula = mantém a atual).
  static Future<KnownLocation> update(
    int id, {
    required String name,
    required int radiusMeters,
    double? latitude,
    double? longitude,
  }) async {
    final data = await ApiClient.put('/locations/$id', {
      'name': name,
      'radiusMeters': radiusMeters,
      'latitude': ?latitude,
      'longitude': ?longitude,
    });
    final updated = KnownLocation.fromJson(data['location'] as Map<String, dynamic>);
    _set([for (final l in items.value) l.id == id ? updated : l]);
    await _saveCache(items.value);
    return updated;
  }

  /// DELETE /locations/:id — os pontos já registrados mantêm o nome do local.
  static Future<void> remove(int id) async {
    await ApiClient.delete('/locations/$id');
    _set(items.value.where((l) => l.id != id).toList());
    await _saveCache(items.value);
  }
}

enum LocationStatus {
  ok,
  serviceDisabled, // GPS desligado no aparelho
  permissionDenied, // usuário negou a permissão
  permissionDeniedForever,
  error,
}

class LocationResult {
  final LocationStatus status;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;

  const LocationResult({
    required this.status,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
  });

  bool get isOk => status == LocationStatus.ok;

  /// Local cadastrado onde o usuário está. Calculado na hora (e não guardado),
  /// então reflete na mesma hora um local que acabou de ser cadastrado.
  KnownLocation? get matchedLocation =>
      isOk && latitude != null && longitude != null ? WorkLocations.match(latitude!, longitude!) : null;
}

class LocationService {
  /// Busca a posição atual do GPS. Trata os casos de GPS desligado e permissão negada.
  /// O local de trabalho correspondente vem de [LocationResult.matchedLocation].
  Future<LocationResult> getCurrentLocation() async {
    // Tudo dentro do try: se o plugin falhar (ex: permissão não declarada no
    // AndroidManifest/Info.plist), a Home mostra o erro em vez de ficar
    // presa em "Buscando localização...".
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(status: LocationStatus.serviceDisabled);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(status: LocationStatus.permissionDenied);
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(status: LocationStatus.permissionDeniedForever);
      }

      final position = await Geolocator.getCurrentPosition(
        // Sem sinal de GPS (ex: ambiente fechado), desiste em 20 s em vez de esperar para sempre.
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );

      return LocationResult(
        status: LocationStatus.ok,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    } catch (_) {
      return const LocationResult(status: LocationStatus.error);
    }
  }
}
