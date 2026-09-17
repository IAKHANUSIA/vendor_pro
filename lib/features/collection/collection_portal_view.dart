import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/bill.dart';
import '../../core/models/customer.dart';
import '../../core/models/route.dart';
import '../../core/providers/app_providers.dart';
import '../payments/payment_receipt_dialog.dart';

class CollectionPortalView extends ConsumerStatefulWidget {
  const CollectionPortalView({super.key});

  @override
  ConsumerState<CollectionPortalView> createState() => _CollectionPortalViewState();
}

class _CollectionPortalViewState extends ConsumerState<CollectionPortalView> {
  int? _selectedRouteId;
  String _searchQuery = '';

  void _openCollectDialog(Customer customer) {
    final db = DatabaseService.instance;
    final amtCtrl = TextEditingController(text: customer.currentBalance.toStringAsFixed(0));
    String payMode = 'cash';
    final remarksCtrl = TextEditingController(text: 'ઉઘરાણી વસૂલાત');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgCardDark,
          title: Row(
            children: [
              const Text('💰 ', style: TextStyle(fontSize: 20)),
              Expanded(
                child: Text(
                  '${customer.name} પાસેથી ઉઘરાણી જમા',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('કુલ બાકી રકમ:', style: TextStyle(color: AppColors.dangerLight, fontWeight: FontWeight.bold)),
                    Text('₹${customer.currentBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'જમા રકમ (₹)', prefixText: '₹'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: payMode,
                dropdownColor: AppColors.bgCardDark,
                decoration: const InputDecoration(labelText: 'પેમેન્ટ પ્રકાર'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('💵 રોકડ (Cash)')),
                  DropdownMenuItem(value: 'upi', child: Text('📱 UPI / Google Pay / PhonePe')),
                  DropdownMenuItem(value: 'bank', child: Text('🏦 બેંક ટ્રાન્સફર / ચેક')),
                ],
                onChanged: (v) => setDlgState(() => payMode = v ?? 'cash'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: remarksCtrl,
                decoration: const InputDecoration(labelText: 'નોંધ / પહોંચ નં.'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton(
              onPressed: () {
                final collectedAmt = double.tryParse(amtCtrl.text) ?? 0.0;
                if (collectedAmt <= 0) return;

                final pId = db.payments.isEmpty ? 1 : db.payments.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
                final payment = Payment(
                  id: pId,
                  customerId: customer.id,
                  amount: collectedAmt,
                  date: DateTime.now().toIso8601String().split('T')[0],
                  paymentMode: payMode,
                  notes: remarksCtrl.text.trim(),
                );
                db.payments.add(payment);

                // Update customer balance
                customer.currentBalance -= collectedAmt;
                if (customer.currentBalance < 0) customer.currentBalance = 0;

                notifyDbChanged(ref);
                Navigator.pop(ctx);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.successGreen,
                    content: Text('✅ ₹$collectedAmt ની ઉઘરાણી સફળતાપૂર્વક જમા થઈ!'),
                  ),
                );

                // Prompt digital payment receipt
                PaymentReceiptDialog.show(context, payment: payment, customer: customer, firm: db.firm);
              },
              child: const Text('જમા કરો (Collect)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpiQrDialog(Customer customer) {
    final db = DatabaseService.instance;
    final upiId = db.firm.upiId.isNotEmpty ? db.firm.upiId : '9825000000@upi';
    final amt = customer.currentBalance;
    final upiUrl = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(db.firm.name)}&am=$amt&cu=INR&tn=${Uri.encodeComponent("Newspaper Bill - ${customer.name}")}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCardDark,
        title: Center(
          child: Text(
            '📱 UPI QR કોડ - ${customer.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: upiUrl,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'બાકી રકમ: ₹${amt.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.accentCyan),
            ),
            const SizedBox(height: 4),
            Text(
              'UPI ID: $upiId',
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ),
            const SizedBox(height: 8),
            const Text(
              'ગ્રાહક આ QR સ્કેન કરીને સીધું પેમેન્ટ કરી શકશે.',
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('બંધ કરો'),
            ),
          ),
        ],
      ),
    );
  }

  void _sendWhatsAppReminder(Customer customer) async {
    final db = DatabaseService.instance;
    final phone = customer.whatsapp.isNotEmpty ? customer.whatsapp : customer.mobile;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ગ્રાહકનો મોબાઈલ અથવા વૉટ્સએપ નંબર ઉપલબ્ધ નથી.')),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;

    final msg = '''નમસ્તે ${customer.name},
*${db.firm.name}* તરફથી ન્યૂઝપેપર બિલની યાદી.
તમારી કુલ બાકી રકમ: *₹${customer.currentBalance.toStringAsFixed(0)}* છે.
કૃપા કરીને આ રકમ રોકડ અથવા UPI ID: *${db.firm.upiId}* પર જમા કરાવવા વિનંતી.
આભાર!''';

    final uri = Uri.parse('https://wa.me/$fullPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp ખોલી શકાયું નથી.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final session = ref.watch(authSessionProvider);
    final isCollectionRole = session.role == AppRole.collection;
    final activeColMan = session.activeCollectionMan;

    // Filter available routes based on role
    final availableRoutes = isCollectionRole && activeColMan != null
        ? db.routes.where((r) => r.collectionManId == activeColMan.id).toList()
        : db.routes;

    // Filter customers who have pending balance
    final pendingCustomers = db.customers.where((c) {
      if (c.status != 'active') return false;
      if (c.currentBalance <= 0) return false;
      if (isCollectionRole && activeColMan != null) {
        // Only show customers from assigned routes
        if (!availableRoutes.any((r) => r.id == c.routeId)) return false;
      }
      if (_selectedRouteId != null && c.routeId != _selectedRouteId) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!c.name.toLowerCase().contains(q) && !c.mobile.contains(q) && !c.code.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => (int.tryParse(a.collectionSequence) ?? int.tryParse(a.sequenceNo) ?? 0)
          .compareTo(int.tryParse(b.collectionSequence) ?? int.tryParse(b.sequenceNo) ?? 0));

    final totalPendingAmt = pendingCustomers.fold(0.0, (sum, c) => sum + c.currentBalance);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E1A47), Color(0xFF1E2433)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.purple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: AppColors.purple, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isCollectionRole && activeColMan != null
                                  ? '💼 ${activeColMan.name} - ઉઘરાણી પોર્ટલ'
                                  : '💼 ઉઘરાણી માસ્ટર અને એજન્ટ કલેક્શન પોર્ટલ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            if (isCollectionRole) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'કલેક્શન સ્ટાફ મોડ',
                                  style: TextStyle(fontSize: 10, color: AppColors.accentGold, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'બાકી ગ્રાહકો: ${pendingCustomers.length} | કુલ વસૂલવાની બાકી રકમ: ₹${totalPendingAmt.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Filters
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondaryDark),
                      hintText: 'ગ્રાહકનું નામ, કોડ, મોબાઇલથી શોધો...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedRouteId,
                    dropdownColor: AppColors.bgCardDark,
                    decoration: const InputDecoration(isDense: true, labelText: 'લાઇન ફિલ્ટર'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('બધી લાઇન')),
                      ...availableRoutes.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedRouteId = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pending Collection List
            Expanded(
              child: pendingCustomers.isEmpty
                  ? const Center(
                      child: Text(
                        '🎉 પસંદ કરેલ લાઇન પર કોઈ બાકી ઉઘરાણી નથી!',
                        style: TextStyle(color: AppColors.successGreen, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      itemCount: pendingCustomers.length,
                      itemBuilder: (ctx, i) {
                        final c = pendingCustomers[i];
                        final r = db.routes.cast<DeliveryRoute?>().firstWhere((rt) => rt?.id == c.routeId, orElse: () => null);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Sequence Number
                                Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c.collectionSequence.isNotEmpty ? c.collectionSequence : c.sequenceNo,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Customer Info & Balance
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                            ),
                                          ),
                                          Text(
                                            '₹${c.currentBalance.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: AppColors.dangerLight,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          if (r != null) Text('🗺️ ${r.name}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                                          if (c.mobile.isNotEmpty) Text('📞 ${c.mobile}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                                          if (c.address.isNotEmpty) Text('🏠 ${c.address}', style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Action Buttons
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // WhatsApp Button
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 20),
                                      onPressed: () => _sendWhatsAppReminder(c),
                                      tooltip: 'WhatsApp બિલ રિમાઇન્ડર',
                                    ),
                                    // UPI QR Button
                                    IconButton(
                                      icon: const Icon(Icons.qr_code, color: AppColors.accentCyan, size: 20),
                                      onPressed: () => _showUpiQrDialog(c),
                                      tooltip: 'UPI QR કોડ',
                                    ),
                                    // Collect Cash / Online Button
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.successGreen,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      onPressed: () => _openCollectDialog(c),
                                      icon: const Icon(Icons.payments, size: 16),
                                      label: const Text('જમા'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
