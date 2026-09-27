/// Модели данных клиента. Поля соответствуют схемам FastAPI (app/schemas.py).
import 'dart:convert';

int? _asInt(dynamic v) => v == null ? null : (v as num).toInt();
double? _asDouble(dynamic v) => v == null ? null : (v as num).toDouble();
DateTime? _asDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v as String);

class AppUser {
  AppUser(
      {required this.id, required this.phone, this.fullName, this.createdAt});
  final int id;
  final String phone;
  final String? fullName;
  final DateTime? createdAt;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        phone: j['phone'] as String,
        fullName: j['full_name'] as String?,
        createdAt: _asDate(j['created_at']),
      );
}

class Vehicle {
  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.plate,
    this.year,
    this.vin,
    this.color,
    this.insuranceCompany,
    this.policyNumber,
    this.policyValidUntil,
  });

  final int id;
  final String make;
  final String model;
  final String plate;
  final int? year;
  final String? vin;
  final String? color;
  final String? insuranceCompany;
  final String? policyNumber;
  final DateTime? policyValidUntil;

  String get title => '$make $model'.trim();

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as int,
        make: j['make'] as String,
        model: j['model'] as String,
        plate: j['plate'] as String,
        year: _asInt(j['year']),
        vin: j['vin'] as String?,
        color: j['color'] as String?,
        insuranceCompany: j['insurance_company'] as String?,
        policyNumber: j['policy_number'] as String?,
        policyValidUntil: _asDate(j['policy_valid_until']),
      );
}

/// Вопрос визарда права — бэкенд отдаёт список, клиент рендерит форму по нему.
class WizardQuestion {
  WizardQuestion(
      {required this.key,
      required this.type,
      required this.label,
      this.defaultValue});
  final String key;
  final String type; // bool | int
  final String label;
  final dynamic defaultValue;

  factory WizardQuestion.fromJson(Map<String, dynamic> j) => WizardQuestion(
        key: j['key'] as String,
        type: j['type'] as String,
        label: j['label'] as String,
        defaultValue: j['default'],
      );
}

class EligibilityReason {
  EligibilityReason(
      {required this.code, required this.message, required this.action});
  final String code;
  final String message;
  final String action;

  factory EligibilityReason.fromJson(Map<String, dynamic> j) =>
      EligibilityReason(
        code: j['code'] as String? ?? '',
        message: j['message'] as String? ?? '',
        action: j['action'] as String? ?? '',
      );
}

class EligibilityResult {
  EligibilityResult(
      {required this.result,
      required this.reasons,
      required this.rulesVersion});
  final String result; // green | red
  final List<EligibilityReason> reasons;
  final String rulesVersion;

  bool get isGreen => result == 'green';

  factory EligibilityResult.fromJson(Map<String, dynamic> j) =>
      EligibilityResult(
        result: j['result'] as String,
        reasons: ((j['reasons'] as List?) ?? [])
            .map((e) => EligibilityReason.fromJson(e as Map<String, dynamic>))
            .toList(),
        rulesVersion: j['rules_version'] as String? ?? '',
      );
}

class Participant {
  Participant({
    required this.id,
    required this.role,
    required this.acceptsFault,
    required this.confirmed,
    this.userId,
    this.vehicleId,
  });
  final int id;
  final String role; // A | B
  final bool acceptsFault;
  final bool confirmed;
  final int? userId;
  final int? vehicleId;

  factory Participant.fromJson(Map<String, dynamic> j) => Participant(
        id: j['id'] as int,
        role: j['role'] as String,
        acceptsFault: j['accepts_fault'] as bool? ?? false,
        confirmed: j['confirmed'] as bool? ?? false,
        userId: _asInt(j['user_id']),
        vehicleId: _asInt(j['vehicle_id']),
      );
}

class Evidence {
  Evidence({
    required this.id,
    required this.kind,
    required this.category,
    required this.filePath,
    required this.qualityStatus,
    this.sha256,
    this.qualityReason,
    this.capturedAt,
    this.createdAt,
  });
  final int id;
  final String kind; // photo | video | document
  final String category; // scene | damage | plate ...
  final String filePath;
  final String qualityStatus; // ok | rejected | pending
  final String? sha256;
  final String? qualityReason;
  final DateTime? capturedAt;
  final DateTime? createdAt;

  bool get isRejected => qualityStatus == 'rejected';

  factory Evidence.fromJson(Map<String, dynamic> j) => Evidence(
        id: j['id'] as int,
        kind: j['kind'] as String,
        category: j['category'] as String,
        filePath: j['file_path'] as String? ?? '',
        qualityStatus: j['quality_status'] as String? ?? 'pending',
        sha256: j['sha256'] as String?,
        qualityReason: j['quality_reason'] as String?,
        capturedAt: _asDate(j['captured_at']),
        createdAt: _asDate(j['created_at']),
      );
}

class AccidentCase {
  AccidentCase({
    required this.id,
    required this.creatorId,
    required this.status,
    required this.eligibility,
    required this.participants,
    required this.evidence,
    this.joinCode,
    this.occurredAt,
    this.locationLat,
    this.locationLng,
    this.address,
    this.sobrietyRequired = false,
    this.sobrietyStatus,
    this.diagram,
    this.createdAt,
  });

  final int id;
  final int creatorId;
  final String
      status; // draft|eligibility|capturing|review|ready|submitted|escalated|stopped
  final String eligibility; // pending|green|yellow|red
  final List<Participant> participants;
  final List<Evidence> evidence;
  final String? joinCode;
  final DateTime? occurredAt;
  final double? locationLat;
  final double? locationLng;
  final String? address;
  final bool sobrietyRequired;
  final String? sobrietyStatus;
  final Map<String, dynamic>? diagram;
  final DateTime? createdAt;

  bool get isGreen => eligibility == 'green';
  bool get isRed => eligibility == 'red';
  bool get hasSecondParty => participants.length >= 2;

  factory AccidentCase.fromJson(Map<String, dynamic> j) => AccidentCase(
        id: j['id'] as int,
        creatorId: j['creator_id'] as int,
        status: j['status'] as String,
        eligibility: j['eligibility'] as String? ?? 'pending',
        participants: ((j['participants'] as List?) ?? [])
            .map((e) => Participant.fromJson(e as Map<String, dynamic>))
            .toList(),
        evidence: ((j['evidence'] as List?) ?? [])
            .map((e) => Evidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        joinCode: j['join_code'] as String?,
        occurredAt: _asDate(j['occurred_at']),
        locationLat: _asDouble(j['location_lat']),
        locationLng: _asDouble(j['location_lng']),
        address: j['address'] as String?,
        sobrietyRequired: j['sobriety_required'] as bool? ?? false,
        sobrietyStatus: j['sobriety_status'] as String?,
        diagram: (j['diagram'] as Map?)?.cast<String, dynamic>(),
        createdAt: _asDate(j['created_at']),
      );

  /// Пакет для страховой возвращается как «сырой» JSON — сохраняем как есть для показа.
  static String pretty(Object? json) =>
      const JsonEncoder.withIndent('  ').convert(json);
}
