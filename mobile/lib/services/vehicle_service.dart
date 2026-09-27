import '../core/api_client.dart';
import '../models.dart';

/// Профиль «Моя машина» (CRUD).
class VehicleService {
  VehicleService(this._api);
  final ApiClient _api;

  Future<List<Vehicle>> list() async {
    final data = await _api.get('/api/vehicles') as List;
    return data
        .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> create(Map<String, dynamic> body) async {
    final data =
        await _api.post('/api/vehicles', body: body) as Map<String, dynamic>;
    return Vehicle.fromJson(data);
  }

  Future<Vehicle> update(int id, Map<String, dynamic> body) async {
    final data = await _api.patch('/api/vehicles/$id', body: body)
        as Map<String, dynamic>;
    return Vehicle.fromJson(data);
  }

  Future<void> delete(int id) => _api.delete('/api/vehicles/$id');
}
