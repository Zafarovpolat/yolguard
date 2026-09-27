import 'dart:io';

import '../core/api_client.dart';
import '../models.dart';

/// Доказательства: загрузка фото/видео/документов и список по делу.
class EvidenceService {
  EvidenceService(this._api);
  final ApiClient _api;

  Future<List<Evidence>> list(int caseId) async {
    final data = await _api.get('/api/cases/$caseId/evidence') as List;
    return data
        .map((e) => Evidence.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Evidence> upload(
    int caseId, {
    required File file,
    required String category,
    String kind = 'photo',
    double? gpsLat,
    double? gpsLng,
  }) async {
    final data = await _api.uploadFile(
      '/api/cases/$caseId/evidence',
      file: file,
      fields: {
        'category': category,
        'kind': kind,
        if (gpsLat != null) 'gps_lat': gpsLat.toString(),
        if (gpsLng != null) 'gps_lng': gpsLng.toString(),
      },
    ) as Map<String, dynamic>;
    return Evidence.fromJson(data);
  }
}
