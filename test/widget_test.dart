import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:research_project/main.dart';
import 'package:research_project/models/consultation_model.dart';
import 'package:research_project/models/patient_record.dart';
import 'package:research_project/services/records_db_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PatientRecord and RecordsDbService test', () async {
    SharedPreferences.setMockInitialValues({});

    final record = PatientRecord(
      id: 'REC-123456',
      patientName: 'করিম মিয়া',
      age: 45,
      gender: 'male',
      weight: 70,
      hasDiabetes: true,
      hasHighBP: false,
      isSmoker: false,
      symptoms: 'বুকে তীব্র ব্যথা',
      urgency: 'emergency',
      careLevelBn: 'মেডিকেল কলেজ হাসপাতাল',
      careLevelEn: 'Medical College Hospital',
      adviceBn: 'দ্রুত হাসপাতালে যান',
      firstAidBn: 'সিপিআর দিন',
      createdAt: DateTime.now(),
    );

    final saved = await RecordsDbService.saveRecord(record);
    expect(saved, true);

    final list = await RecordsDbService.getRecords();
    expect(list.length, 1);
    expect(list.first.patientName, 'করিম মিয়া');
    expect(list.first.hasDiabetes, true);
    expect(list.first.toQrPayload().contains('করিম মিয়া'), true);

    final deleted = await RecordsDbService.deleteRecord('REC-123456');
    expect(deleted, true);

    final emptyList = await RecordsDbService.getRecords();
    expect(emptyList.isEmpty, true);
  });

  test('Consultation API Request and Response parsing test', () {
    final req = ConsultationRequest(
      patientName: 'করিম সাহেব',
      age: 52,
      gender: 'male',
      weight: 72,
      hasDiabetes: true,
      hasHypertension: true,
      hasHeartDisease: false,
      hasAsthma: true,
      hasKidneyDisease: true,
      hasCancer: false,
      hasStroke: true,
      hasAllergy: true,
      hasLiverCirrhosis: false,
      hasTb: false,
      hasThyroidProblem: true,
      isSmoker: true,
      isAlcoholic: false,
      symptoms: ['বুকে তীব্র ব্যথা', 'শ্বাসকষ্ট'],
      symptomDescription: 'শ্বাসকষ্ট ও বুকে চাপ অনুভূত হচ্ছে',
      durationDays: 2,
    );

    final jsonReq = req.toJson();
    expect(jsonReq['patient_name'], 'করিম সাহেব');
    expect(jsonReq['age'], 52);
    expect(jsonReq['has_diabetes'], true);
    expect(jsonReq['has_hypertension'], true);
    expect(jsonReq['has_heart_disease'], false);
    expect(jsonReq['has_asthma'], true);
    expect(jsonReq['has_kidney_disease'], true);
    expect(jsonReq['has_cancer'], false);
    expect(jsonReq['has_stroke'], true);
    expect(jsonReq['has_allergy'], true);
    expect(jsonReq['has_liver_cirrhosis'], false);
    expect(jsonReq['has_tb'], false);
    expect(jsonReq['has_thyroid_problem'], true);
    expect(jsonReq['is_smoker'], true);
    expect(jsonReq['is_alcoholic'], false);
    expect(jsonReq['symptoms'], ['বুকে তীব্র ব্যথা', 'শ্বাসকষ্ট']);
    expect(jsonReq['duration_days'], 2);

    final sampleResponseJson = {
      "data": {
        "id": 3,
        "tracking_code": "DK-202610-GP6HU",
        "patient": {
          "name": "করিম সাহেব",
          "age": 52,
          "gender": "male",
          "weight": 72,
          "risk_factors": {
            "is_smoker": true,
            "has_diabetes": true,
            "has_hypertension": true,
            "has_heart_disease": false,
            "has_asthma": true,
            "has_kidney_disease": true,
            "has_cancer": false,
            "has_stroke": true,
            "has_allergy": true,
            "has_liver_cirrhosis": false,
            "has_tb": false,
            "has_thyroid_problem": true,
            "is_alcoholic": false
          }
        },
        "symptoms": {
          "selected": ["বুকে তীব্র ব্যথা", "শ্বাসকষ্ট"],
          "description": "শ্বাসকষ্ট ও বুকে চাপ অনুভূত হচ্ছে",
          "duration_days": 2
        },
        "triage_result": {
          "risk_level": "high",
          "risk_level_bn": "জরুরি / উচ্চ ঝুঁকি",
          "recommended_facility": "medical_college",
          "recommended_facility_bn": "মেডিকেল কলেজ হাসপাতাল",
          "recommended_specialist": "হৃদরোগ বিশেষজ্ঞ (Cardiologist)",
          "possible_conditions": [
            {
              "condition": "মায়োকার্ডিয়াল ইনফার্কশন বা হার্ট অ্যাটাক (Myocardial Infarction)",
              "probability": "উচ্চ (High)",
              "description": "বুকে চাপ, তীব্র ব্যথা এবং শ্বাসকষ্টের উপসর্গগুলো হৃদরোগের গুরুতর সমস্যার ইঙ্গিত দেয়।"
            }
          ],
          "primary_advice": [
            "রোগীকে অবিলম্বে সম্পূর্ণ বিশ্রামে রাখুন।"
          ],
          "warning_signs": [
            "বুকের ব্যথা যদি চোরা, গলা, বাহু বা পিঠের দিকে ছড়িয়ে পড়ে"
          ],
          "ai_summary": "করিম সাহেবের বয়স ৫২ বছর এবং তাঁর ডায়াবেটিস ও উচ্চ রক্তচাপ রয়েছে...",
          "ai_provider": "gemini"
        },
        "qr": {
          "tracking_code": "DK-202610-GP6HU",
          "qr_data": "DK-202610-GP6HU",
          "verification_url": "https://dev.learnwithnoman.com/api/v1/consultations/DK-202610-GP6HU",
          "qr_image_url": "https://dev.learnwithnoman.com/api/v1/consultations/DK-202610-GP6HU/qr"
        },
        "status": "completed",
        "created_at": "2026-10-27T06:46:29+00:00"
      }
    };

    final resp = ConsultationResponse.fromJson(sampleResponseJson);
    expect(resp.id, 3);
    expect(resp.trackingCode, 'DK-202610-GP6HU');
    expect(resp.triageResult.riskLevel, 'high');
    expect(resp.triageResult.riskLevelBn, 'জরুরি / উচ্চ ঝুঁকি');
    expect(resp.triageResult.recommendedFacilityBn, 'মেডিকেল কলেজ হাসপাতাল');
    expect(resp.triageResult.recommendedSpecialist, 'হৃদরোগ বিশেষজ্ঞ (Cardiologist)');
    expect(resp.triageResult.possibleConditions.length, 1);
    expect(resp.triageResult.primaryAdvice.length, 1);
    expect(resp.qr.verificationUrl, 'https://dev.learnwithnoman.com/api/v1/consultations/DK-202610-GP6HU');
  });

  testWidgets('Dr. Kache Home Screen Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    expect(find.text('ডাক্তার কাছে (Dr. Kache)'), findsOneWidget);
    expect(find.text('লক্ষণ যাচাই করুন (শুরু করুন)'), findsOneWidget);
  });
}
