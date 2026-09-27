import '../core/api_client.dart';
import '../models.dart';

/// Дело об аварии: право (Европротокол), присоединение 2-го участника,
/// схема, подтверждения, пакет для страховой.
class CaseService {
  CaseService(this._api);
  final ApiClient _api;

  Future<List<WizardQuestion>> eligibilityQuestions() async {
    final data = await _api.get('/api/cases/eligibility-questions')
        as Map<String, dynamic>;
    return (data['questions'] as List)
        .map((e) => WizardQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AccidentCase>> list() async {
    final data = await _api.get('/api/cases') as List;
    return data
        .map((e) => AccidentCase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AccidentCase> get(int id) async {
    final data = await _api.get('/api/cases/$id') as Map<String, dynamic>;
    return AccidentCase.fromJson(data);
  }

  Future<AccidentCase> create(
      {int? vehicleId, String? address, double? lat, double? lng}) async {
    final data = await _api.post('/api/cases', body: {
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (address != null && address.isNotEmpty) 'address': address,
      if (lat != null) 'location_lat': lat,
      if (lng != null) 'location_lng': lng,
    }) as Map<String, dynamic>;
    return AccidentCase.fromJson(data);
  }

  Future<EligibilityResult> submitEligibility(
      int caseId, Map<String, dynamic> answers) async {
    final data = await _api.post('/api/cases/$caseId/eligibility',
        body: {'answers': answers}) as Map<String, dynamic>;
    return EligibilityResult.fromJson(data);
  }

  Future<AccidentCase> join({required String joinCode, int? vehicleId}) async {
    final data = await _api.post('/api/cases/join', body: {
      'join_code': joinCode,
      if (vehicleId != null) 'vehicle_id': vehicleId,
    }) as Map<String, dynamic>;
    return AccidentCase.fromJson(data);
  }

  Future<AccidentCase> updateDiagram(
      int caseId, Map<String, dynamic> diagram) async {
    final data =
        await _api.put('/api/cases/$caseId/diagram', body: {'diagram': diagram})
            as Map<String, dynamic>;
    return AccidentCase.fromJson(data);
  }

  Future<AccidentCase> confirm(int caseId, {bool? acceptsFault}) async {
    final data = await _api.post('/api/cases/$caseId/confirm',
            body: {if (acceptsFault != null) 'accepts_fault': acceptsFault})
        as Map<String, dynamic>;
    return AccidentCase.fromJson(data);
  }

  /// Пакет для страховой — «сырой» JSON (структура сборки на бэкенде).
  Future<Map<String, dynamic>> claimPackage(int caseId) async {
    final data = await _api.post('/api/cases/$caseId/claim-package')
        as Map<String, dynamic>;
    return data;
  }
}
