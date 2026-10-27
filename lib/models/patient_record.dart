import 'dart:convert';
import 'package:intl/intl.dart';

class PatientRecord {
  final String id;
  final String? trackingCode;
  final String patientName;
  final int age;
  final String gender;
  final double? weight;
  final int durationDays;
  final bool hasDiabetes;
  final bool hasHighBP; // has_hypertension
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
  final String symptoms;
  final String urgency; // 'emergency', 'high', 'medium', 'low'
  final String careLevelBn;
  final String careLevelEn;
  final String? recommendedSpecialist;
  final String? aiSummary;
  final String adviceBn;
  final String firstAidBn;
  final String? verificationUrl;
  final String? consultationJson;
  final DateTime createdAt;

  PatientRecord({
    required this.id,
    this.trackingCode,
    required this.patientName,
    required this.age,
    required this.gender,
    this.weight,
    this.durationDays = 2,
    required this.hasDiabetes,
    required this.hasHighBP,
    this.hasHeartDisease = false,
    this.hasAsthma = false,
    this.hasKidneyDisease = false,
    this.hasCancer = false,
    this.hasStroke = false,
    this.hasAllergy = false,
    this.hasLiverCirrhosis = false,
    this.hasTb = false,
    this.hasThyroidProblem = false,
    required this.isSmoker,
    this.isAlcoholic = false,
    required this.symptoms,
    required this.urgency,
    required this.careLevelBn,
    required this.careLevelEn,
    this.recommendedSpecialist,
    this.aiSummary,
    required this.adviceBn,
    required this.firstAidBn,
    this.verificationUrl,
    this.consultationJson,
    required this.createdAt,
  });

  String get genderDisplayBn {
    switch (gender) {
      case 'female':
        return 'নারী';
      case 'pregnant':
        return 'গর্ভবতী মা';
      case 'male':
      default:
        return 'পুরুষ';
    }
  }

  String get urgencyDisplayBn {
    switch (urgency) {
      case 'emergency':
        return 'জরুরি অবস্থা (Emergency)';
      case 'high':
        return 'উচ্চ ঝুঁকি (High Risk)';
      case 'medium':
        return 'মাঝারি লক্ষণ (Moderate)';
      case 'low':
      default:
        return 'সাধারণ লক্ষণ (Low Risk)';
    }
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
  }

  /// Generates a comprehensive, human-readable and structured medical summary
  /// that any standard QR scanner or doctor app can immediately display.
  String toQrPayload() {
    final buffer = StringBuffer();
    buffer.writeln('📋 [ডাঃ কাছে - ডিজিটাল ট্রায়াজ ও প্রেসক্রিপশন]');
    if (trackingCode != null && trackingCode!.isNotEmpty) {
      buffer.writeln('ট্র্যাকিং কোড: $trackingCode');
    }
    buffer.writeln('আইডি: $id');
    buffer.writeln('তারিখ: $formattedDate');
    if (verificationUrl != null && verificationUrl!.isNotEmpty) {
      buffer.writeln('অনলাইন ভেরিফিকেশন: $verificationUrl');
    }
    buffer.writeln('------------------------------------');
    buffer.writeln('👤 রোগীর তথ্য:');
    buffer.writeln('নাম: ${patientName.isEmpty ? "নাম উল্লেখ নেই" : patientName}');
    buffer.writeln('বয়স: $age বছর | লিঙ্গ: $genderDisplayBn${weight != null ? ' | ওজন: $weight কেজি' : ''}');
    buffer.writeln('লক্ষণ স্থায়িত্ব: $durationDays দিন');
    
    final riskList = <String>[];
    if (hasDiabetes) riskList.add('ডায়াবেটিস');
    if (hasHighBP) riskList.add('উচ্চ রক্তচাপ');
    if (hasHeartDisease) riskList.add('হৃদরোগ');
    if (hasAsthma) riskList.add('হাঁপানি/অ্যাজমা');
    if (hasKidneyDisease) riskList.add('কিডনি রোগ');
    if (hasCancer) riskList.add('ক্যান্সার');
    if (hasStroke) riskList.add('স্ট্রোক');
    if (hasAllergy) riskList.add('অ্যালার্জি');
    if (hasLiverCirrhosis) riskList.add('লিভার সিরোসিস');
    if (hasTb) riskList.add('যক্ষ্মা (TB)');
    if (hasThyroidProblem) riskList.add('থাইরয়েড সমস্যা');
    if (isSmoker) riskList.add('ধূমপায়ী');
    if (isAlcoholic) riskList.add('মদ্যপান');
    buffer.writeln('ঝুঁকি ফ্যাক্টর: ${riskList.isEmpty ? "কোনোটিই নয়" : riskList.join(", ")}');
    
    buffer.writeln('------------------------------------');
    buffer.writeln('🩺 রোগীর লক্ষণ ও সমস্যা:');
    buffer.writeln(symptoms.trim());
    
    buffer.writeln('------------------------------------');
    buffer.writeln('🏥 ট্রায়াজ মূল্যায়ন ও সুপারিশ:');
    buffer.writeln('ঝুঁকির মাত্রা: $urgencyDisplayBn');
    buffer.writeln('প্রস্তাবিত স্বাস্থ্যকেন্দ্র: $careLevelBn ($careLevelEn)');
    if (recommendedSpecialist != null && recommendedSpecialist!.isNotEmpty) {
      buffer.writeln('প্রস্তাবিত বিশেষজ্ঞ: $recommendedSpecialist');
    }
    
    if (aiSummary != null && aiSummary!.isNotEmpty) {
      buffer.writeln('------------------------------------');
      buffer.writeln('🤖 এআই মূল্যায়ন:');
      buffer.writeln(aiSummary!.trim());
    }

    if (firstAidBn.isNotEmpty) {
      buffer.writeln('জরুরি পরামর্শ: $firstAidBn');
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trackingCode': trackingCode,
      'patientName': patientName,
      'age': age,
      'gender': gender,
      'weight': weight,
      'durationDays': durationDays,
      'hasDiabetes': hasDiabetes,
      'hasHighBP': hasHighBP,
      'hasHeartDisease': hasHeartDisease,
      'hasAsthma': hasAsthma,
      'hasKidneyDisease': hasKidneyDisease,
      'hasCancer': hasCancer,
      'hasStroke': hasStroke,
      'hasAllergy': hasAllergy,
      'hasLiverCirrhosis': hasLiverCirrhosis,
      'hasTb': hasTb,
      'hasThyroidProblem': hasThyroidProblem,
      'isSmoker': isSmoker,
      'isAlcoholic': isAlcoholic,
      'symptoms': symptoms,
      'urgency': urgency,
      'careLevelBn': careLevelBn,
      'careLevelEn': careLevelEn,
      'recommendedSpecialist': recommendedSpecialist,
      'aiSummary': aiSummary,
      'adviceBn': adviceBn,
      'firstAidBn': firstAidBn,
      'verificationUrl': verificationUrl,
      'consultationJson': consultationJson,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PatientRecord.fromMap(Map<String, dynamic> map) {
    return PatientRecord(
      id: map['id'] ?? '',
      trackingCode: map['trackingCode'],
      patientName: map['patientName'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'male',
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      durationDays: map['durationDays'] ?? 2,
      hasDiabetes: map['hasDiabetes'] ?? false,
      hasHighBP: map['hasHighBP'] ?? false,
      hasHeartDisease: map['hasHeartDisease'] ?? false,
      hasAsthma: map['hasAsthma'] ?? false,
      hasKidneyDisease: map['hasKidneyDisease'] ?? false,
      hasCancer: map['hasCancer'] ?? false,
      hasStroke: map['hasStroke'] ?? false,
      hasAllergy: map['hasAllergy'] ?? false,
      hasLiverCirrhosis: map['hasLiverCirrhosis'] ?? false,
      hasTb: map['hasTb'] ?? false,
      hasThyroidProblem: map['hasThyroidProblem'] ?? false,
      isSmoker: map['isSmoker'] ?? false,
      isAlcoholic: map['isAlcoholic'] ?? false,
      symptoms: map['symptoms'] ?? '',
      urgency: map['urgency'] ?? 'low',
      careLevelBn: map['careLevelBn'] ?? '',
      careLevelEn: map['careLevelEn'] ?? '',
      recommendedSpecialist: map['recommendedSpecialist'],
      aiSummary: map['aiSummary'],
      adviceBn: map['adviceBn'] ?? '',
      firstAidBn: map['firstAidBn'] ?? '',
      verificationUrl: map['verificationUrl'],
      consultationJson: map['consultationJson'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PatientRecord.fromJson(String source) =>
      PatientRecord.fromMap(json.decode(source));
}
