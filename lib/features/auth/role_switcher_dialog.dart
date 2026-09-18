import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
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

class _RoleSwitcherDialogState extends ConsumerState<RoleSwitcherDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();
  bool _obscurePin = true;
  String? _loginError;

  int? _selectedSalesmanId;
  int? _selectedCollectionManId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _handleMobileLogin() {
    setState(() => _loginError = null);
    final phone = _mobileCtrl.text.replaceAll(RegExp(r'\s+'), '').trim();
    final pin = _pinCtrl.text.trim();

    if (phone.isEmpty) {
      setState(() => _loginError = '⚠️ કૃપા કરીને મોબાઇલ નંબર દાખલ કરો.');
      return;
    }
    if (pin.isEmpty) {
      setState(() => _loginError = '⚠️ કૃપા કરીને ૪ થી ૮ આંકડાનો લૉગિન PIN દાખલ કરો.');
      return;
    }

    final db = DatabaseService.instance;
    final firm = db.firm;

    // 1. Check Owner / Admin login by Phone or Master PIN
    final isOwnerPhone = firm.phone.replaceAll(RegExp(r'\s+'), '').trim() == phone;
    final isMasterPin = (firm.ownerPin.isNotEmpty ? firm.ownerPin : '1111') == pin;
    if (isOwnerPhone && isMasterPin) {
      ref.read(authSessionProvider.notifier).setAdmin();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👑 એડમિન મોડ સફળતાપૂર્વક અનલૉક થયો!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      return;
    }

    // 2. Look up all Salesmen & CollectionMen matching this phone
    final sMatches = db.salesmen.where((s) => s.mobile.replaceAll(RegExp(r'\s+'), '').trim() == phone).toList();
    final cMatches = db.collectionMen.where((c) => c.mobile.replaceAll(RegExp(r'\s+'), '').trim() == phone).toList();

    if (sMatches.isEmpty && cMatches.isEmpty) {
      setState(() => _loginError = '❌ આ મોબાઇલ નંબર સિસ્ટમમાં નોંધાયેલ નથી. કૃપા કરીને એડમિનનો સંપર્ક કરો.');
      return;
    }

    // 3. Check for Active vs Inactive staff
    final activeS = sMatches.where((s) => s.isActive).toList();
    final activeC = cMatches.where((c) => c.isActive).toList();

    if (activeS.isEmpty && activeC.isEmpty) {
      setState(() => _loginError = '🚫 આ સ્ટાફ મેમ્બર હાલ નિષ્ક્રિય (નોકરી છોડેલ) તરીકે માર્ક કરેલ છે. લૉગિન શક્ય નથી.');
      return;
    }

    // 4. Validate PIN
    final validPinS = activeS.where((s) => (s.pin.isNotEmpty ? s.pin : '1111') == pin).toList();
    final validPinC = activeC.where((c) => (c.pin.isNotEmpty ? c.pin : '1111') == pin).toList();

    if (validPinS.isEmpty && validPinC.isEmpty) {
      setState(() => _loginError = '❌ ખોટો લૉગિન PIN! કૃપા કરીને સાચો PIN નાખો.');
      return;
    }

    // 5. Dual Role Check: Same person active in BOTH Salesman AND Collection
    final isDualRole = validPinS.isNotEmpty && validPinC.isNotEmpty;

    if (isDualRole) {
      // Prompt user to pick Morning Delivery vs Evening Collection
      final matchedSalesman = validPinS.first;
      final matchedCollection = validPinC.first;
      _showDualRoleChoiceDialog(matchedSalesman, matchedCollection);
    } else if (validPinS.isNotEmpty) {
      final s = validPinS.first;
      final companionC = activeC.isNotEmpty ? activeC.first : null;
      ref.read(authSessionProvider.notifier).setSalesman(s, companionC);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚴‍♂️ વિતરક: ${s.name} લૉગિન સફળ!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    } else if (validPinC.isNotEmpty) {
      final c = validPinC.first;
      final companionS = activeS.isNotEmpty ? activeS.first : null;
      ref.read(authSessionProvider.notifier).setCollection(c, companionS);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💼 ઉઘરાણી સ્ટાફ: ${c.name} લૉગિન સફળ!'),
          backgroundColor: AppColors.accentGold,
        ),
      );
    }
  }

  void _showDualRoleChoiceDialog(Salesman salesman, CollectionMan collectionMan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (choiceCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.swap_horizontal_circle, color: AppColors.accentGold, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '🔄 ડ્યુઅલ રોલ પસંદ કરો',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'નમસ્તે ${salesman.name}! તમે વિતરક (Salesman) અને ઉઘરાણીદાર (Collection) બંને હોદ્દા ધરાવો છો.',
              style: const TextStyle(color: Color(0xFFCFD8DC), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text(
              'તમે અત્યારે કયા કાર્ય માટે પ્રવેશ કરવા માંગો છો?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Option 1: Salesman Delivery
            InkWell(
              onTap: () {
                ref.read(authSessionProvider.notifier).setSalesman(salesman, collectionMan);
                Navigator.pop(choiceCtx); // Close choice dialog
                Navigator.pop(context); // Close parent role switcher
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🚴‍♂️ સવારના વિતરણ પોર્ટલમાં સ્વાગત છે (${salesman.name})!'),
                    backgroundColor: AppColors.primaryBlue,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.delivery_dining, color: AppColors.primaryBlue, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚴‍♂️ સવારનું વિતરણ (Salesman)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'દૈનિક લાઇન ડિલિવરી શીટ, પેપર કાઉન્ટ અને ગ્રાહકો',
                            style: TextStyle(color: Color(0xFF90CAF9), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: AppColors.primaryBlue, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Option 2: Collection Portal
            InkWell(
              onTap: () {
                ref.read(authSessionProvider.notifier).setCollection(collectionMan, salesman);
                Navigator.pop(choiceCtx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('💼 સાંજની ઉઘરાણી પોર્ટલમાં સ્વાગત છે (${collectionMan.name})!'),
                    backgroundColor: AppColors.accentGold,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.work_outline, color: AppColors.accentGold, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💼 સાંજની ઉઘરાણી (Collection)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'રૂટ ઉઘરાણી લિસ્ટ, સ્પોટ પાવતી, લાઈવ UPI QR અને WhatsApp',
                            style: TextStyle(color: Color(0xFFFFE082), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: AppColors.accentGold, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF141A28),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textMutedDark, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'લૉગિન થયા પછી પણ ઉપરના બારમાંથી ગમે ત્યારે ૧-ક્લિકમાં સ્વિચ કરી શકાશે.',
                      style: TextStyle(color: AppColors.textMutedDark, fontSize: 11),
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
      contentPadding: const EdgeInsets.all(20),
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
                            'સ્ટાફ ઓથેન્ટિકેશન (Staff Login)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'મોબાઇલ નંબર અને પિન વડે સુરક્ષિત લૉગિન',
                            style: TextStyle(fontSize: 11, color: AppColors.textMutedDark),
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
              const SizedBox(height: 14),

              // Active Role Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('હાલનો સક્રિય રોલ:', style: TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
              const SizedBox(height: 12),

              // TabBar: Tab 1 (Mobile Login) & Tab 2 (Admin Quick Switcher)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141A28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryTeal, width: 1),
                  ),
                  labelColor: AppColors.accentCyan,
                  unselectedLabelColor: AppColors.textMutedDark,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(icon: Icon(Icons.phone_android, size: 16), text: 'મોબાઇલ લૉગિન'),
                    Tab(icon: Icon(Icons.admin_panel_settings, size: 16), text: 'એડમિન સ્વિચર'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab Bar Content
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // TAB 1: Direct Mobile + PIN Login
                    _buildMobileLoginTab(db: DatabaseService.instance),

                    // TAB 2: Admin Direct Role Switcher (Pre-existing)
                    _buildAdminSwitcherTab(session, firm, salesmen, collectionMen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: Direct Mobile Number & PIN Login
  // -------------------------------------------------------------
  Widget _buildMobileLoginTab({required DatabaseService db}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'કર્મચારી લૉગિન (વિતરક / કલેક્શન સ્ટાફ)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'તમારા એડમિન દ્વારા આપેલ મોબાઇલ નંબર અને લૉગિન PIN દાખલ કરો.',
            style: TextStyle(color: AppColors.textMutedDark, fontSize: 11),
          ),
          const SizedBox(height: 14),

          // Mobile Number Field
          TextFormField(
            controller: _mobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'મોબાઇલ નંબર (Mobile Number)',
              hintText: 'દા.ત. 98250 11111',
              prefixIcon: const Icon(Icons.phone, color: AppColors.primaryTeal, size: 18),
              filled: true,
              fillColor: const Color(0xFF141A28),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A364F))),
            ),
          ),
          const SizedBox(height: 12),

          // PIN Field
          TextFormField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: _obscurePin,
            maxLength: 8,
            decoration: InputDecoration(
              labelText: '🔐 લૉગિન PIN (૪ થી ૮ આંકડા)',
              hintText: 'દા.ત. 1111',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.accentGold, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off, size: 18, color: Colors.white70),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
              counterText: '',
              filled: true,
              fillColor: const Color(0xFF141A28),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2A364F))),
            ),
          ),
          const SizedBox(height: 8),

          // Error Display
          if (_loginError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF5350), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loginError!,
                      style: const TextStyle(color: Color(0xFFFFCDD2), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _handleMobileLogin,
              icon: const Icon(Icons.login, size: 18),
              label: const Text('લૉગિન કરો (Login)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 14),

          // Quick autofill chips for convenience
          const Text('⚡ ઝડપી ટેસ્ટિંગ માટે ક્લિક કરો:', style: TextStyle(color: AppColors.textMutedDark, fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...db.salesmen.take(3).map((s) => ActionChip(
                    backgroundColor: const Color(0xFF141A28),
                    avatar: Icon(Icons.pedal_bike, size: 12, color: s.isActive ? AppColors.primaryBlue : AppColors.textMutedDark),
                    label: Text(
                      '${s.name} (${s.isActive ? "સક્રિય" : "છોડેલ"})',
                      style: TextStyle(
                        fontSize: 10,
                        color: s.isActive ? Colors.white : const Color(0xFFEF5350),
                        decoration: s.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _mobileCtrl.text = s.mobile;
                        _pinCtrl.text = s.pin.isNotEmpty ? s.pin : '1111';
                        _loginError = null;
                      });
                    },
                  )),
              ...db.collectionMen.take(2).map((c) => ActionChip(
                    backgroundColor: const Color(0xFF141A28),
                    avatar: Icon(Icons.work_outline, size: 12, color: c.isActive ? AppColors.accentGold : AppColors.textMutedDark),
                    label: Text(
                      '${c.name} (${c.isActive ? "સક્રિય" : "છોડેલ"})',
                      style: TextStyle(
                        fontSize: 10,
                        color: c.isActive ? Colors.white : const Color(0xFFEF5350),
                        decoration: c.isActive ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _mobileCtrl.text = c.mobile;
                        _pinCtrl.text = c.pin.isNotEmpty ? c.pin : '1111';
                        _loginError = null;
                      });
                    },
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: Admin Quick Role Switcher
  // -------------------------------------------------------------
  Widget _buildAdminSwitcherTab(
    AuthSession session,
    dynamic firm,
    List<Salesman> salesmen,
    List<CollectionMan> collectionMen,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
          const SizedBox(height: 10),

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
                // Check if companion collection profile exists
                final companionCol = collectionMen.cast<CollectionMan?>().firstWhere(
                      (c) => c?.mobile.trim() == targetSalesman.mobile.trim(),
                      orElse: () => null,
                    );
                ref.read(authSessionProvider.notifier).setSalesman(targetSalesman, companionCol);
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
          const SizedBox(height: 10),

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
                final companionSales = salesmen.cast<Salesman?>().firstWhere(
                      (s) => s?.mobile.trim() == targetColMan.mobile.trim(),
                      orElse: () => null,
                    );
                ref.read(authSessionProvider.notifier).setCollection(targetColMan, companionSales);
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
        padding: const EdgeInsets.all(12),
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
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isActive ? color : AppColors.textLight)),
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
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
            if (customChild != null) customChild,
          ],
        ),
      ),
    );
  }
}
