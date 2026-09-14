import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/bill.dart';
import '../../core/models/customer.dart';
import '../../core/providers/app_providers.dart';

class PaymentsView extends ConsumerStatefulWidget {
  const PaymentsView({super.key});

  @override
  ConsumerState<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends ConsumerState<PaymentsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMode = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentsProvider);
    final customers = ref.watch(customersProvider);
    final customerMap = {for (var c in customers) c.id: c};
    final firm = ref.watch(firmProvider);

    final filteredPayments = payments.where((p) {
      if (_selectedMode != 'all' && p.paymentMode != _selectedMode) return false;
      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.trim().toLowerCase();
        final cName = customerMap[p.customerId]?.name.toLowerCase() ?? '';
        final cNo = customerMap[p.customerId]?.custNo.toLowerCase() ?? '';
        final rec = p.receiptNo.toLowerCase();
        if (!cName.contains(q) && !cNo.contains(q) && !rec.contains(q)) return false;
      }
      return true;
    }).toList();

    final totalCollected = payments.fold(0.0, (sum, p) => sum + p.amount);
    final cashCollected = payments.where((p) => p.paymentMode == 'cash').fold(0.0, (sum, p) => sum + p.amount);
    final upiCollected = payments.where((p) => p.paymentMode != 'cash' && p.paymentMode != 'cheque').fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Actions
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.payments, color: AppColors.successGreen, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ચૂકવણી અને વસૂલાત (Payments & Collection)',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              Text(
                                'ગ્રાહકો પાસેથી મળેલ રોકડ / UPI પેમેન્ટ્સનું રજિસ્ટર',
                                style: TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    // Dynamic UPI QR Button
                    OutlinedButton.icon(
                      onPressed: () => _showDynamicUpiQrDialog(context, firm),
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('UPI QR સ્કેન'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                        side: const BorderSide(color: AppColors.primaryTeal),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    // New Payment Button
                    ElevatedButton.icon(
                      onPressed: () => _showAddPaymentModal(context, customers),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવી ચૂકવણી જમા કરો'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;
                return GridView.count(
                  crossAxisCount: isNarrow ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isNarrow ? 1.8 : 2.6,
                  children: [
                    _buildKpiCard('કુલ વસૂલાત (Total)', '₹${totalCollected.toStringAsFixed(0)}', Icons.account_balance_wallet, AppColors.successGreen, '${payments.length} ચૂકવણીઓ'),
                    _buildKpiCard('રોકડ વસૂલાત (Cash)', '₹${cashCollected.toStringAsFixed(0)}', Icons.money, AppColors.accentGold, '${payments.where((p) => p.paymentMode == 'cash').length} એન્ટ્રીઓ'),
                    _buildKpiCard('UPI / ઓનલાઇન (GPay/PhonePe)', '₹${upiCollected.toStringAsFixed(0)}', Icons.qr_code_scanner, AppColors.primaryTeal, '${payments.where((p) => p.paymentMode != 'cash' && p.paymentMode != 'cheque').length} એન્ટ્રીઓ'),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ગ્રાહક નામ / રસીદ નં...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildModeFilterChip('all', 'બધા'),
                      _buildModeFilterChip('cash', 'રોકડ (Cash)'),
                      _buildModeFilterChip('gpay', 'Google Pay / UPI'),
                      _buildModeFilterChip('phonepe', 'PhonePe'),
                      _buildModeFilterChip('cheque', 'ચેક (Cheque)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Records List
            if (filteredPayments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Column(
                  children: [
                    Icon(Icons.payments_outlined, size: 64, color: AppColors.textMutedDark.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('કોઈ ચૂકવણી રેકોર્ડ મળેલ નથી.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('નવી ચૂકવણી જમા કરવા ઉપર આપેલ બટન દબાવો.', style: TextStyle(color: AppColors.textMutedDark)),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredPayments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorderDark),
                  itemBuilder: (context, index) {
                    final p = filteredPayments[index];
                    final cust = customerMap[p.customerId];
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.check, color: AppColors.successGreen, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(cust?.name ?? 'ગ્રાહક #${p.customerId}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    if (cust?.custNo.isNotEmpty ?? false) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                        child: Text('#${cust!.custNo}', style: const TextStyle(fontSize: 10, color: AppColors.primaryTeal)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'તારીખ: ${p.date}  |  પદ્ધતિ: ${p.paymentMode.toUpperCase()}  ${p.receiptNo.isNotEmpty ? "| રસીદ: " + p.receiptNo : ""}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                                ),
                                if (p.notes.isNotEmpty)
                                  Text('નોંધ: ${p.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMutedDark)),
                              ],
                            ),
                          ),
                          Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                        ],
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

  Widget _buildModeFilterChip(String key, String label) {
    final isSelected = _selectedMode == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.successGreen.withOpacity(0.25),
      backgroundColor: AppColors.surfaceDark,
      onSelected: (_) => setState(() => _selectedMode = key),
      side: BorderSide(color: isSelected ? AppColors.successGreen : Colors.transparent),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, String subtext) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(subtext, style: const TextStyle(fontSize: 10, color: AppColors.textMutedDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPI QR Dialog
  void _showDynamicUpiQrDialog(BuildContext context, dynamic firm) {
    double qrAmount = 0.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setQrState) {
          final upiUrl = 'upi://pay?pa=${firm.upiId}&pn=${Uri.encodeComponent(firm.name)}${qrAmount > 0 ? '&am=' + qrAmount.toStringAsFixed(2) : ''}&cu=INR';
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: Row(
              children: [
                const Icon(Icons.qr_code, color: AppColors.primaryTeal),
                const SizedBox(width: 10),
                Text('${firm.name} - UPI QR'),
              ],
            ),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: upiUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('UPI ID: ${firm.upiId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentGold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'ચોક્કસ રકમ ઉમેરો (Optional Amount ₹)', isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setQrState(() => qrAmount = double.tryParse(v) ?? 0.0),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('બંધ કરો')),
            ],
          );
        },
      ),
    );
  }

  // Add Payment Modal
  void _showAddPaymentModal(BuildContext context, List<Customer> customers) {
    int? selectedCustId = customers.isNotEmpty ? customers.first.id : null;
    double amount = 0.0;
    String mode = 'cash';
    String notes = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final selectedCust = customers.cast<Customer?>().firstWhere((c) => c?.id == selectedCustId, orElse: () => null);
          return AlertDialog(
            backgroundColor: AppColors.cardDark,
            title: const Row(
              children: [
                Icon(Icons.add_card, color: AppColors.successGreen),
                SizedBox(width: 10),
                Text('નવી ચૂકવણી જમા કરો'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCustId,
                    decoration: const InputDecoration(labelText: 'ગ્રાહક પસંદ કરો (Select Customer)', isDense: true),
                    dropdownColor: AppColors.cardDark,
                    items: customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.custNo.isNotEmpty ? "#" + c.custNo + " - " : ""}${c.name} (બાકી: ₹${c.currentBalance.toStringAsFixed(0)})'))).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedCustId = val;
                      });
                    },
                  ),
                  if (selectedCust != null) ...[
                    const SizedBox(height: 8),
                    Text('હાલની બાકી રકમ: ₹${selectedCust.currentBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.errorRed)),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'જમા મળતી રકમ (₹) *'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => amount = double.tryParse(v) ?? 0.0,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: mode,
                    decoration: const InputDecoration(labelText: 'ચૂકવણી પદ્ધતિ (Mode)', isDense: true),
                    dropdownColor: AppColors.cardDark,
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('રોકડ (Cash)')),
                      DropdownMenuItem(value: 'gpay', child: Text('Google Pay / UPI')),
                      DropdownMenuItem(value: 'phonepe', child: Text('PhonePe / Paytm')),
                      DropdownMenuItem(value: 'cheque', child: Text('ચેક (Cheque)')),
                    ],
                    onChanged: (v) => setModalState(() => mode = v ?? 'cash'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'નોંધ / રસીદ નંબર'),
                    onChanged: (v) => notes = v,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
              ElevatedButton.icon(
                onPressed: () {
                  if (selectedCustId == null || amount <= 0) return;
                  Navigator.pop(ctx);
                  final db = ref.read(databaseProvider);
                  final p = Payment(
                    id: DateTime.now().millisecondsSinceEpoch,
                    customerId: selectedCustId!,
                    date: DateTime.now().toIso8601String().split('T')[0],
                    amount: amount,
                    paymentMode: mode,
                    notes: notes,
                  );
                  db.recordPayment(p);
                  notifyDbChanged(ref);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('₹${amount.toStringAsFixed(0)} ની ચૂકવણી જમા થઈ ગઈ!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('જમા કરો'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen),
              ),
            ],
          );
        },
      ),
    );
  }
}
