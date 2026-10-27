class ConsultationRequest {
  final String patientName;
  final int age;
  final String gender;
  final num? weight;
  final bool hasDiabetes;
  final bool hasHypertension;
  final bool hasHeartDisease;
  final bool hasAsthma;
  final bool hasKidneyDisease;
  final bool hasCancer;
  final bool hasStroke;
  final bool hasAllergy;
  final bool hasLiverCirrhosis;
  final bool hasTb;
  final bool hasThyroidProblem;
  final bool isSmoker;
  final bool isAlcoholic;
  final List<String> symptoms;
  final String symptomDescription;
  final int durationDays;

  ConsultationRequest({
    required this.patientName,
    required this.age,
    required this.gender,
    this.weight,
    required this.hasDiabetes,
    required this.hasHypertension,
    required this.hasHeartDisease,
    required this.hasAsthma,
    required this.hasKidneyDisease,
    required this.hasCancer,
    required this.hasStroke,
    required this.hasAllergy,
    required this.hasLiverCirrhosis,
    required this.hasTb,
    required this.hasThyroidProblem,
    required this.isSmoker,
    required this.isAlcoholic,
    required this.symptoms,
    required this.symptomDescription,
    required this.durationDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'patient_name': patientName,
      'age': age,
      'gender': gender,
      if (weight != null) 'weight': weight,
      'has_diabetes': hasDiabetes,
      'has_hypertension': hasHypertension,
      'has_heart_disease': hasHeartDisease,
      'has_asthma': hasAsthma,
      'has_kidney_disease': hasKidneyDisease,
      'has_cancer': hasCancer,
      'has_stroke': hasStroke,
      'has_allergy': hasAllergy,
      'has_liver_cirrhosis': hasLiverCirrhosis,
      'has_tb': hasTb,
      'has_thyroid_problem': hasThyroidProblem,
      'is_smoker': isSmoker,
      'is_alcoholic': isAlcoholic,
      'symptoms': symptoms,
      'symptom_description': symptomDescription,
      'duration_days': durationDays,
    };
  }
}

class PossibleConditionModel {
  final String condition;
  final String probability;
  final String description;

  PossibleConditionModel({
    required this.condition,
    required this.probability,
    required this.description,
  });

  factory PossibleConditionModel.fromJson(Map<String, dynamic> json) {
    return PossibleConditionModel(
      condition: json['condition']?.toString() ?? '',
      probability: json['probability']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'probability': probability,
      'description': description,
    };
  }
}

class TriageResultModel {
  final String riskLevel;
  final String riskLevelBn;
  final String recommendedFacility;
  final String recommendedFacilityBn;
  final String recommendedSpecialist;
  final List<PossibleConditionModel> possibleConditions;
  final List<String> primaryAdvice;
  final List<String> warningSigns;
  final String aiSummary;
  final String aiProvider;

  TriageResultModel({
    required this.riskLevel,
    required this.riskLevelBn,
    required this.recommendedFacility,
    required this.recommendedFacilityBn,
    required this.recommendedSpecialist,
    required this.possibleConditions,
    required this.primaryAdvice,
    required this.warningSigns,
    required this.aiSummary,
    required this.aiProvider,
  });

  factory TriageResultModel.fromJson(Map<String, dynamic> json) {
    final conditionsList = (json['possible_conditions'] as List?)
            ?.map((e) => PossibleConditionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final adviceList = (json['primary_advice'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final warningsList = (json['warning_signs'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return TriageResultModel(
      riskLevel: json['risk_level']?.toString() ?? 'low',
      riskLevelBn: json['risk_level_bn']?.toString() ?? 'সাধারণ লক্ষণ',
      recommendedFacility: json['recommended_facility']?.toString() ?? '',
      recommendedFacilityBn: json['recommended_facility_bn']?.toString() ?? '',
      recommendedSpecialist: json['recommended_specialist']?.toString() ?? '',
      possibleConditions: conditionsList,
      primaryAdvice: adviceList,
      warningSigns: warningsList,
      aiSummary: json['ai_summary']?.toString() ?? '',
      aiProvider: json['ai_provider']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_level': riskLevel,
      'risk_level_bn': riskLevelBn,
      'recommended_facility': recommendedFacility,
      'recommended_facility_bn': recommendedFacilityBn,
      'recommended_specialist': recommendedSpecialist,
      'possible_conditions': possibleConditions.map((e) => e.toJson()).toList(),
      'primary_advice': primaryAdvice,
      'warning_signs': warningSigns,
      'ai_summary': aiSummary,
      'ai_provider': aiProvider,
    };
  }
}

class QrModel {
  final String trackingCode;
  final String qrData;
  final String verificationUrl;
  final String qrImageUrl;
  final Map<String, dynamic>? payload;

  QrModel({
    required this.trackingCode,
    required this.qrData,
    required this.verificationUrl,
    required this.qrImageUrl,
    this.payload,
  });

  factory QrModel.fromJson(Map<String, dynamic> json) {
    return QrModel(
      trackingCode: json['tracking_code']?.toString() ?? '',
      qrData: json['qr_data']?.toString() ?? '',
      verificationUrl: json['verification_url']?.toString() ?? '',
      qrImageUrl: json['qr_image_url']?.toString() ?? '',
      payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tracking_code': trackingCode,
      'qr_data': qrData,
      'verification_url': verificationUrl,
      'qr_image_url': qrImageUrl,
      'payload': payload,
    };
  }
}

class ConsultationResponse {
  final int id;
  final String trackingCode;
  final String status;
  final String createdAt;
  final TriageResultModel triageResult;
  final QrModel qr;
  final Map<String, dynamic> rawJson;

  ConsultationResponse({
    required this.id,
    required this.trackingCode,
    required this.status,
    required this.createdAt,
    required this.triageResult,
    required this.qr,
    required this.rawJson,
  });

  factory ConsultationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;

    return ConsultationResponse(
      id: data['id'] is num ? (data['id'] as num).toInt() : int.tryParse(data['id']?.toString() ?? '') ?? 0,
      trackingCode: data['tracking_code']?.toString() ?? '',
      status: data['status']?.toString() ?? 'completed',
      createdAt: data['created_at']?.toString() ?? '',
      triageResult: TriageResultModel.fromJson(
        data['triage_result'] is Map ? Map<String, dynamic>.from(data['triage_result']) : {},
      ),
      qr: QrModel.fromJson(
        data['qr'] is Map ? Map<String, dynamic>.from(data['qr']) : {},
      ),
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() => rawJson;
}
