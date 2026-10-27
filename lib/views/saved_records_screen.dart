import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/patient_record.dart';
import '../services/records_db_service.dart';
import '../theme/app_theme.dart';
import 'triage_wizard_screen.dart';

class SavedRecordsScreen extends StatefulWidget {
  const SavedRecordsScreen({super.key});

  @override
  State<SavedRecordsScreen> createState() => _SavedRecordsScreenState();
}

class _SavedRecordsScreenState extends State<SavedRecordsScreen> {
  List<PatientRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final list = await RecordsDbService.getRecords();
    setState(() {
      _records = list;
      _isLoading = false;
    });
  }

  Future<void> _addSampleRecord() async {
    setState(() => _isLoading = true);
    await RecordsDbService.createSampleDemoRecord();
    await _loadRecords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('নমুনা কিউআর রেকর্ড সফলভাবে তৈরি ও সংরক্ষিত হয়েছে!'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDelete(PatientRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppTheme.dangerColor),
            SizedBox(width: 8),
            Text('রেকর্ড মুছবেন?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'আপনি কি "${record.patientName.isEmpty ? "রোগীর রেকর্ড" : record.patientName}" এর সংরক্ষিত কিউআর কোড ও স্বাস্থ্য তথ্য মুছে ফেলতে চান?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না, বাতিল', style: TextStyle(color: AppTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ, মুছুন'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await RecordsDbService.deleteRecord(record.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('রেকর্ডটি সফলভাবে মুছে ফেলা হয়েছে'),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
        _loadRecords();
      }
    }
  }

  void _showQrModal(PatientRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QrDetailBottomSheet(record: record),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'emergency':
        return AppTheme.dangerColor;
      case 'high':
        return const Color(0xFFE29578);
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
      default:
        return AppTheme.successColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'সংরক্ষিত কিউআর ও হিস্ট্রি',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'নমুনা কিউআর তৈরি করুন',
            onPressed: _addSampleRecord,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'রিফ্রেশ করুন',
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return _buildRecordCard(record);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 72,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'কোনো সংরক্ষিত কিউআর কোড নেই',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'আপনি যখনই লক্ষণ যাচাই সম্পন্ন করবেন, আপনার সমস্ত পরামর্শ ও স্মার্ট কিউআর কোড এখানে স্বয়ংক্রিয়ভাবে সংরক্ষিত থাকবে।',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textLight, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TriageWizardScreen()),
                );
                _loadRecords();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('নতুন লক্ষণ যাচাই ও কিউআর তৈরি করুন'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addSampleRecord,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('একটি নমুনা কিউআর যোগ করুন (টেস্ট)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(PatientRecord record) {
    final urgencyColor = _getUrgencyColor(record.urgency);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: urgencyColor.withOpacity(0.3), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showQrModal(record),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name & Urgency badge + Delete button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.patientName.isEmpty ? 'অজ্ঞাত রোগী' : record.patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          record.formattedDate,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: urgencyColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      record.urgencyDisplayBn,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: urgencyColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor, size: 22),
                    tooltip: 'মুছে ফেলুন',
                    onPressed: () => _confirmDelete(record),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Patient info chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildMiniChip('${record.age} বছর', Icons.calendar_today),
                  _buildMiniChip(record.genderDisplayBn, Icons.person),
                  _buildMiniChip('${record.durationDays} দিন', Icons.timer_outlined),
                  if (record.weight != null)
                    _buildMiniChip('${record.weight} কেজি', Icons.monitor_weight),
                  if (record.trackingCode != null && record.trackingCode!.isNotEmpty)
                    _buildMiniChip(record.trackingCode!, Icons.verified, color: AppTheme.primaryColor),
                  if (record.hasDiabetes)
                    _buildMiniChip('ডায়াবেটিস', Icons.bloodtype, color: AppTheme.dangerColor),
                  if (record.hasHighBP)
                    _buildMiniChip('উচ্চ রক্তচাপ', Icons.favorite, color: AppTheme.dangerColor),
                  if (record.hasHeartDisease)
                    _buildMiniChip('হৃদরোগ', Icons.monitor_heart, color: AppTheme.dangerColor),
                  if (record.hasAsthma)
                    _buildMiniChip('হাঁপানি', Icons.air, color: AppTheme.warningColor),
                  if (record.hasKidneyDisease)
                    _buildMiniChip('কিডনি', Icons.water_drop, color: AppTheme.warningColor),
                  if (record.hasStroke)
                    _buildMiniChip('স্ট্রোক', Icons.psychology, color: AppTheme.dangerColor),
                  if (record.hasCancer)
                    _buildMiniChip('ক্যান্সার', Icons.medical_services, color: AppTheme.dangerColor),
                  if (record.hasAllergy)
                    _buildMiniChip('অ্যালার্জি', Icons.coronavirus, color: AppTheme.warningColor),
                  if (record.hasThyroidProblem)
                    _buildMiniChip('থাইরয়েড', Icons.healing, color: AppTheme.warningColor),
                  if (record.hasLiverCirrhosis)
                    _buildMiniChip('লিভার', Icons.local_hospital, color: AppTheme.dangerColor),
                  if (record.hasTb)
                    _buildMiniChip('যক্ষ্মা', Icons.sick, color: AppTheme.dangerColor),
                  if (record.isSmoker)
                    _buildMiniChip('ধূমপায়ী', Icons.smoking_rooms, color: AppTheme.warningColor),
                  if (record.isAlcoholic)
                    _buildMiniChip('মদ্যপান', Icons.local_bar, color: AppTheme.warningColor),
                ],
              ),
              const SizedBox(height: 10),

              // Symptoms Snippet
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'উপসর্গ / লক্ষণ:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.symptoms,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Recommended Facility & QR Button Row
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.local_hospital, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            record.careLevelBn,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showQrModal(record),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('কিউআর কোড', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color ?? AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color ?? AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrDetailBottomSheet extends StatelessWidget {
  final PatientRecord record;

  const _QrDetailBottomSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag indicator handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'ডাক্তারের জন্য স্মার্ট কিউআর কোড',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // High Contrast QR Code Display Container
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: record.toQrPayload(),
                      version: QrVersions.auto,
                      size: 220.0,
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
                    const SizedBox(height: 8),
                    const Text(
                      'ডাক্তারকে এই কিউআর কোডটি স্ক্যান করতে বলুন',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Patient summary box inside dialog
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'রোগী: ${record.patientName.isEmpty ? "উল্লেখ নেই" : record.patientName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                      ),
                      Text(
                        record.formattedDate,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'প্রস্তাবিত সেবা: ${record.careLevelBn}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'লক্ষণ: ${record.symptoms}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বন্ধ করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
