import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/consultation_model.dart';

class ConsultationApiException implements Exception {
  final String message;
  final int? statusCode;

  ConsultationApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ConsultationApiService {
  static const String baseUrl = 'https://dev.learnwithnoman.com';
  static const Duration timeoutDuration = Duration(seconds: 35);

  /// Submits patient information, symptoms, and risk factors to the consultation API.
  static Future<ConsultationResponse> createConsultation(ConsultationRequest request) async {
    final uri = Uri.parse('$baseUrl/api/v1/consultations');
    final payloadJson = jsonEncode(request.toJson());

    debugPrint('ConsultationApiService: Calling POST $uri');
    debugPrint('ConsultationApiService payload: $payloadJson');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: payloadJson,
          )
          .timeout(timeoutDuration);

      debugPrint('ConsultationApiService response code: ${response.statusCode}');
      debugPrint('ConsultationApiService response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return ConsultationResponse.fromJson(decoded);
        } else {
          throw ConsultationApiException('সার্ভার থেকে প্রাপ্ত তথ্য সঠিক ফরম্যাটে নেই।');
        }
      } else if (response.statusCode == 422) {
        // Validation Error
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final message = decoded['message'] ?? 'তথ্য যাচাইয়ে সমস্যা হয়েছে।';
          throw ConsultationApiException('যাচাইকরণ ত্রুটি (422): $message', statusCode: 422);
        } catch (e) {
          if (e is ConsultationApiException) rethrow;
          throw ConsultationApiException('যাচাইকরণ ত্রুটি (422): সব তথ্য সঠিকভাবে পূরণ করুন।', statusCode: 422);
        }
      } else {
        throw ConsultationApiException(
          'সার্ভার ত্রুটি (${response.statusCode})। অনুগ্রহ করে কিছুক্ষণ পর আবার চেষ্টা করুন।',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      debugPrint('ConsultationApiService SocketException: $e');
      throw ConsultationApiException('ইন্টারনেট সংযোগ পাওয়া যাচ্ছে না। আপনার নেটওয়ার্ক চেক করুন।');
    } on TimeoutException catch (e) {
      debugPrint('ConsultationApiService TimeoutException: $e');
      throw ConsultationApiException('সার্ভার থেকে সাড়া পেতে বেশি সময় লাগছে। অনুগ্রহ করে পুনরায় চেষ্টা করুন।');
    } on http.ClientException catch (e) {
      debugPrint('ConsultationApiService ClientException: $e');
      throw ConsultationApiException('নেটওয়ার্ক সংযোগ ব্যর্থ হয়েছে: ${e.message}');
    } catch (e) {
      debugPrint('ConsultationApiService Unexpected error: $e');
      if (e is ConsultationApiException) rethrow;
      throw ConsultationApiException('অনাকাঙ্ক্ষিত ত্রুটি: $e');
    }
  }

  /// Retrieves consultation result by its tracking code.
  static Future<ConsultationResponse> getConsultation(String trackingCode) async {
    final uri = Uri.parse('$baseUrl/api/v1/consultations/$trackingCode');
    debugPrint('ConsultationApiService: Calling GET $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return ConsultationResponse.fromJson(decoded);
      } else {
        throw ConsultationApiException('পরামর্শ রেকর্ড খুঁজে পাওয়া যায়নি (${response.statusCode})');
      }
    } catch (e) {
      if (e is ConsultationApiException) rethrow;
      throw ConsultationApiException('রেকর্ড লোড করতে ব্যর্থ হয়েছে: $e');
    }
  }
}
