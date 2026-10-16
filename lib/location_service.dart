import 'package:geolocator/geolocator.dart';

/// Um local pré-cadastrado (ex: escritório, casa) usado para identificar
/// automaticamente onde o usuário está.
class KnownLocation {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const KnownLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 150,
  });
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
  final KnownLocation? matchedLocation;

  const LocationResult({
    required this.status,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.matchedLocation,
  });

  bool get isOk => status == LocationStatus.ok;
}

class LocationService {
  // TODO: substituir por locais cadastrados de verdade pelo usuário/empresa
  // (viria do backend, numa tela de "Locais de Trabalho" futura).
  static const List<KnownLocation> knownLocations = [
    KnownLocation(name: 'Escritório Central', latitude: -23.5505, longitude: -46.6333),
    KnownLocation(name: 'Home Office', latitude: -23.5629, longitude: -46.6544),
  ];

  /// Busca a posição atual do GPS e confere se bate com algum local
  /// conhecido. Trata os casos de GPS desligado e permissão negada.
  Future<LocationResult> getCurrentLocation() async {
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

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final match = _findKnownLocation(position.latitude, position.longitude);

      return LocationResult(
        status: LocationStatus.ok,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        matchedLocation: match,
      );
    } catch (_) {
      return const LocationResult(status: LocationStatus.error);
    }
  }

  KnownLocation? _findKnownLocation(double lat, double lng) {
    for (final loc in knownLocations) {
      final distance = Geolocator.distanceBetween(lat, lng, loc.latitude, loc.longitude);
      if (distance <= loc.radiusMeters) return loc;
    }
    return null;
  }
}
