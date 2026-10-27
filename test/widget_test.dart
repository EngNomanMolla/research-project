import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:research_project/main.dart';
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

  testWidgets('Dr. Kache Home Screen Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    expect(find.text('ডাক্তার কাছে (Dr. Kache)'), findsOneWidget);
    expect(find.text('লক্ষণ যাচাই করুন (শুরু করুন)'), findsOneWidget);
  });
}
