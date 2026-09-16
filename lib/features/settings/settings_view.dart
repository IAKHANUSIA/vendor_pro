import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/firm.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/services/license_service.dart';

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

  late TextEditingController _cloudUrlController;
  late TextEditingController _cloudKeyController;

  @override
  void initState() {
    super.initState();
    final db = DatabaseService.instance;
    final firm = ref.read(firmProvider);
    _nameController = TextEditingController(text: firm.name);
    _ownerController = TextEditingController(text: firm.ownerName);
    _phoneController = TextEditingController(text: firm.phone);
    _addressController = TextEditingController(text: firm.address);
    _upiController = TextEditingController(text: firm.upiId);
    _notesController = TextEditingController(text: firm.billNotes);

    _cloudUrlController = TextEditingController(text: db.cloudUrl);
    _cloudKeyController = TextEditingController(text: db.cloudKey);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _upiController.dispose();
    _notesController.dispose();
    _cloudUrlController.dispose();
    _cloudKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;

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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings, color: AppColors.primaryTeal, size: 26),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'એજન્સી સેટિંગ્સ, ક્લાઉડ સિંક અને લાયસન્સ',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    Text(
                      'ડેટા સ્ટોરેજ મોડ, Supabase લાઈવ સિંક્રોનાઇઝેશન અને એજન્સી પ્રોફાઇલ',
                      style: TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 1. Data Storage Mode & Cloud Sync (Top Priority)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cloud_sync, color: AppColors.primaryBlue, size: 22),
                          SizedBox(width: 10),
                          Text('૧. ડેટા સ્ટોરેજ મોડ (Offline vs Cloud Sync)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _performCloudSync,
                        icon: const Icon(Icons.sync, size: 18),
                        label: const Text('હમણાં સિંક કરો (Sync Now)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mode Selector Radios
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => db.storageMode = 'offline'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: db.storageMode == 'offline' ? AppColors.primaryBlue.withOpacity(0.15) : AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: db.storageMode == 'offline' ? AppColors.primaryBlue : AppColors.borderDark,
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'offline',
                                  groupValue: db.storageMode,
                                  onChanged: (v) => setState(() => db.storageMode = v!),
                                ),
                                const SizedBox(width: 8),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('💾 ૧૦૦% ઓફલાઇન મોડ (Offline)', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('ઝીરો ઇન્ટરનેટ - તમામ ડેટા તમારા ડિવાઇસ પર સુરક્ષિત',
                                        style: TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => db.storageMode = 'cloud'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: db.storageMode == 'cloud' ? AppColors.accentCyan.withOpacity(0.15) : AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: db.storageMode == 'cloud' ? AppColors.accentCyan : AppColors.borderDark,
                              ),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'cloud',
                                  groupValue: db.storageMode,
                                  onChanged: (v) => setState(() => db.storageMode = v!),
                                ),
                                const SizedBox(width: 8),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('☁️ ક્લાઉડ સિંક મોડ (Live Sync)', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Supabase સાથે સેકન્ડે-સેકન્ડે સુપર-એડમિન લાઈવ મોનિટરિંગ',
                                        style: TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Agency ID & Copy Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('તમારી Agency ID: ', style: TextStyle(color: AppColors.textMutedDark)),
                            Text(
                              db.agencyId,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: db.agencyId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Agency ID કોપી થઈ ગયો! 📋')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('કોપી કરો'),
                        ),
                      ],
                    ),
                  ),

                  if (db.storageMode == 'cloud') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cloudUrlController,
                            decoration: const InputDecoration(labelText: 'Supabase Project URL (દા.ત. https://xyz.supabase.co)'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _cloudKeyController,
                            decoration: const InputDecoration(labelText: 'Supabase anon / public API Key'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          db.cloudUrl = _cloudUrlController.text.trim();
                          db.cloudKey = _cloudKeyController.text.trim();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ક્લાઉડ કનેક્શન સેટિંગ્સ સાચવવામાં આવ્યા! ☁️')),
                          );
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('ક્લાઉડ સેટિંગ્સ સેવ કરો'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. SaaS Licensing Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.workspace_premium, color: AppColors.accentGold, size: 22),
                          SizedBox(width: 10),
                          Text('૨. લાયસન્સ અને સબ્સ્ક્રિપ્શન (SaaS Licensing)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showUnlockLicenseDialog(context),
                        icon: const Icon(Icons.key, size: 18),
                        label: const Text('નવી લાયસન્સ કી દાખલ કરો'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('પ્લાન (Active Plan)', style: TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                              const SizedBox(height: 4),
                              Text(db.licensePlan, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('વેલિડિટી મુદત (Valid Until)', style: TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                              const SizedBox(height: 4),
                              Text(db.licenseValidUntil, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('સ્ટેટસ (Status)', style: TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                              const SizedBox(height: 4),
                              Text(
                                db.licenseStatus == 'active' ? '🟢 સક્રિય (Active)' : '🔴 પૂર્ણ (Expired)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: db.licenseStatus == 'active' ? AppColors.successGreen : AppColors.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Firm Profile Details Form
            Form(
              key: _formKey,
              child: Container(
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
                        Text('૩. એજન્સી / પેઢીની વિગતો (Firm Profile)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            ),
            const SizedBox(height: 24),

            // 4. Offline Backup & Restore Card
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
                      Icon(Icons.backup, color: AppColors.primaryTeal, size: 20),
                      SizedBox(width: 8),
                      Text('૪. ૧૦૦% ઓફલાઇન ડેટા બેકઅપ (Data Backup & Restore)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'તમારો તમામ ગ્રાહક લિસ્ટ, પેપર દરો, ડેપો હિસાબ, બેંક ખાતાઓ, બિલિંગ અને વસૂલાતનો ડેટા તમારા ડિવાઇસ પર સંપૂર્ણ સુરક્ષિત છે.',
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
    );
  }

  void _saveFirmProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final db = DatabaseService.instance;
      db.firm = Firm(
        id: db.firm.id,
        name: _nameController.text.trim(),
        ownerName: _ownerController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        upiId: _upiController.text.trim(),
        billNotes: _notesController.text.trim(),
      );
      notifyDbChanged(ref);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('એજન્સી પ્રોફાઇલ સફળતાપૂર્વક સાચવવામાં આવી! ✅')),
      );
    }
  }

  Future<void> _performCloudSync() async {
    final db = DatabaseService.instance;
    final res = await CloudSyncService.instance.syncToCloud(db);
    notifyDbChanged(ref);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
    }
  }

  void _showUnlockLicenseDialog(BuildContext context) {
    final keyCtrl = TextEditingController();
    final db = DatabaseService.instance;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('🔑 નવી લાયસન્સ કી દાખલ કરો', style: TextStyle(color: AppColors.textLight)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agency ID: ${db.agencyId}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'લાયસન્સ કી (License Key)',
                hintText: 'VS-261031-BEBF-XXXX',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
          ElevatedButton(
            onPressed: () {
              final key = keyCtrl.text.trim();
              final res = LicenseService.verifyKey(key, db.agencyId);
              if (res.isValid) {
                db.licenseKey = key;
                db.licensePlan = res.plan;
                db.licenseValidUntil = res.expiryDate;
                db.licenseStatus = 'active';
                notifyDbChanged(ref);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🎉 લાયસન્સ સફળતાપૂર્વક અનલૉક થયું! મુદત: ${res.expiryDate} ✅')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('⚠️ ${res.message ?? "અમાન્ય કી"}'), backgroundColor: AppColors.errorRed),
                );
              }
            },
            child: const Text('અનલૉક કરો'),
          ),
        ],
      ),
    );
  }

  void _exportBackup() {
    final jsonStr = DatabaseService.instance.exportToJsonString();
    Share.share(jsonStr, subject: 'Vendor Pro Database Backup - ${DateTime.now().toIso8601String()}');
  }

  void _showImportDialog() {
    final jsonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('📥 બેકઅપ JSON પેસ્ટ કરો'),
        content: TextField(
          controller: jsonCtrl,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'અહીં JSON બેકઅપ કોડ પેસ્ટ કરો...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
          ElevatedButton(
            onPressed: () {
              DatabaseService.instance.importFromJsonString(jsonCtrl.text.trim());
              notifyDbChanged(ref);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('બેકઅપ સફળતાપૂર્વક રિસ્ટોર થયો! ✅')),
              );
            },
            child: const Text('રિસ્ટોર કરો'),
          ),
        ],
      ),
    );
  }
}
