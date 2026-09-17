import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/salesman.dart';
import '../../core/models/collection_man.dart';
import '../../core/providers/app_providers.dart';
import 'pin_auth_dialog.dart';

class RoleSwitcherDialog extends ConsumerStatefulWidget {
  const RoleSwitcherDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const RoleSwitcherDialog(),
    );
  }

  @override
  ConsumerState<RoleSwitcherDialog> createState() => _RoleSwitcherDialogState();
}

class _RoleSwitcherDialogState extends ConsumerState<RoleSwitcherDialog> {
  int? _selectedSalesmanId;
  int? _selectedCollectionManId;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final firm = ref.watch(firmProvider);
    final salesmen = ref.watch(salesmenProvider).where((s) => s.isActive).toList();
    final collectionMen = ref.watch(collectionMenProvider).where((c) => c.isActive).toList();

    return AlertDialog(
      backgroundColor: AppColors.bgDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderDark),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.accentGold, size: 24),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'રોલ બદલો (Switch User Role)',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'ઓનર કંટ્રોલ અથવા સ્ટાફ પોર્ટલમાં લૉગિન કરો',
                            style: TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Current Role Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('હાલનો સક્રિય રોલ:', style: TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.successGreen.withOpacity(0.4)),
                      ),
                      child: Text(
                        session.displayName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Role Card 1: Admin / Owner
              _buildRoleCard(
                context,
                title: '👑 એડમિન / ઓનર (Admin Mode)',
                subtitle: 'સંપૂર્ણ વહીવટી કંટ્રોલ, બિલિંગ, એકાઉન્ટ્સ, પેપર્સ અને સેટિંગ્સ',
                badgeText: session.isAdmin ? '✓ સક્રિય (Active)' : 'Owner PIN જરૂરી',
                badgeColor: session.isAdmin ? AppColors.successGreen : AppColors.accentGold,
                isActive: session.isAdmin,
                icon: Icons.admin_panel_settings,
                color: AppColors.primaryTeal,
                onTap: () async {
                  if (session.isAdmin) {
                    Navigator.pop(context);
                    return;
                  }
                  final verified = await PinAuthDialog.verify(
                    context,
                    title: '🔐 Owner Master PIN',
                    subtitle: 'એડમિન રોલમાં સ્વિચ કરવા માટે ૪ થી ૮ આંકડાનો Master PIN નાખો:',
                    expectedPin: firm.ownerPin.isNotEmpty ? firm.ownerPin : '1111',
                    roleBadge: '👑 એડમિન ઓથેન્ટિકેશન',
                  );
                  if (verified && context.mounted) {
                    ref.read(authSessionProvider.notifier).setAdmin();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('👑 એડમિન રોલ સફળતાપૂર્વક અનલૉક થયો!'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // Role Card 2: Salesman / Delivery
              _buildRoleCard(
                context,
                title: '🚴‍♂️ વિતરક પોર્ટલ (Salesman Mode)',
                subtitle: 'માત્ર સવારની લાઇન ડિલિવરી શીટ, પેપર કાઉન્ટ્સ અને ગ્રાહક ચેકલિસ્ટ',
                badgeText: session.isSalesman ? '✓ સક્રિય (${session.activeSalesman?.name})' : 'Salesman PIN',
                badgeColor: session.isSalesman ? AppColors.successGreen : AppColors.primaryTeal,
                isActive: session.isSalesman,
                icon: Icons.delivery_dining,
                color: AppColors.primaryBlue,
                customChild: session.isSalesman
                    ? null
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedSalesmanId,
                            hint: const Text('વિતરક પસંદ કરો (Select Salesman)', style: TextStyle(fontSize: 12)),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            dropdownColor: AppColors.cardDark,
                            items: salesmen.map((s) {
                              return DropdownMenuItem<int>(
                                value: s.id,
                                child: Text('${s.name} (${s.mobile})', style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedSalesmanId = val),
                          ),
                        ],
                      ),
                onTap: () async {
                  if (session.isSalesman) {
                    Navigator.pop(context);
                    return;
                  }
                  if (salesmen.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('કોઈ સક્રિય સેલ્સમેન ઉપલબ્ધ નથી. પહેલા સ્ટાફ માસ્ટરમાં ઉમેરો.')),
                    );
                    return;
                  }
                  final targetSalesman = salesmen.cast<Salesman?>().firstWhere(
                        (s) => s?.id == (_selectedSalesmanId ?? salesmen.first.id),
                        orElse: () => salesmen.first,
                      );
                  if (targetSalesman == null) return;

                  final verified = await PinAuthDialog.verify(
                    context,
                    title: '🚴‍♂️ ${targetSalesman.name} - PIN',
                    subtitle: 'આ વિતરકના પોર્ટલમાં લૉગિન કરવા માટે ૪ થી ૮ આંકડાનો PIN નાખો:',
                    expectedPin: targetSalesman.pin.isNotEmpty ? targetSalesman.pin : '1111',
                    roleBadge: '🚴‍♂️ વિતરક લૉગિન',
                  );
                  if (verified && context.mounted) {
                    ref.read(authSessionProvider.notifier).setSalesman(targetSalesman);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🚴‍♂️ ${targetSalesman.name} પોર્ટલ સક્રિય થયું!'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // Role Card 3: Collection Staff
              _buildRoleCard(
                context,
                title: '💼 ઉઘરાણી સ્ટાફ પોર્ટલ (Collection Mode)',
                subtitle: 'લાઇન વાઇઝ ઉઘરાણી લિસ્ટ, સ્પોટ કલેક્શન પાવતી, લાઈવ UPI QR અને WhatsApp રસીદ',
                badgeText: session.isCollection ? '✓ સક્રિય (${session.activeCollectionMan?.name})' : 'Staff PIN',
                badgeColor: session.isCollection ? AppColors.successGreen : AppColors.accentGold,
                isActive: session.isCollection,
                icon: Icons.work_outline,
                color: AppColors.accentGold,
                customChild: session.isCollection
                    ? null
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedCollectionManId,
                            hint: const Text('કલેક્શન સ્ટાફ પસંદ કરો (Select Staff)', style: TextStyle(fontSize: 12)),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            dropdownColor: AppColors.cardDark,
                            items: collectionMen.map((c) {
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Text('${c.name} (${c.mobile})', style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedCollectionManId = val),
                          ),
                        ],
                      ),
                onTap: () async {
                  if (session.isCollection) {
                    Navigator.pop(context);
                    return;
                  }
                  if (collectionMen.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('કોઈ સક્રિય કલેક્શન સ્ટાફ ઉપલબ્ધ નથી. પહેલા સ્ટાફ માસ્ટરમાં ઉમેરો.')),
                    );
                    return;
                  }
                  final targetColMan = collectionMen.cast<CollectionMan?>().firstWhere(
                        (c) => c?.id == (_selectedCollectionManId ?? collectionMen.first.id),
                        orElse: () => collectionMen.first,
                      );
                  if (targetColMan == null) return;

                  final verified = await PinAuthDialog.verify(
                    context,
                    title: '💼 ${targetColMan.name} - PIN',
                    subtitle: 'આ કલેક્શન સ્ટાફ પોર્ટલમાં લૉગિન કરવા માટે ૪ થી ૮ આંકડાનો PIN નાખો:',
                    expectedPin: targetColMan.pin.isNotEmpty ? targetColMan.pin : '1111',
                    roleBadge: '💼 ઉઘરાણી સ્ટાફ લૉગિન',
                  );
                  if (verified && context.mounted) {
                    ref.read(authSessionProvider.notifier).setCollection(targetColMan);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('💼 ${targetColMan.name} ઉઘરાણી પોર્ટલ સક્રિય થયું!'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required bool isActive,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? customChild,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : AppColors.cardBorderDark,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? color : AppColors.textLight)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badgeColor.withOpacity(0.4)),
                  ),
                  child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
            if (customChild != null) customChild,
          ],
        ),
      ),
    );
  }
}
