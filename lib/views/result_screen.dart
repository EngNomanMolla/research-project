import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/triage_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Prepare words for simulated TTS word-by-word highlighting
    _audioWords = widget.result.audioScriptBn.split(' ');
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    super.dispose();
  }

  void _toggleAudioPlayback() {
    if (_isPlayingAudio) {
      _audioTimer?.cancel();
      setState(() {
        _isPlayingAudio = false;
        _highlightedWordIndex = -1;
      });
    } else {
      setState(() {
        _isPlayingAudio = true;
        _highlightedWordIndex = 0;
      });

      // Highlight next words slowly to simulate speaking cadence
      _audioTimer = Timer.periodic(const Duration(milliseconds: 380), (timer) {
        if (!mounted) return;
        setState(() {
          if (_highlightedWordIndex < _audioWords.length - 1) {
            _highlightedWordIndex++;
          } else {
            _audioTimer?.cancel();
            _isPlayingAudio = false;
            _highlightedWordIndex = -1;
          }
        });
      });
    }
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient details card
            Text(
              'রোগী: ${widget.patientName} এর জন্য পরামর্শ',
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

            // 2. TTS Voice Instruction Box (Low-literacy focus)
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

            // 3. Kobiraj Warning Box
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

            // 4. First Aid Tips
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
