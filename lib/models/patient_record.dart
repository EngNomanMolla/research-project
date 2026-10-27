import 'dart:convert';
import 'package:intl/intl.dart';

class PatientRecord {
  final String id;
  final String patientName;
  final int age;
  final String gender;
  final double? weight;
  final bool hasDiabetes;
  final bool hasHighBP;
  final bool isSmoker;
  final String symptoms;
  final String urgency; // 'emergency', 'high', 'medium', 'low'
  final String careLevelBn;
  final String careLevelEn;
  final String adviceBn;
  final String firstAidBn;
  final DateTime createdAt;

  PatientRecord({
    required this.id,
    required this.patientName,
    required this.age,
    required this.gender,
    this.weight,
    required this.hasDiabetes,
    required this.hasHighBP,
    required this.isSmoker,
    required this.symptoms,
    required this.urgency,
    required this.careLevelBn,
    required this.careLevelEn,
    required this.adviceBn,
    required this.firstAidBn,
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
    buffer.writeln('📋 [ডাঃ কাছে - ডিজিটাল প্রেসক্রিপশন ও ট্রায়াজ রিপোর্ট]');
    buffer.writeln('আইডি: $id');
    buffer.writeln('তারিখ: $formattedDate');
    buffer.writeln('------------------------------------');
    buffer.writeln('👤 রোগীর তথ্য:');
    buffer.writeln('নাম: ${patientName.isEmpty ? "নাম উল্লেখ নেই" : patientName}');
    buffer.writeln('বয়স: $age বছর | লিঙ্গ: $genderDisplayBn${weight != null ? ' | ওজন: $weight কেজি' : ''}');
    
    final riskList = <String>[];
    if (hasDiabetes) riskList.add('ডায়াবেটিস');
    if (hasHighBP) riskList.add('উচ্চ রক্তচাপ');
    if (isSmoker) riskList.add('ধূমপায়ী');
    buffer.writeln('ঝুঁকি ফ্যাক্টর: ${riskList.isEmpty ? "কোনোটিই নয়" : riskList.join(", ")}');
    
    buffer.writeln('------------------------------------');
    buffer.writeln('🩺 রোগীর লক্ষণ ও সমস্যা:');
    buffer.writeln(symptoms.trim());
    
    buffer.writeln('------------------------------------');
    buffer.writeln('🏥 ট্রায়াজ মূল্যায়ন ও সুপারিশ:');
    buffer.writeln('ঝুঁকির মাত্রা: $urgencyDisplayBn');
    buffer.writeln('প্রস্তাবিত স্বাস্থ্যকেন্দ্র: $careLevelBn ($careLevelEn)');
    
    if (firstAidBn.isNotEmpty) {
      buffer.writeln('জরুরি পরামর্শ: $firstAidBn');
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'age': age,
      'gender': gender,
      'weight': weight,
      'hasDiabetes': hasDiabetes,
      'hasHighBP': hasHighBP,
      'isSmoker': isSmoker,
      'symptoms': symptoms,
      'urgency': urgency,
      'careLevelBn': careLevelBn,
      'careLevelEn': careLevelEn,
      'adviceBn': adviceBn,
      'firstAidBn': firstAidBn,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PatientRecord.fromMap(Map<String, dynamic> map) {
    return PatientRecord(
      id: map['id'] ?? '',
      patientName: map['patientName'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'male',
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      hasDiabetes: map['hasDiabetes'] ?? false,
      hasHighBP: map['hasHighBP'] ?? false,
      isSmoker: map['isSmoker'] ?? false,
      symptoms: map['symptoms'] ?? '',
      urgency: map['urgency'] ?? 'low',
      careLevelBn: map['careLevelBn'] ?? '',
      careLevelEn: map['careLevelEn'] ?? '',
      adviceBn: map['adviceBn'] ?? '',
      firstAidBn: map['firstAidBn'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PatientRecord.fromJson(String source) =>
      PatientRecord.fromMap(json.decode(source));
}
