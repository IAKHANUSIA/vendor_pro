import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/firm.dart';
import '../../core/providers/app_providers.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ownerController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _upiController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final firm = ref.read(firmProvider);
    _nameController = TextEditingController(text: firm.name);
    _ownerController = TextEditingController(text: firm.ownerName);
    _phoneController = TextEditingController(text: firm.phone);
    _addressController = TextEditingController(text: firm.address);
    _upiController = TextEditingController(text: firm.upiId);
    _notesController = TextEditingController(text: firm.billNotes);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _upiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings, color: AppColors.primaryTeal, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'એજન્સી સેટિંગ્સ અને બેકઅપ (Settings & Backup)',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    Text(
                      'એજન્સી પ્રોફાઇલ, UPI કલેક્શન આઇડી અને ૧૦૦% ઓફલાઇન ડેટા બેકઅપ',
                      style: TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form Content
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Firm Details Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.storefront, color: AppColors.accentGold, size: 20),
                            SizedBox(width: 8),
                            Text('એજન્સી / પેઢીની વિગતો (Firm Profile)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(labelText: 'એજન્સીનું નામ (Agency Name) *'),
                                validator: (v) => (v == null || v.isEmpty) ? 'નામ જરૂરી છે' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _ownerController,
                                decoration: const InputDecoration(labelText: 'માલિકનું નામ (Owner Name)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(labelText: 'સંપર્ક મોબાઈલ નંબર (Phone) *'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _upiController,
                                decoration: const InputDecoration(labelText: 'UPI આઈડી (QR કોડ અને ઓનલાઇન વસૂલાત માટે)', hintText: 'દા.ત. vendor@okaxis'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'દુકાન / ડેપોનું સરનામું (Address)'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'બિલ નીચે છાપવા માટેની ગુજરાતી નોંધ (Bill Footnote)',
                            hintText: 'દા.ત. મહેરબાની કરીને ૧૦ તારીખ પહેલા બિલ ભરી દેવું. આભાર!',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _saveFirmProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('પ્રોફાઇલ સાચવો (Save Profile)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. 100% Offline Backup & Restore Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cloud_sync, color: AppColors.primaryTeal, size: 20),
                            SizedBox(width: 8),
                            Text('૧૦૦% ઓફલાઇન ડેટા સુરક્ષા અને બેકઅપ (Data Backup & Restore)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'તમારો તમામ ગ્રાહક લિસ્ટ, પેપર દરો, ડેપો હિસાબ, બિલિંગ અને વસૂલાતનો ડેટા તમારા ડિવાઇસ પર સંપૂર્ણ સુરક્ષિત છે. તમે કોઈપણ સમયે તેનો JSON બેકઅપ ડાઉનલોડ કરી શકો છો અથવા નવો બેકઅપ રિસ્ટોર કરી શકો છો.',
                          style: TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _exportBackup,
                              icon: const Icon(Icons.download),
                              label: const Text('બેકઅપ એક્સપોર્ટ કરો (Export Backup JSON)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceDark,
                                foregroundColor: AppColors.accentGold,
                                side: const BorderSide(color: AppColors.accentGold),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showImportDialog,
                              icon: const Icon(Icons.upload),
                              label: const Text('બેકઅપ ઇમ્પોર્ટ કરો (Import Backup JSON)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceDark,
                                foregroundColor: AppColors.primaryTeal,
                                side: const BorderSide(color: AppColors.primaryTeal),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveFirmProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final db = ref.read(databaseProvider);
      db.firm = Firm(
        name: _nameController.text.trim(),
        ownerName: _ownerController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        upiId: _upiController.text.trim(),
        billNotes: _notesController.text.trim(),
      );
      notifyDbChanged(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('એજન્સી પ્રોફાઇલ સફળતાપૂર્વક સાચવવામાં આવી!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _exportBackup() {
    final db = ref.read(databaseProvider);
    final jsonString = db.exportToJsonString();
    Share.share(jsonString, subject: 'VendorPro_Backup_${DateTime.now().toIso8601String().split('T')[0]}.json');
  }

  void _showImportDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: AppColors.primaryTeal),
            SizedBox(width: 10),
            Text('JSON બેકઅપ રિસ્ટોર કરો'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('અગાઉ લીધેલ JSON બેકઅપ કોડ અહીં પેસ્ટ કરો:', style: TextStyle(fontSize: 13, color: AppColors.textMutedDark)),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '{\n  "firm": { ... },\n  "customers": [ ... ]\n}',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
          ElevatedButton.icon(
            onPressed: () {
              final jsonStr = textController.text.trim();
              if (jsonStr.isNotEmpty) {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                db.importFromJsonString(jsonStr);
                notifyDbChanged(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('બેકઅપ ડેટા સફળતાપૂર્વક રિસ્ટોર થઈ ગયો!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('રિસ્ટોર કરો'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
          ),
        ],
      ),
    );
  }
}
