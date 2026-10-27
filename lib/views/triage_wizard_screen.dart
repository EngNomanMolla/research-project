import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/consultation_model.dart';
import '../services/consultation_api_service.dart';
import '../services/triage_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class TriageWizardScreen extends StatefulWidget {
  const TriageWizardScreen({super.key});

  @override
  State<TriageWizardScreen> createState() => _TriageWizardScreenState();
}

class _TriageWizardScreenState extends State<TriageWizardScreen> {
  int _currentStep = 0;

  // Form Fields - Basic
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController(text: '35');
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '2');
  String _selectedGender = 'male'; // male, female, pregnant
  int _durationDays = 2;

  // Form Fields - Risk Factors & Medical History
  bool _hasDiabetes = false;
  bool _hasHypertension = false; // High BP
  bool _hasHeartDisease = false;
  bool _hasAsthma = false;
  bool _hasKidneyDisease = false;
  bool _hasCancer = false;
  bool _hasStroke = false;
  bool _hasAllergy = false;
  bool _hasLiverCirrhosis = false;
  bool _hasTb = false;
  bool _hasThyroidProblem = false;
  bool _isSmoker = false;
  bool _isAlcoholic = false;

  final TextEditingController _symptomController = TextEditingController();
  String _selectedPresetLabel = '';

  // Voice Recording State
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isRecording = false;
  bool _isAnalyzing = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  final List<double> _soundWaves = List.generate(15, (index) => 10.0);
  Timer? _waveTimer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (_isRecording) {
              _stopListening();
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('Speech error: $errorNotification');
          if (_isRecording) {
            _stopListening();
          }
        },
      );
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  // Demo Symptom Presets (Kept identical as requested)
  final List<Map<String, String>> _presets = [
    {
      'label': 'বুকে প্রচণ্ড ব্যথা ও শ্বাসকষ্ট',
      'text': 'আমার বুকে তীব্র ব্যথা হচ্ছে আর দম বন্ধ হয়ে আসছে, মনে হচ্ছে হার্ট অ্যাটাক হয়েছে।',
      'icon': '🫀'
    },
    {
      'label': 'গা হাত পা কেটে ভাঙা ও সাপে কাটা',
      'text': 'আমার পা পিছলে পড়ে মচকে বা ভেঙে গেছে এবং তীব্র ব্যথা হচ্ছে।',
      'icon': '🦴'
    },
    {
      'label': 'বাচ্চার জ্বর, বমি ও পাতলা পায়খানা',
      'text': 'আমার ছেলের দুই দিন ধরে অনেক জ্বর এবং ঘন ঘন বমি আর পাতলা পায়খানা হচ্ছে।',
      'icon': '🤒'
    },
    {
      'label': 'হালকা চুলকানি ও সর্দি',
      'text': 'আমার শরীরে এলার্জি বা হালকা সর্দি কাশি হয়েছে আর চুলকাচ্ছে।',
      'icon': '🧴'
    },
    {
      'label': 'প্রস্রাবে জ্বালাপোড়া ও কোমর ব্যথা',
      'text': 'আমার প্রস্রাব করতে গেলে প্রচণ্ড জ্বালাপোড়া হচ্ছে এবং কোমরে ব্যথা করছে।',
      'icon': '🚽'
    },
    {
      'label': 'কুকুরে কামড়ানো ও ক্ষত',
      'text': 'রাস্তায় একটি কুকুর আমার পায়ে কামড়ে দিয়েছে, ক্ষত থেকে রক্ত বের হচ্ছে।',
      'icon': '🐕'
    },
    {
      'label': 'চোখে প্রচণ্ড ব্যথা ও ঝাপসা দেখা',
      'text': 'আমার চোখে তীব্র ব্যথা হচ্ছে, চোখ লাল হয়ে গেছে এবং ঝাপসা দেখছি।',
      'icon': '👁️'
    },
    {
      'label': 'মাথায় আঘাত ও বমি ভাব',
      'text': 'মাথায় শক্ত কিছুর আঘাত লেগে রক্ত বের হচ্ছে এবং মাথা ঘুরছে ও বমি ভাব হচ্ছে।',
      'icon': '🤕'
    },
    {
      'label': 'গর্ভবতী মায়ের তলপেটে ব্যথা',
      'text': 'আমি একজন গর্ভবতী মা, আমার তলপেটে তীব্র ব্যথা হচ্ছে এবং রক্তপাত হচ্ছে।',
      'icon': '🤰'
    },
    {
      'label': 'শরীরের একপাশ অবশ ও মুখ বাঁকা',
      'text': 'আমার শরীরের ডান পাশ হঠাৎ অবশ হয়ে গেছে এবং মুখ একদিকে বেঁকে গেছে।',
      'icon': '🧠'
    },
    {
      'label': 'সড়ক দুর্ঘটনা ও অতিরিক্ত রক্তক্ষরণ',
      'text': 'সড়ক দুর্ঘটনায় হাত-পা কেটে ফিনকি দিয়ে রক্ত ঝরছে এবং রক্ত থামানো যাচ্ছে না।',
      'icon': '🚑'
    },
    {
      'label': 'সাপে কামড়ানো ও শরীর নীল হওয়া',
      'text': 'আমার পায়ে সাপে কামড়েছে, আক্রান্ত স্থান ফুলে গেছে এবং শরীর ঝিমঝিম করছে।',
      'icon': '🐍'
    },
    {
      'label': 'কোমর ও হাঁটুতে বাতের ব্যথা',
      'text': 'আমার দীর্ঘদিন ধরে হাঁটু ও কোমরে বাতের ব্যথা হচ্ছে, যার কারণে হাঁটতে কষ্ট হয়।',
      'icon': '🦽'
    },
    {
      'label': 'শিশুর পেটে কৃমি ও পেট ফাঁপা',
      'text': 'আমার বাচ্চার পেটে অনেক কৃমি হয়েছে, পেট ফাঁপা এবং বাচ্চা খেতে চাচ্ছে না।',
      'icon': '👶'
    },
    {
      'label': 'খোসপাঁচড়া ও চুলকানি',
      'text': 'আমার সারা শরীরে এলার্জির মতো খোসপাঁচড়া হয়ে প্রচণ্ড চুলকাচ্ছে।',
      'icon': '🧴'
    },
    {
      'label': 'কানে তীব্র ব্যথা ও পুঁজ পড়া',
      'text': 'কয়েকদিন ধরে আমার কানে অনেক ব্যথা হচ্ছে এবং কান দিয়ে পুঁজ বের হচ্ছে।',
      'icon': '👂'
    },
    {
      'label': 'দাঁতে ব্যথা ও মাড়ি ফোলা',
      'text': 'দাঁতে প্রচণ্ড ব্যথা হচ্ছে এবং মাড়ি ফুলে গেছে, চিবিয়ে কিছু খাওয়া যাচ্ছে না।',
      'icon': '🦷'
    },
    {
      'label': 'সাধারণ সর্দি ও গলা ব্যথা',
      'text': 'আমার সর্দি লেগেছে, নাক দিয়ে পানি পড়ছে এবং গলায় খুসখুসে ব্যথা হচ্ছে।',
      'icon': '🤧'
    },
    {
      'label': 'বিষ বা কীটনাশক খাওয়া',
      'text': 'ভুলবশত ফসলের বিষ বা ক্ষতিকর কীটনাশক খেয়ে পেটে তীব্র জ্বালা ও ছটফটানি হচ্ছে।',
      'icon': '🧪'
    },
    {
      'label': 'জন্ডিস ও চোখ হলুদ হওয়া',
      'text': 'আমার চোখ এবং প্রস্রাব অতিরিক্ত হলুদ হয়ে গেছে, বমি বমি ভাব ও জ্বর জ্বর লাগছে।',
      'icon': '🟡'
    },
    {
      'label': 'হাঁপানির টান ও চরম শ্বাসকষ্ট',
      'text': 'আমার হাঁপানির টান উঠেছে, বুক চেপে আসছে এবং শ্বাস নিতে তীব্র কষ্ট হচ্ছে।',
      'icon': '🫁'
    },
    {
      'label': 'ডায়রিয়া ও পানিশূন্যতা',
      'text': 'ঘন ঘন পাতলা পায়খানা ও বমি হয়ে শরীর একদম নিস্তেজ হয়ে পড়েছে।',
      'icon': '🥤'
    },
    {
      'label': 'একজিমা বা খসখসে চর্মরোগ',
      'text': 'আমার হাতে গোল গোল হয়ে খসখসে চর্মরোগ হয়েছে এবং রস ঝরছে ও চুলকাচ্ছে।',
      'icon': '✋'
    },
    {
      'label': 'আগুনে বা গরম পানিতে পুড়ে যাওয়া',
      'text': 'রান্না করার সময় গরম তরকারি বা ফুটন্ত পানি পড়ে পিঠ ও হাত পুড়ে ছাল উঠে গেছে।',
      'icon': '🔥'
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _symptomController.dispose();
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    super.dispose();
  }

  void _startListening() async {
    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (!_speechEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('মাইক্রোফোন বা ভয়েস রিকগনিশন সেবা চালু করা যাচ্ছে না।'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
      _symptomController.clear();
      _selectedPresetLabel = '';
      _lastWords = '';
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordSeconds++;
      });
      if (_recordSeconds >= 20) {
        _stopListening();
      }
    });

    _waveTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      setState(() {
        for (int i = 0; i < _soundWaves.length; i++) {
          _soundWaves[i] = 10.0 + (50.0 * (i % 2 == 0 ? 0.3 : 0.8) * (1 + _recordSeconds % 3));
          if (_soundWaves[i] > 60) _soundWaves[i] = 20;
        }
      });
    });

    await _speechToText.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _lastWords = result.recognizedWords;
          _symptomController.text = _lastWords;
        });
      },
      listenOptions: SpeechListenOptions(
        localeId: 'bn_BD',
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  void _stopListening() async {
    _recordTimer?.cancel();
    _waveTimer?.cancel();

    await _speechToText.stop();

    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        if (_symptomController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('দুঃখিত, কোনো কণ্ঠস্বর শনাক্ত করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।'),
              backgroundColor: AppTheme.dangerColor,
            ),
          );
        } else {
          _currentStep = 2; // Jump to symptom review
        }
      });
    });
  }

  List<String> _extractSymptomsList(String text) {
    if (_selectedPresetLabel.isNotEmpty) {
      final parts = _selectedPresetLabel
          .split(RegExp(r'[,।\n]|(\s+ও\s+)|(\s+এবং\s+)'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts;
    }

    final raw = text
        .split(RegExp(r'[,।\n]|(\s+ও\s+)|(\s+এবং\s+)'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length >= 2)
        .toList();

    if (raw.isNotEmpty) {
      return raw.take(6).toList();
    }
    return [text.trim()];
  }

  Future<void> _submitTriage() async {
    final symptomText = _symptomController.text.trim();
    if (symptomText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে আপনার রোগের বিবরণ দিন বা বলুন।'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    final ageValue = int.tryParse(_ageController.text) ?? 35;
    final weightValue = double.tryParse(_weightController.text);
    final durationValue = int.tryParse(_durationController.text) ?? _durationDays;
    final symptomsList = _extractSymptomsList(symptomText);

    // Show stylish Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ডাঃ কাছে এআই ট্রায়াজ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'রোগীর বয়স, ডায়াবেটিস, উচ্চ রক্তচাপ ও লক্ষণসমূহ বিশ্লেষণ করা হচ্ছে...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_sync, size: 16, color: AppTheme.primaryColor),
                      SizedBox(width: 6),
                      Text(
                        'dev.learnwithnoman.com সার্ভারে সংযোগ',
                        style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Prepare API Request
    final request = ConsultationRequest(
      patientName: _nameController.text.trim(),
      age: ageValue,
      gender: _selectedGender,
      weight: weightValue,
      hasDiabetes: _hasDiabetes,
      hasHypertension: _hasHypertension,
      hasHeartDisease: _hasHeartDisease,
      hasAsthma: _hasAsthma,
      hasKidneyDisease: _hasKidneyDisease,
      hasCancer: _hasCancer,
      hasStroke: _hasStroke,
      hasAllergy: _hasAllergy,
      hasLiverCirrhosis: _hasLiverCirrhosis,
      hasTb: _hasTb,
      hasThyroidProblem: _hasThyroidProblem,
      isSmoker: _isSmoker,
      isAlcoholic: _isAlcoholic,
      symptoms: symptomsList,
      symptomDescription: symptomText,
      durationDays: durationValue,
    );

    try {
      final consultationResponse = await ConsultationApiService.createConsultation(request);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Also compute local fallback result for color/compatibility
      final fallbackResult = TriageService.analyzeSymptoms(
        symptomText,
        age: ageValue,
        gender: _selectedGender,
        isSmoker: _isSmoker,
        weight: weightValue,
        hasDiabetes: _hasDiabetes,
        hasHighBP: _hasHypertension,
        hasHeartDisease: _hasHeartDisease,
        hasAsthma: _hasAsthma,
        hasKidneyDisease: _hasKidneyDisease,
        hasCancer: _hasCancer,
        hasStroke: _hasStroke,
        hasAllergy: _hasAllergy,
        hasLiverCirrhosis: _hasLiverCirrhosis,
        hasTb: _hasTb,
        hasThyroidProblem: _hasThyroidProblem,
        isAlcoholic: _isAlcoholic,
        durationDays: durationValue,
      );

      // Navigate to Result Screen with live API consultation response!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            result: fallbackResult,
            consultation: consultationResponse,
            patientName: _nameController.text.trim(),
            symptoms: symptomText,
            age: ageValue,
            weight: weightValue,
            durationDays: durationValue,
            hasDiabetes: _hasDiabetes,
            hasHighBP: _hasHypertension,
            hasHeartDisease: _hasHeartDisease,
            hasAsthma: _hasAsthma,
            hasKidneyDisease: _hasKidneyDisease,
            hasCancer: _hasCancer,
            hasStroke: _hasStroke,
            hasAllergy: _hasAllergy,
            hasLiverCirrhosis: _hasLiverCirrhosis,
            hasTb: _hasTb,
            hasThyroidProblem: _hasThyroidProblem,
            isSmoker: _isSmoker,
            isAlcoholic: _isAlcoholic,
            gender: _selectedGender,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Consultation API call error: $e');
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show friendly fallback choice dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cloud_off, color: AppTheme.dangerColor),
              SizedBox(width: 8),
              Text('সার্ভার যোগাযোগে সমস্যা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$e',
                style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'ইন্টারনেট সংযোগ না থাকলেও আপনি তাৎক্ষণিক অফলাইন ট্রায়াজ ফলাফল দেখতে পারেন।',
                style: TextStyle(fontSize: 12, color: AppTheme.textLight, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _submitTriage(); // Retry
              },
              child: const Text('আবার চেষ্টা করুন'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Proceed with local rule-based analysis
                final fallbackResult = TriageService.analyzeSymptoms(
                  symptomText,
                  age: ageValue,
                  gender: _selectedGender,
                  isSmoker: _isSmoker,
                  weight: weightValue,
                  hasDiabetes: _hasDiabetes,
                  hasHighBP: _hasHypertension,
                  hasHeartDisease: _hasHeartDisease,
                  hasAsthma: _hasAsthma,
                  hasKidneyDisease: _hasKidneyDisease,
                  hasCancer: _hasCancer,
                  hasStroke: _hasStroke,
                  hasAllergy: _hasAllergy,
                  hasLiverCirrhosis: _hasLiverCirrhosis,
                  hasTb: _hasTb,
                  hasThyroidProblem: _hasThyroidProblem,
                  isAlcoholic: _isAlcoholic,
                  durationDays: durationValue,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(
                      result: fallbackResult,
                      consultation: null,
                      patientName: _nameController.text.trim(),
                      symptoms: symptomText,
                      age: ageValue,
                      weight: weightValue,
                      durationDays: durationValue,
                      hasDiabetes: _hasDiabetes,
                      hasHighBP: _hasHypertension,
                      hasHeartDisease: _hasHeartDisease,
                      hasAsthma: _hasAsthma,
                      hasKidneyDisease: _hasKidneyDisease,
                      hasCancer: _hasCancer,
                      hasStroke: _hasStroke,
                      hasAllergy: _hasAllergy,
                      hasLiverCirrhosis: _hasLiverCirrhosis,
                      hasTb: _hasTb,
                      hasThyroidProblem: _hasThyroidProblem,
                      isSmoker: _isSmoker,
                      isAlcoholic: _isAlcoholic,
                      gender: _selectedGender,
                    ),
                  ),
                );
              },
              child: const Text('অফলাইন রেজাল্ট দেখুন'),
            ),
          ],
        ),
      );
    }
  }

  void _resetAllRisks() {
    setState(() {
      _hasDiabetes = false;
      _hasHypertension = false;
      _hasHeartDisease = false;
      _hasAsthma = false;
      _hasKidneyDisease = false;
      _hasCancer = false;
      _hasStroke = false;
      _hasAllergy = false;
      _hasLiverCirrhosis = false;
      _hasTb = false;
      _hasThyroidProblem = false;
      _isSmoker = false;
      _isAlcoholic = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('লক্ষণ যাচাই করণ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Linear Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 6,
          ),
          const SizedBox(height: 10),

          // Steps Tracker Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepHeader(0, '১. রোগী ও স্বাস্থ্য তথ্য', active: _currentStep == 0),
                _buildStepHeader(1, '২. কথা বলুন', active: _currentStep == 1),
                _buildStepHeader(2, '৩. নিশ্চিত করুন', active: _currentStep == 2),
              ],
            ),
          ),
          const Divider(height: 25),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('পূর্বে যান'),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  onPressed: () {
                    if (_currentStep == 0) {
                      if (_nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('অনুগ্রহ করে রোগীর নাম লিখুন (বাধ্যতামূলক)।'),
                            backgroundColor: AppTheme.dangerColor,
                          ),
                        );
                        return;
                      }
                    }
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      _submitTriage();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: Text(_currentStep == 2 ? 'বিশ্লেষণ করুন' : 'পরবর্তী ধাপ'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(int index, String title, {required bool active}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: active ? AppTheme.primaryColor : Colors.grey.shade300,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? AppTheme.primaryColor : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildProfileStep();
      case 1:
        return _buildVoiceStep();
      case 2:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  // --- STEP 1: USER PROFILE & MEDICAL HISTORY ---
  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'রোগীর নাম লিখুন (বাধ্যতামূলক)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'উদাঃ করিম সাহেব',
            filled: true,
            fillColor: AppTheme.accentColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.15), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.15), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 25),

        const Text(
          'রোগীর বয়স কত? (বছর)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 10),

        // Age Selector Widget
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.4),
            borderRadius: AppTheme.borderRadius,
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Material(
                color: AppTheme.primaryColor,
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                child: InkWell(
                  onTap: () {
                    int current = int.tryParse(_ageController.text) ?? 35;
                    if (current > 1) {
                      setState(() => _ageController.text = (current - 1).toString());
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.remove, color: Colors.white, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 25),
              Container(
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 25),
              Material(
                color: AppTheme.primaryColor,
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                child: InkWell(
                  onTap: () {
                    int current = int.tryParse(_ageController.text) ?? 35;
                    if (current < 120) {
                      setState(() => _ageController.text = (current + 1).toString());
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Age presets
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [5, 12, 25, 45, 52, 65, 80].map((age) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('$age বছর'),
                  selected: _ageController.text == age.toString(),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _ageController.text = age.toString());
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                  backgroundColor: Colors.grey.shade100,
                  checkmarkColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: _ageController.text == age.toString() ? AppTheme.primaryColor : AppTheme.textDark,
                    fontWeight: _ageController.text == age.toString() ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 25),

        // Gender Selector
        const Text(
          'জেন্ডার সিলেক্ট করুন',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildVisualOptionCard(
                label: 'পুরুষ',
                desc: 'Male',
                icon: Icons.male,
                isSelected: _selectedGender == 'male',
                onTap: () => setState(() => _selectedGender = 'male'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildVisualOptionCard(
                label: 'নারী',
                desc: 'Female',
                icon: Icons.female,
                isSelected: _selectedGender == 'female',
                onTap: () => setState(() => _selectedGender = 'female'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildVisualOptionCard(
                label: 'গর্ভবতী মা',
                desc: 'Pregnant',
                icon: Icons.pregnant_woman,
                isSelected: _selectedGender == 'pregnant',
                onTap: () => setState(() => _selectedGender = 'pregnant'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),

        // Weight Field
        const Text(
          'রোগীর ওজন কত? (কেজি - ঐচ্ছিক)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'উদাঃ ৭২ (কেজি)',
            filled: true,
            fillColor: AppTheme.accentColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.15), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.15), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            prefixIcon: const Icon(Icons.monitor_weight_outlined, color: AppTheme.primaryColor),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 25),

        // Duration in Days Section (NEW: Duration Days)
        const Text(
          'লক্ষণ শুরুর সময়কাল / কত দিন ধরে লক্ষণ? (দিন)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppTheme.borderRadius,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: AppTheme.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'অসুস্থতার স্থায়িত্ব: $_durationDays দিন',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                        ),
                        const Text(
                          'লক্ষণ কত দিন ধরে চলছে তা ঝুঁকি মূল্যায়নে অত্যন্ত গুরুত্বপূর্ণ',
                          style: TextStyle(fontSize: 11, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [1, 2, 3, 5, 7, 10, 14, 30].map((days) {
                    final isSel = _durationDays == days;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('$days দিন'),
                        selected: isSel,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _durationDays = days;
                              _durationController.text = days.toString();
                            });
                          }
                        },
                        selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                        backgroundColor: Colors.grey.shade100,
                        checkmarkColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSel ? AppTheme.primaryColor : AppTheme.textDark,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),

        // Health Conditions & Risk Factors Card Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'পূর্ববর্তী রোগ ও স্বাস্থ্য ঝুঁকি',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                Text(
                  'প্রযোজ্য ক্ষেত্রে টিক/সুইচ অন করুন',
                  style: TextStyle(fontSize: 11, color: AppTheme.textLight),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _resetAllRisks,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('সব "না"', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 1. Major Chronic Conditions Card
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade200, width: 1),
            borderRadius: AppTheme.borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.healing, color: AppTheme.primaryColor, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'দীর্ঘমেয়াদী ও প্রধান রোগসমূহ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 10),
                _buildRiskSwitch(
                  title: 'ডায়াবেটিস (Diabetes)',
                  subtitle: 'রক্তে চিনির মাত্রা বেশি বা ইনসুলিন গ্রহণ করেন',
                  icon: Icons.bloodtype_outlined,
                  value: _hasDiabetes,
                  onChanged: (val) => setState(() => _hasDiabetes = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'উচ্চ রক্তচাপ (Hypertension / High BP)',
                  subtitle: 'হাই প্রেসারের ওষুধ খান বা প্রেসার বেশি থাকে',
                  icon: Icons.favorite_border,
                  value: _hasHypertension,
                  onChanged: (val) => setState(() => _hasHypertension = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'হৃদরোগ (Heart Disease)',
                  subtitle: 'হার্টের সমস্যা, ব্লক বা পূর্বে হার্ট অ্যাটাকের ইতিহাস',
                  icon: Icons.monitor_heart_outlined,
                  value: _hasHeartDisease,
                  onChanged: (val) => setState(() => _hasHeartDisease = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'হাঁপানি / অ্যাজমা (Asthma)',
                  subtitle: 'শ্বাসকষ্টের টান বা ইনহেলার ব্যবহার করতে হয়',
                  icon: Icons.air,
                  value: _hasAsthma,
                  onChanged: (val) => setState(() => _hasAsthma = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'কিডনি রোগ (Kidney Disease)',
                  subtitle: 'কিডনি সমস্যা বা ক্রিয়েটিনিন বেশি',
                  icon: Icons.water_drop_outlined,
                  value: _hasKidneyDisease,
                  onChanged: (val) => setState(() => _hasKidneyDisease = val),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Other Health Risks Card
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade200, width: 1),
            borderRadius: AppTheme.borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.medical_services_outlined, color: AppTheme.secondaryColor, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'অন্যান্য স্বাস্থ্য জটিলতা',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.secondaryColor),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 10),
                _buildRiskSwitch(
                  title: 'ব্রেন স্ট্রোক (Stroke)',
                  subtitle: 'পূর্বে শরীরের একপাশ অবশ বা স্ট্রোকের ইতিহাস',
                  icon: Icons.psychology_outlined,
                  value: _hasStroke,
                  onChanged: (val) => setState(() => _hasStroke = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'অ্যালার্জি (Allergy)',
                  subtitle: 'ওষুধ, খাবার বা ধুলাবালিতে তীব্র অ্যালার্জি',
                  icon: Icons.coronavirus_outlined,
                  value: _hasAllergy,
                  onChanged: (val) => setState(() => _hasAllergy = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'থাইরয়েড সমস্যা (Thyroid Problem)',
                  subtitle: 'থাইরয়েডের হরমোনের তারতম্য বা ওষুধ সেবন',
                  icon: Icons.healing_outlined,
                  value: _hasThyroidProblem,
                  onChanged: (val) => setState(() => _hasThyroidProblem = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'ক্যান্সার (Cancer)',
                  subtitle: 'ক্যান্সার বা টিউমারের ইতিহাস বা চিকিৎসা চলছে',
                  icon: Icons.shield_outlined,
                  value: _hasCancer,
                  onChanged: (val) => setState(() => _hasCancer = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'লিভার সিরোসিস (Liver Cirrhosis)',
                  subtitle: 'লিভারের দীর্ঘমেয়াদী জটিলতা বা ফ্যাটি লিভার',
                  icon: Icons.local_hospital_outlined,
                  value: _hasLiverCirrhosis,
                  onChanged: (val) => setState(() => _hasLiverCirrhosis = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'যক্ষ্মা / টিবি (Tuberculosis / TB)',
                  subtitle: 'পূর্বে যক্ষ্মার চিকিৎসা নিয়েছেন বা আক্রান্ত',
                  icon: Icons.sick_outlined,
                  value: _hasTb,
                  onChanged: (val) => setState(() => _hasTb = val),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Lifestyle & Habits Card
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade200, width: 1),
            borderRadius: AppTheme.borderRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: AppTheme.warningColor, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'জীবনযাপন ও অভ্যাস',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.warningColor),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 10),
                _buildRiskSwitch(
                  title: 'ধূমপান করেন? (Smoker)',
                  subtitle: 'সিগারেট, বিড়ি বা তামাক সেবনের অভ্যাস আছে',
                  icon: Icons.smoking_rooms,
                  value: _isSmoker,
                  onChanged: (val) => setState(() => _isSmoker = val),
                ),
                const Divider(height: 1),
                _buildRiskSwitch(
                  title: 'মদ্যপান করেন? (Alcoholic)',
                  subtitle: 'অ্যালকোহল বা মদ্যপানের অভ্যাস রয়েছে',
                  icon: Icons.local_bar_outlined,
                  value: _isAlcoholic,
                  onChanged: (val) => setState(() => _isAlcoholic = val),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRiskSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  icon,
                  color: value ? AppTheme.primaryColor : Colors.grey.shade500,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: value ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                          color: value ? AppTheme.primaryColor : AppTheme.textDark,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildVisualOptionCard({
    required String label,
    required String desc,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.6) : Colors.grey.shade200,
            width: isSelected ? 1.2 : 0.8,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
              ),
            ),
            Text(
              desc,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.7) : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 2: VOICE OR PRESET TEXT SELECTION ---
  Widget _buildVoiceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'আপনার রোগের বিবরণ দিন',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'মাইক্রোফোন চেপে ধরে বাংলা ভাষায় কথা বলুন, অথবা নিচে দেওয়া লক্ষণগুলো থেকে একটি নির্বাচন করুন।',
          style: TextStyle(fontSize: 12, color: AppTheme.textLight),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 25),

        // Recorder Widget Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade100),
            borderRadius: AppTheme.borderRadius,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                // Animated Soundwaves
                SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _soundWaves.map((h) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 4,
                        height: h,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'রেকর্ডিং হচ্ছে... 0:${_recordSeconds < 10 ? '0' : ''}$_recordSeconds/0:20',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _stopListening,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                  icon: const Icon(Icons.stop),
                  label: const Text('রেকর্ডিং বন্ধ করুন'),
                ),
              ] else if (_isAnalyzing) ...[
                const SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'আপনার কণ্ঠস্বর বিশ্লেষণ ও অনুবাদ করা হচ্ছে...',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ] else ...[
                // Idle Mic Button
                GestureDetector(
                  onTap: _startListening,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(Icons.mic, color: Colors.white, size: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'বলুন (Tap to Speak)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 15),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Presets Divider
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('অথবা নমুনা লক্ষণ নির্বাচন করুন (Demo)',
                  style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 15),

        // Preset List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _presets.length,
          itemBuilder: (context, index) {
            final item = _presets[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Text(item['icon']!, style: const TextStyle(fontSize: 24)),
                title: Text(item['label']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                subtitle: Text(item['text']!,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  setState(() {
                    _selectedPresetLabel = item['label']!;
                    _symptomController.text = item['text']!;
                    _currentStep = 2; // Forward to review
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // --- STEP 3: CONFIRM & SUBMIT ---
  Widget _buildReviewStep() {
    final activeRisks = <String>[];
    if (_hasDiabetes) activeRisks.add('ডায়াবেটিস');
    if (_hasHypertension) activeRisks.add('উচ্চ রক্তচাপ');
    if (_hasHeartDisease) activeRisks.add('হৃদরোগ');
    if (_hasAsthma) activeRisks.add('হাঁপানি/অ্যাজমা');
    if (_hasKidneyDisease) activeRisks.add('কিডনি রোগ');
    if (_hasStroke) activeRisks.add('স্ট্রোক');
    if (_hasCancer) activeRisks.add('ক্যান্সার');
    if (_hasAllergy) activeRisks.add('অ্যালার্জি');
    if (_hasThyroidProblem) activeRisks.add('থাইরয়েড');
    if (_hasLiverCirrhosis) activeRisks.add('লিভার সিরোসিস');
    if (_hasTb) activeRisks.add('যক্ষ্মা (TB)');
    if (_isSmoker) activeRisks.add('ধূমপায়ী');
    if (_isAlcoholic) activeRisks.add('মদ্যপান');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'আপনার লক্ষণ যাচাই করুন',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 4),
        const Text(
          'নিচে দেওয়া রোগের বিবরণটি প্রয়োজনে পরিবর্তন করে নিচের বাটনে ক্লিক করুন।',
          style: TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
        const SizedBox(height: 20),

        // Text Field Review
        TextField(
          controller: _symptomController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'এখানে আপনার রোগ বা অসুখের লক্ষণের কথা লিখুন...',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 20),

        // Details Summary Card
        Card(
          elevation: 0,
          color: AppTheme.accentColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'রোগীর প্রোফাইল ও ঝুঁকির সংক্ষেপ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSummaryBadge('নাম: ${_nameController.text.trim()}'),
                    _buildSummaryBadge('বয়স: ${_ageController.text} বছর'),
                    _buildSummaryBadge('স্থায়িত্ব: $_durationDays দিন'),
                    if (_weightController.text.trim().isNotEmpty)
                      _buildSummaryBadge('ওজন: ${_weightController.text.trim()} কেজি'),
                    _buildSummaryBadge(
                      'লিঙ্গ: ${_selectedGender == 'male' ? 'পুরুষ' : _selectedGender == 'female' ? 'নারী' : 'গর্ভবতী'}',
                    ),
                    if (activeRisks.isEmpty)
                      _buildSummaryBadge('পূর্ববর্তী রোগ: কোনোটিই নয়')
                    else
                      ...activeRisks.map((risk) => _buildSummaryBadge(risk, isAlert: true)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBadge(String label, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAlert ? AppTheme.primaryColor.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAlert ? AppTheme.primaryColor.withOpacity(0.4) : AppTheme.primaryColor.withOpacity(0.15),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isAlert ? AppTheme.primaryColor : AppTheme.textDark,
          fontWeight: isAlert ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
