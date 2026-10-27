import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/patient_record.dart';
import '../services/records_db_service.dart';
import '../services/triage_service.dart';
import '../theme/app_theme.dart';
import 'saved_records_screen.dart';

class ResultScreen extends StatefulWidget {
  final TriageResult result;
  final String patientName;
  final String symptoms;
  final int age;
  final double? weight;
  final bool hasDiabetes;
  final bool hasHighBP;
  final bool isSmoker;
  final String gender;

  const ResultScreen({
    super.key,
    required this.result,
    required this.patientName,
    required this.symptoms,
    required this.age,
    required this.weight,
    required this.hasDiabetes,
    required this.hasHighBP,
    required this.isSmoker,
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

  @override
  void initState() {
    super.initState();
    // Prepare words for simulated TTS word-by-word highlighting
    _audioWords = widget.result.audioScriptBn.split(' ');

    // Construct PatientRecord model
    _patientRecord = PatientRecord(
      id: 'REC-${DateTime.now().millisecondsSinceEpoch}',
      patientName: widget.patientName,
      age: widget.age,
      gender: widget.gender,
      weight: widget.weight,
      hasDiabetes: widget.hasDiabetes,
      hasHighBP: widget.hasHighBP,
      isSmoker: widget.isSmoker,
      symptoms: widget.symptoms,
      urgency: _getUrgencyKey(widget.result.urgency),
      careLevelBn: widget.result.careLevelBn,
      careLevelEn: widget.result.careLevelEn,
      adviceBn: widget.result.adviceBn,
      firstAidBn: widget.result.firstAidBn,
      createdAt: DateTime.now(),
    );

    // Save record to local database automatically
    _saveRecordToLocalDb();

    // Initialize Text to speech
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      // Configure Bengali voice
      await _flutterTts.setLanguage('bn-BD');
      await _flutterTts.setSpeechRate(0.45); // comfortable rate
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

      // Synchronize visual highlighting
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

      // Speak aloud in Bengali
      try {
        final res = await _flutterTts.speak(widget.result.audioScriptBn);
        debugPrint('TTS Speak result: $res');
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

  @override
  Widget build(BuildContext context) {
    // Dynamic text color based on risk levels for maximum contrast
    final isEmergency = widget.result.urgency == UrgencyLevel.emergency || widget.result.urgency == UrgencyLevel.high;
    final textColor = isEmergency ? Colors.white : AppTheme.textDark;

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
            // Patient details card
            Text(
              'রোগী: ${widget.patientName.isEmpty ? "অজ্ঞাত" : widget.patientName} এর জন্য পরামর্শ',
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
                _buildDetailChip(
                  widget.gender == 'male' 
                      ? 'লিঙ্গ: পুরুষ' 
                      : widget.gender == 'female' 
                          ? 'লিঙ্গ: নারী' 
                          : 'লিঙ্গ: গর্ভবতী মা',
                  Icons.person,
                ),
                if (widget.isSmoker)
                  _buildDetailChip('ধূমপায়ী', Icons.smoking_rooms, color: AppTheme.warningColor),
                if (widget.hasDiabetes)
                  _buildDetailChip('ডায়াবেটিস', Icons.bloodtype, color: AppTheme.dangerColor),
                if (widget.hasHighBP)
                  _buildDetailChip('উচ্চ রক্তচাপ', Icons.favorite, color: AppTheme.dangerColor),
              ],
            ),
            const SizedBox(height: 15),

            // 1. Referral Location Card (Primary Output)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.result.color,
                borderRadius: AppTheme.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: widget.result.color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgency badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getUrgencyTextBn(widget.result.urgency),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'আপনার যাওয়া উচিত:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.result.careLevelBn,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                
                  const Divider(height: 25, color: Colors.white24),
                  Text(
                    widget.result.descriptionBn,
                    style: TextStyle(
                      fontSize: 13,
                      color: isEmergency ? Colors.white.withOpacity(0.9) : AppTheme.textDark.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Smart QR Code Card (Saved automatically to local storage)
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
                                style: TextStyle(fontSize: 11, color: AppTheme.successColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text(
                      'হাসপাতালে গিয়ে ডাক্তারকে এই কিউআর কোডটি স্ক্যান করতে বলুন। ডাক্তার আপনার বয়স, ডায়াবেটিস হিস্ট্রি ও উপসর্গের সব তথ্য এক ক্লিকেই পেয়ে যাবেন।',
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
            const SizedBox(height: 20),

            // 3. TTS Voice Instruction Box (Low-literacy focus)
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
                                'প্রেসক্রিপশন অডিও শুনুন',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                'শুনতে স্পিকার বাটনে চাপুন (অডিও গাইড)',
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
                            width: 30,
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
                              backgroundColor: isHighlighted ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.transparent,
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

            // 4. Kobiraj Warning Box
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
                        Icon(Icons.gavel, color: AppTheme.dangerColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'সতর্কতা ও ভীতি দূরীকরণ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.dangerColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      widget.result.adviceBn,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDark,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. First Aid Tips
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
                        Icon(Icons.medical_services_outlined, color: AppTheme.successColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'তাত্ক্ষণিক করণীয় ও প্রাথমিক পরামর্শ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      widget.result.firstAidBn,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDark,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Triage Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                // Return to home screen
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('হোম স্ক্রিনে ফিরে যান'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Restart triage wizard
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

  String _getUrgencyTextBn(UrgencyLevel urgency) {
    switch (urgency) {
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
