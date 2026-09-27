import 'package:geolocator/geolocator.dart';

/// Координаты + необязательная ошибка (для мягкого показа пользователю).
class GpsFix {
  const GpsFix({this.lat, this.lng, this.error});
  final double? lat;
  final double? lng;
  final String? error;

  bool get ok => lat != null && lng != null;
}

/// Best-effort определение координат. Никогда не бросает — при отказе
/// возвращает GpsFix с текстом ошибки, чтобы сценарий продолжился без GPS.
Future<GpsFix> tryGetLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const GpsFix(error: 'Геолокация выключена в системе');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return const GpsFix(error: 'Нет доступа к геолокации');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return GpsFix(lat: pos.latitude, lng: pos.longitude);
  } catch (e) {
    return GpsFix(error: 'Не удалось получить координаты: $e');
  }
}
