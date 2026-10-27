import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/consultation_model.dart';
import '../models/patient_record.dart';
import '../services/records_db_service.dart';
import '../services/triage_service.dart';
import '../theme/app_theme.dart';
import 'saved_records_screen.dart';

class ResultScreen extends StatefulWidget {
  final TriageResult result;
  final ConsultationResponse? consultation;
  final String patientName;
  final String symptoms;
  final int age;
  final double? weight;
  final int durationDays;
  final bool hasDiabetes;
  final bool hasHighBP;
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
  final String gender;

  const ResultScreen({
    super.key,
    required this.result,
    this.consultation,
    required this.patientName,
    required this.symptoms,
    required this.age,
    required this.weight,
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
    required this.gender,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isPlayingAudio = false;
  int _highlightedWordIndex = -1;
  Timer? _audioTimer;
  List<String> _audioWords = [];
  late PatientRecord _patientRecord;
  final FlutterTts _flutterTts = FlutterTts();

  String get _speakableText {
    if (widget.consultation != null && widget.consultation!.triageResult.aiSummary.isNotEmpty) {
      return widget.consultation!.triageResult.aiSummary;
    }
    return widget.result.audioScriptBn;
  }

  Color get _themeColor {
    if (widget.consultation != null) {
      final level = widget.consultation!.triageResult.riskLevel.toLowerCase();
      if (level == 'emergency') return const Color(0xFFE63946);
      if (level == 'high') return const Color(0xFFE29578);
      if (level == 'medium') return const Color(0xFFF4A261);
      return const Color(0xFF2A9D8F);
    }
    return widget.result.color;
  }

  String get _urgencyTextBn {
    if (widget.consultation != null) {
      return widget.consultation!.triageResult.riskLevelBn;
    }
    switch (widget.result.urgency) {
      case UrgencyLevel.emergency:
        return 'জরুরি অবস্থা (Emergency)';
      case UrgencyLevel.high:
        return 'উচ্চ ঝুঁকি (High Risk)';
      case UrgencyLevel.medium:
        return 'মাঝারি লক্ষণ (Moderate Symptoms)';
      case UrgencyLevel.low:
        return 'সাধারণ লক্ষণ (Low Risk)';
    }
  }

  String get _careFacilityBn {
    if (widget.consultation != null && widget.consultation!.triageResult.recommendedFacilityBn.isNotEmpty) {
      return widget.consultation!.triageResult.recommendedFacilityBn;
    }
    return widget.result.careLevelBn;
  }

  String? get _specialistBn {
    if (widget.consultation != null && widget.consultation!.triageResult.recommendedSpecialist.isNotEmpty) {
      return widget.consultation!.triageResult.recommendedSpecialist;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Prepare words for simulated TTS word-by-word highlighting
    _audioWords = _speakableText.split(' ').where((w) => w.trim().isNotEmpty).toList();

    // Construct PatientRecord model
    final tracking = widget.consultation?.trackingCode;
    _patientRecord = PatientRecord(
      id: tracking ?? 'REC-${DateTime.now().millisecondsSinceEpoch}',
      trackingCode: tracking,
      patientName: widget.patientName,
      age: widget.age,
      gender: widget.gender,
      weight: widget.weight,
      durationDays: widget.durationDays,
      hasDiabetes: widget.hasDiabetes,
      hasHighBP: widget.hasHighBP,
      hasHeartDisease: widget.hasHeartDisease,
      hasAsthma: widget.hasAsthma,
      hasKidneyDisease: widget.hasKidneyDisease,
      hasCancer: widget.hasCancer,
      hasStroke: widget.hasStroke,
      hasAllergy: widget.hasAllergy,
      hasLiverCirrhosis: widget.hasLiverCirrhosis,
      hasTb: widget.hasTb,
      hasThyroidProblem: widget.hasThyroidProblem,
      isSmoker: widget.isSmoker,
      isAlcoholic: widget.isAlcoholic,
      symptoms: widget.symptoms,
      urgency: widget.consultation?.triageResult.riskLevel ?? _getUrgencyKey(widget.result.urgency),
      careLevelBn: _careFacilityBn,
      careLevelEn: widget.consultation?.triageResult.recommendedFacility ?? widget.result.careLevelEn,
      recommendedSpecialist: _specialistBn,
      aiSummary: widget.consultation?.triageResult.aiSummary,
      adviceBn: widget.consultation != null && widget.consultation!.triageResult.primaryAdvice.isNotEmpty
          ? widget.consultation!.triageResult.primaryAdvice.join('\n• ')
          : widget.result.adviceBn,
      firstAidBn: widget.consultation != null && widget.consultation!.triageResult.warningSigns.isNotEmpty
          ? widget.consultation!.triageResult.warningSigns.join('\n• ')
          : widget.result.firstAidBn,
      verificationUrl: widget.consultation?.qr.verificationUrl,
      consultationJson: widget.consultation != null ? jsonEncode(widget.consultation!.rawJson) : null,
      createdAt: DateTime.now(),
    );

    // Save record to local database automatically
    _saveRecordToLocalDb();

    // Initialize Text to speech
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('bn-BD');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlayingAudio = false;
          _highlightedWordIndex = -1;
        });
        _audioTimer?.cancel();
      });

      _flutterTts.setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlayingAudio = false;
          _highlightedWordIndex = -1;
        });
        _audioTimer?.cancel();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        if (!mounted) return;
        setState(() {
          _isPlayingAudio = false;
          _highlightedWordIndex = -1;
        });
        _audioTimer?.cancel();
      });
    } catch (e) {
      debugPrint('TTS Init Error: $e');
    }
  }

  Future<void> _saveRecordToLocalDb() async {
    await RecordsDbService.saveRecord(_patientRecord);
  }

  String _getUrgencyKey(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.emergency:
        return 'emergency';
      case UrgencyLevel.high:
        return 'high';
      case UrgencyLevel.medium:
        return 'medium';
      case UrgencyLevel.low:
        return 'low';
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleAudioPlayback() async {
    if (_isPlayingAudio) {
      await _flutterTts.stop();
      _audioTimer?.cancel();
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _highlightedWordIndex = -1;
        });
      }
    } else {
      setState(() {
        _isPlayingAudio = true;
        _highlightedWordIndex = 0;
      });

      _audioTimer?.cancel();
      _audioTimer = Timer.periodic(const Duration(milliseconds: 380), (timer) {
        if (!mounted) return;
        setState(() {
          if (_highlightedWordIndex < _audioWords.length - 1) {
            _highlightedWordIndex++;
          } else {
            _audioTimer?.cancel();
          }
        });
      });

      try {
        await _flutterTts.speak(_speakableText);
      } catch (e) {
        debugPrint('TTS Speak exception: $e');
      }
    }
  }

  void _showFullscreenQr() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ডাক্তারকে স্ক্যান করতে দিন',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              if (_patientRecord.trackingCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ট্র্যাকিং কোড: ${_patientRecord.trackingCode}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'রোগী: ${_patientRecord.patientName.isEmpty ? "অজ্ঞাত" : _patientRecord.patientName} (${_patientRecord.age} বছর)',
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: QrImageView(
                  data: _patientRecord.toQrPayload(),
                  version: QrVersions.auto,
                  size: 240.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppTheme.primaryColor,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1D3557),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বন্ধ করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyTrackingCode() {
    final code = widget.consultation?.trackingCode;
    if (code != null && code.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ট্র্যাকিং কোড "$code" ক্লিপবোর্ডে কপি করা হয়েছে!'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _themeColor;
    final isDarkBadge = color == const Color(0xFFE63946) || color == const Color(0xFFE29578);
    final headerTextColor = isDarkBadge ? Colors.white : AppTheme.textDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('পরামর্শ ও ফলাফল', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'সংরক্ষিত হিস্ট্রি',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedRecordsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tracking Code Banner (if available)
            if (widget.consultation != null && widget.consultation!.trackingCode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.08),
                      AppTheme.secondaryColor.withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: AppTheme.primaryColor, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ডিজিটাল ট্রায়াজ ট্র্যাকিং কোড',
                            style: TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            widget.consultation!.trackingCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: AppTheme.primaryColor),
                      tooltip: 'কপি করুন',
                      onPressed: _copyTrackingCode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Patient details bar
            Text(
              'রোগী: ${widget.patientName.isEmpty ? "অজ্ঞাত" : widget.patientName} এর জন্য এআই ট্রায়াজ মূল্যায়ন',
              style: const TextStyle(fontSize: 14, color: AppTheme.textLight, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildDetailChip('বয়স: ${widget.age} বছর', Icons.calendar_today),
                if (widget.weight != null)
                  _buildDetailChip('ওজন: ${widget.weight} কেজি', Icons.monitor_weight),
                _buildDetailChip('স্থায়িত্ব: ${widget.durationDays} দিন', Icons.timer_outlined),
                _buildDetailChip(
                  widget.gender == 'male'
                      ? 'পুরুষ'
                      : widget.gender == 'female'
                          ? 'নারী'
                          : 'গর্ভবতী মা',
                  Icons.person,
                ),
                if (widget.hasDiabetes)
                  _buildDetailChip('ডায়াবেটিস', Icons.bloodtype, color: AppTheme.dangerColor),
                if (widget.hasHighBP)
                  _buildDetailChip('উচ্চ রক্তচাপ', Icons.favorite, color: AppTheme.dangerColor),
                if (widget.hasHeartDisease)
                  _buildDetailChip('হৃদরোগ', Icons.monitor_heart, color: AppTheme.dangerColor),
                if (widget.hasAsthma)
                  _buildDetailChip('হাঁপানি/অ্যাজমা', Icons.air, color: AppTheme.warningColor),
                if (widget.hasKidneyDisease)
                  _buildDetailChip('কিডনি রোগ', Icons.water_drop, color: AppTheme.warningColor),
                if (widget.hasStroke)
                  _buildDetailChip('স্ট্রোক', Icons.psychology, color: AppTheme.dangerColor),
                if (widget.hasCancer)
                  _buildDetailChip('ক্যান্সার', Icons.medical_services, color: AppTheme.dangerColor),
                if (widget.hasAllergy)
                  _buildDetailChip('অ্যালার্জি', Icons.coronavirus, color: AppTheme.warningColor),
                if (widget.hasThyroidProblem)
                  _buildDetailChip('থাইরয়েড', Icons.healing, color: AppTheme.warningColor),
                if (widget.hasLiverCirrhosis)
                  _buildDetailChip('লিভার সিরোসিস', Icons.local_hospital, color: AppTheme.dangerColor),
                if (widget.hasTb)
                  _buildDetailChip('যক্ষ্মা (TB)', Icons.sick, color: AppTheme.dangerColor),
                if (widget.isSmoker)
                  _buildDetailChip('ধূমপায়ী', Icons.smoking_rooms, color: AppTheme.warningColor),
                if (widget.isAlcoholic)
                  _buildDetailChip('মদ্যপান', Icons.local_bar, color: AppTheme.warningColor),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Primary Recommendation Card (Facility & Specialist)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppTheme.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgency badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: headerTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _urgencyTextBn,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: headerTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'আপনার যাওয়া উচিত:',
                    style: TextStyle(
                      fontSize: 13,
                      color: headerTextColor.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _careFacilityBn,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: headerTextColor,
                      height: 1.3,
                    ),
                  ),
                  if (_specialistBn != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_pin, color: headerTextColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'প্রস্তাবিত বিশেষজ্ঞ: $_specialistBn',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: headerTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.consultation == null) ...[
                    const Divider(height: 25, color: Colors.white24),
                    Text(
                      widget.result.descriptionBn,
                      style: TextStyle(
                        fontSize: 13,
                        color: headerTextColor.withOpacity(0.92),
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. AI Assessment & Voice Audio Guidance
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2), width: 1.5),
                borderRadius: AppTheme.borderRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          radius: 20,
                          child: IconButton(
                            icon: Icon(
                              _isPlayingAudio ? Icons.pause : Icons.volume_up,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            onPressed: _toggleAudioPlayback,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'এআই মূল্যায়ন ও অডিও পরামর্শ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                'শুনতে স্পিকার বাটনে চাপুন (বাংলা ভয়েস গাইড)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isPlayingAudio)
                          const SizedBox(
                            width: 32,
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              color: AppTheme.primaryColor,
                            ),
                          )
                      ],
                    ),
                    const Divider(height: 20),
                    RichText(
                      text: TextSpan(
                        children: List.generate(_audioWords.length, (index) {
                          final isHighlighted = index == _highlightedWordIndex;
                          return TextSpan(
                            text: '${_audioWords[index]} ',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              height: 1.5,
                              color: isHighlighted ? AppTheme.primaryColor : AppTheme.textDark,
                              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                              backgroundColor: isHighlighted
                                  ? AppTheme.secondaryColor.withOpacity(0.3)
                                  : Colors.transparent,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Possible Conditions & Diseases (from AI API)
            if (widget.consultation != null &&
                widget.consultation!.triageResult.possibleConditions.isNotEmpty) ...[
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: AppTheme.borderRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.biotech_outlined, color: AppTheme.primaryColor, size: 22),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'সম্ভাব্য রোগ ও জটিলতা (Possible Conditions)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.consultation!.triageResult.possibleConditions.map((cond) {
                        final isHighProb = cond.probability.contains('উচ্চ') || cond.probability.toLowerCase().contains('high');
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isHighProb ? Colors.red.shade50.withOpacity(0.5) : AppTheme.accentColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHighProb ? Colors.red.shade200 : AppTheme.primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      cond.condition,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isHighProb ? AppTheme.dangerColor : AppTheme.warningColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cond.probability,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (cond.description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  cond.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textLight,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 4. Primary Medical Advice
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: AppTheme.borderRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.medical_services_outlined, color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'জরুরি প্রাথমিক করণীয় ও পরামর্শ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (widget.consultation != null && widget.consultation!.triageResult.primaryAdvice.isNotEmpty) ...[
                      ...widget.consultation!.triageResult.primaryAdvice.map((advice) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.successColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  advice,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      Text(
                        widget.result.adviceBn,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Warning Signs (বিপদ সংকেত)
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.red.shade100, width: 1.2),
                borderRadius: AppTheme.borderRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.report_problem_outlined, color: AppTheme.dangerColor, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'বিপদ সংকেত (Warning Signs)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.dangerColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (widget.consultation != null && widget.consultation!.triageResult.warningSigns.isNotEmpty) ...[
                      ...widget.consultation!.triageResult.warningSigns.map((warning) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning, size: 16, color: AppTheme.dangerColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  warning,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      Text(
                        widget.result.firstAidBn,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Smart QR Code Card
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                borderRadius: AppTheme.borderRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ডাক্তারের জন্য স্মার্ট কিউআর কোড',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                'ডাটাবেজে সংরক্ষিত | স্ক্যান করে তথ্য দেখা যাবে',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text(
                      'হাসপাতালে গিয়ে ডাক্তারকে এই কিউআর কোডটি স্ক্যান করতে বলুন। ডাক্তার আপনার বয়স, ডায়াবেটিস, উচ্চ রক্তচাপ, রোগের লক্ষণ ও এআই ট্রায়াজের সব তথ্য তাৎক্ষণিক পেয়ে যাবেন।',
                      style: TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _showFullscreenQr,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: _patientRecord.toQrPayload(),
                                version: QrVersions.auto,
                                size: 160.0,
                                gapless: false,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: AppTheme.primaryColor,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF1D3557),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in, size: 14, color: AppTheme.textLight),
                                  SizedBox(width: 4),
                                  Text(
                                    'বড় করে দেখতে স্পর্শ করুন',
                                    style: TextStyle(fontSize: 10, color: AppTheme.textLight),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showFullscreenQr,
                            icon: const Icon(Icons.fullscreen, size: 18),
                            label: const Text('বড় কিউআর', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SavedRecordsScreen()),
                              );
                            },
                            icon: const Icon(Icons.folder_shared_outlined, size: 18),
                            label: const Text('সংরক্ষিত হিস্ট্রি', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              backgroundColor: AppTheme.secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Triage Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('হোম স্ক্রিনে ফিরে যান'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('আবার পরীক্ষা করুন'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null ? color.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color != null ? color.withOpacity(0.3) : AppTheme.primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
