import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'triage_wizard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'ডাক্তার কাছে (Dr. Kache)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome & Research Info Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppTheme.borderRadius,
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ডিজিটাল স্বাস্থ্যসেবা রূপান্তর',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'বাংলাদেশের গ্রামীণ মানুষের জন্য সঠিক হাসপাতালে ও ডাক্তারের কাছে যাওয়ার সহজ গাইডলাইন।',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Anti-Kobiraj / Quack Warning Banner
            Card(
              elevation: 0,
              color: AppTheme.dangerColor.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppTheme.dangerColor, width: 1.5),
                borderRadius: AppTheme.borderRadius,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor, size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ভুয়া কবিরাজ ও হাতুড়ে ডাক্তার থেকে সতর্ক থাকুন',
                            style: TextStyle(
                              color: AppTheme.dangerColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'অসুখ হলে ওঝা বা ভুয়া কবিরাজের কাছে গিয়ে সময় ও টাকা নষ্ট করবেন না। জটিল লক্ষণ দেখা দিলে সরাসরি হাসপাতালে চিকিৎসা নিন।',
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Huge Visual Start Button (Triage Wizard)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TriageWizardScreen()),
                );
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: AppTheme.borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: const Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.settings_voice_outlined,
                        size: 160,
                        color: Colors.white10,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.keyboard_voice,
                            color: Colors.white,
                            size: 40,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'লক্ষণ যাচাই করুন (শুরু করুন)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'মুখে বলুন বা লিখে আপনার রোগের কথা জানান',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 24,
                      top: 0,
                      bottom: 0,
                      child: Icon(
                        Icons.arrow_circle_right_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Emergency Helplines Section Title
            const Text(
              'জরুরি সরকারি যোগাযোগ (Helplines)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Government Helpline Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildHelplineCard(
                    context,
                    number: '১৬২৬৩',
                    label: 'স্বাস্থ্য বাতায়ন',
                    desc: '২৪ ঘণ্টা ফ্রি চিকিৎসকের পরামর্শ',
                    icon: Icons.phone_in_talk,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHelplineCard(
                    context,
                    number: '৯৯৯',
                    label: 'জাতীয় জরুরি সেবা',
                    desc: 'অ্যাম্বুলেন্স ও পুলিশ ও ফায়ার সার্ভিস',
                    icon: Icons.emergency,
                    color: AppTheme.dangerColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Research Metadata Project Card
            Card(
              color: Colors.white,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.school_outlined, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'University Research Project',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      'Topic: Digital Healthcare Transformation in Bangladesh: Opportunities, Challenges and recommendations.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textDark.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelplineCard(
    BuildContext context, {
    required String number,
    required String label,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
        borderRadius: AppTheme.borderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  radius: 18,
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
