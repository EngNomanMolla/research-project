import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient_record.dart';

class RecordsDbService {
  static const String _storageKey = 'saved_patient_records';
  
  // In-memory cache for instant synchronous access and reliability
  static final List<PatientRecord> _memoryCache = [];

  /// Saves a new patient triage record to local storage.
  static Future<bool> saveRecord(PatientRecord record) async {
    try {
      // 1. Update in-memory cache first
      _memoryCache.removeWhere((item) => item.id == record.id);
      _memoryCache.insert(0, record);

      // 2. Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = prefs.getStringList(_storageKey) ?? [];
      
      rawList.removeWhere((item) {
        try {
          final Map<String, dynamic> data = json.decode(item);
          return data['id'] == record.id;
        } catch (_) {
          return false;
        }
      });

      rawList.insert(0, record.toJson());
      final success = await prefs.setStringList(_storageKey, rawList);
      debugPrint('RecordsDbService: Saved record ${record.id} (success: $success). Total: ${rawList.length}');
      return success;
    } catch (e) {
      debugPrint('RecordsDbService error saving: $e');
      // In-memory cache is still saved
      return true;
    }
  }

  /// Retrieves all saved patient records, sorted newest first.
  static Future<List<PatientRecord>> getRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = prefs.getStringList(_storageKey) ?? [];
      
      final List<PatientRecord> diskRecords = [];
      for (final raw in rawList) {
        try {
          diskRecords.add(PatientRecord.fromJson(raw));
        } catch (e) {
          debugPrint('RecordsDbService: skipping invalid entry: $e');
        }
      }

      // Sync memory cache with disk records
      for (final diskRecord in diskRecords) {
        if (!_memoryCache.any((m) => m.id == diskRecord.id)) {
          _memoryCache.add(diskRecord);
        }
      }
      
      // Sort by creation date descending
      _memoryCache.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List<PatientRecord>.from(_memoryCache);
    } catch (e) {
      debugPrint('RecordsDbService error getting records: $e');
      return List<PatientRecord>.from(_memoryCache);
    }
  }

  /// Deletes a specific patient record by its ID.
  static Future<bool> deleteRecord(String id) async {
    try {
      // 1. Remove from memory
      _memoryCache.removeWhere((item) => item.id == id);

      // 2. Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final List<String> rawList = prefs.getStringList(_storageKey) ?? [];
      
      rawList.removeWhere((item) {
        try {
          final Map<String, dynamic> data = json.decode(item);
          return data['id'] == id;
        } catch (_) {
          return false;
        }
      });

      final success = await prefs.setStringList(_storageKey, rawList);
      debugPrint('RecordsDbService: Deleted record $id (success: $success). Remaining: ${rawList.length}');
      return success;
    } catch (e) {
      debugPrint('RecordsDbService error deleting: $e');
      return true;
    }
  }

  /// Clears all stored records.
  static Future<bool> clearAllRecords() async {
    try {
      _memoryCache.clear();
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('RecordsDbService error clearing: $e');
      return false;
    }
  }

  /// Creates and saves a sample demo record for quick testing.
  static Future<PatientRecord> createSampleDemoRecord() async {
    final sample = PatientRecord(
      id: 'REC-${DateTime.now().millisecondsSinceEpoch}',
      patientName: 'মোঃ আব্দুল করিম',
      age: 48,
      gender: 'male',
      weight: 68.5,
      hasDiabetes: true,
      hasHighBP: true,
      isSmoker: false,
      symptoms: 'বুকে তীব্র চাপ ও ব্যথা, শ্বাস নিতে কষ্ট হচ্ছে এবং বুক ধড়ফড় করছে।',
      urgency: 'emergency',
      careLevelBn: 'মেডিকেল কলেজ ও বিশেষায়িত হাসপাতাল',
      careLevelEn: 'Medical College & Specialized Hospital',
      adviceBn: 'কোনো ভুয়া কবিরাজ বা হাতুড়ে ডাক্তারের কাছে গিয়ে সময় নষ্ট করবেন না। অবিলম্বে হাসপাতালে জরুরি বিভাগে যান।',
      firstAidBn: 'রোগীকে সোজা বসিয়ে রাখুন। টাইট কাপড় ঢিলে করে দিন। তাৎক্ষণিকভাবে ১৬২৬৩ বা ৯৯৯ এ কল করে অ্যাম্বুলেন্স ডাকুন।',
      createdAt: DateTime.now(),
    );
    await saveRecord(sample);
    return sample;
  }
}
