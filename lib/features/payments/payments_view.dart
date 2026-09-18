import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/bill.dart';
import '../../core/models/customer.dart';
import '../../core/models/route.dart';
import '../../core/models/collection_man.dart';
import '../../core/providers/app_providers.dart';
import 'dynamic_upi_dialog.dart';
import 'payment_receipt_dialog.dart';

class PaymentsView extends ConsumerStatefulWidget {
  const PaymentsView({super.key});

  @override
  ConsumerState<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends ConsumerState<PaymentsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMode = 'all';
  int? _selectedCollectionManId;

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
    final routes = ref.watch(routesProvider);
    final routeMap = {for (var r in routes) r.id: r};
    final bills = ref.watch(billsProvider);
    final firm = ref.watch(firmProvider);
    final collectionMen = ref.watch(collectionMenProvider);

    final filteredPayments = payments.where((p) {
      if (_selectedMode != 'all' && p.paymentMode != _selectedMode) return false;

      final cust = customerMap[p.customerId];

      if (_selectedCollectionManId != null) {
        final r = cust != null ? routeMap[cust.routeId] : null;
        if (r?.collectionManId != _selectedCollectionManId) return false;
      }

      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.trim().toLowerCase();
        final cName = cust?.name.toLowerCase() ?? '';
        final cNo = cust?.custNo.toLowerCase() ?? '';
        final cCode = cust?.code.toLowerCase() ?? '';
        final cMob = cust?.mobile.toLowerCase() ?? '';
        final rec = p.receiptNo.toLowerCase();

        // Check if query matches any bill of this customer or bill number directly
        final hasMatchingBill = bills.any(
          (b) => b.customerId == p.customerId && (b.billNo.toLowerCase().contains(q) || b.id.toString().contains(q)),
        );

        if (!cName.contains(q) && !cNo.contains(q) && !cCode.contains(q) && !cMob.contains(q) && !rec.contains(q) && !hasMatchingBill) {
          return false;
        }
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
            LayoutBuilder(
              builder: (context, headerConstraints) {
                final isHeaderNarrow = headerConstraints.maxWidth < 750;
                final headerInfo = Row(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'ચૂકવણી અને વસૂલાત (Payments & Collection)',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          Text(
                            'ગ્રાહકો પાસેથી મળેલ રોકડ / UPI પેમેન્ટ્સનું રજિસ્ટર',
                            style: TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final actionButtons = Wrap(
                  spacing: 12,
                  runSpacing: 8,
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
                      onPressed: () => _showAddPaymentModal(context, customers, collectionMen, routes, bills),
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
                );

                if (isHeaderNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      headerInfo,
                      const SizedBox(height: 14),
                      actionButtons,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: headerInfo),
                    actionButtons,
                  ],
                );
              },
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

            // Filter Bar with Bill No / Search & Collection Man combo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: LayoutBuilder(
                builder: (context, filterConstraints) {
                  final isFilterNarrow = filterConstraints.maxWidth < 600;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Search Bar with Bill No support
                      SizedBox(
                        width: isFilterNarrow ? double.infinity : 280,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'શોધો (બિલ નં, ગ્રાહક, રસીદ)...',
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

                      // Collection Man Combo Filter
                      SizedBox(
                        width: isFilterNarrow ? double.infinity : 220,
                        child: DropdownButtonFormField<int?>(
                          value: _selectedCollectionManId,
                          dropdownColor: const Color(0xFF1E2638),
                          decoration: InputDecoration(
                            labelText: '💼 ઉઘરાણીદાર',
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.surfaceDark,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('બધા ઉઘરાણીદાર (All)')),
                            ...collectionMen.map((cm) => DropdownMenuItem<int?>(value: cm.id, child: Text(cm.name))),
                          ],
                          onChanged: (v) => setState(() => _selectedCollectionManId = v),
                        ),
                      ),

                      // Mode Chips
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
                  );
                },
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                              const SizedBox(height: 4),
                              if (cust != null)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    PaymentReceiptDialog.show(context, payment: p, customer: cust, firm: firm);
                                  },
                                  icon: const Icon(Icons.receipt_long, size: 14),
                                  label: const Text('રસીદ', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accentCyan,
                                    side: const BorderSide(color: AppColors.accentCyan, width: 0.8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
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
    DynamicUpiDialog.show(context, firm: firm);
  }

  // Add Payment Modal matching Image 4
  void _showAddPaymentModal(
    BuildContext context,
    List<Customer> customers,
    List<CollectionMan> collectionMen,
    List<DeliveryRoute> routes,
    List<Bill> bills,
  ) {
    final routeMap = {for (var r in routes) r.id: r};
    int? modalCollectionManId;
    String modalSearchQuery = '';
    final searchCtrl = TextEditingController();

    int? selectedCustId = customers.isNotEmpty ? customers.first.id : null;
    double amount = 0.0;
    String mode = 'cash';
    String notes = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          // Filter customers by collection man and search query (name, code, custNo, mobile, bill no)
          final filteredCusts = customers.where((c) {
            if (modalCollectionManId != null) {
              final r = routeMap[c.routeId];
              if (r?.collectionManId != modalCollectionManId) return false;
            }

            if (modalSearchQuery.trim().isNotEmpty) {
              final q = modalSearchQuery.toLowerCase();
              final matchName = c.name.toLowerCase().contains(q);
              final matchMobile = c.mobile.contains(q);
              final matchCode = c.code.toLowerCase().contains(q);
              final matchCustNo = c.custNo.contains(q);
              final matchBill = bills.any((b) => b.customerId == c.id && (b.billNo.toLowerCase().contains(q) || b.id.toString().contains(q)));

              if (!matchName && !matchMobile && !matchCode && !matchCustNo && !matchBill) {
                return false;
              }
            }
            return true;
          }).toList();

          if (selectedCustId != null && !filteredCusts.any((c) => c.id == selectedCustId)) {
            selectedCustId = filteredCusts.isNotEmpty ? filteredCusts.first.id : null;
          }

          final selectedCust = customers.cast<Customer?>().firstWhere((c) => c?.id == selectedCustId, orElse: () => null);

          return Dialog(
            backgroundColor: const Color(0xFF1E2638),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Header matching Image 4
                    Row(
                      children: const [
                        Icon(Icons.add_card, color: Color(0xFF00E676), size: 24),
                        SizedBox(width: 10),
                        Text(
                          'નવી ચૂકવણી જમા કરો',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filter row inside modal: Collection Man & Search Bar
                    Row(
                      children: [
                        // Collection Man combo
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int?>(
                            value: modalCollectionManId,
                            dropdownColor: const Color(0xFF141A28),
                            decoration: InputDecoration(
                              labelText: '💼 ઉઘરાણીદાર',
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFF141A28),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('બધા (All)', style: TextStyle(fontSize: 12, color: Colors.white))),
                              ...collectionMen.map((cm) => DropdownMenuItem<int?>(value: cm.id, child: Text(cm.name, style: const TextStyle(fontSize: 12, color: Colors.white)))),
                            ],
                            onChanged: (v) => setModalState(() => modalCollectionManId = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Search by Bill No / Name
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: searchCtrl,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondaryDark),
                              labelText: 'બિલ નં / ગ્રાહક શોધો',
                              hintText: 'દા.ત. #101, B-101, રમેશ...',
                              isDense: true,
                              filled: true,
                              fillColor: const Color(0xFF141A28),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                            ),
                            onChanged: (v) => setModalState(() => modalSearchQuery = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Customer Selection Dropdown matching Image 4
                    const Text('ગ્રાહક પસંદ કરો (Select Customer)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: selectedCustId,
                      dropdownColor: const Color(0xFF141A28),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF141A28),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                      ),
                      items: filteredCusts.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '#${c.custNo.isNotEmpty ? c.custNo : c.id} - ${c.name} (બાકી: ₹${c.currentBalance.toStringAsFixed(0)})',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedCustId = val;
                        });
                      },
                    ),

                    // Prominent Balance Alert matching Image 4
                    if (selectedCust != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'હાલની બાકી રકમ: ₹${selectedCust.currentBalance.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5252),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Amount Input
                    const Text('જમા મળતી રકમ (₹) *', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'દા.ત. 320',
                        filled: true,
                        fillColor: const Color(0xFF141A28),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => amount = double.tryParse(v) ?? 0.0,
                    ),
                    const SizedBox(height: 14),

                    // Payment Mode Dropdown matching Image 4
                    const Text('ચૂકવણી પદ્ધતિ (Mode)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: mode,
                      dropdownColor: const Color(0xFF141A28),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF141A28),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('રોકડ (Cash)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: 'gpay', child: Text('Google Pay / UPI', style: TextStyle(color: Colors.white, fontSize: 13))),
                        DropdownMenuItem(value: 'phonepe', child: Text('PhonePe / Paytm', style: TextStyle(color: Colors.white, fontSize: 13))),
                        DropdownMenuItem(value: 'cheque', child: Text('ચેક (Cheque)', style: TextStyle(color: Colors.white, fontSize: 13))),
                      ],
                      onChanged: (v) => setModalState(() => mode = v ?? 'cash'),
                    ),
                    const SizedBox(height: 14),

                    // Notes / Receipt No
                    const Text('નોંધ / રસીદ નંબર', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'દા.ત. REC-001',
                        filled: true,
                        fillColor: const Color(0xFF141A28),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                      ),
                      onChanged: (v) => notes = v,
                    ),
                    const SizedBox(height: 22),

                    // Footer Buttons matching Image 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('રદ કરો', style: TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (selectedCustId == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('કૃપા કરીને રકમ દાખલ કરો!')),
                              );
                              return;
                            }
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
                            if (selectedCust != null) {
                              PaymentReceiptDialog.show(context, payment: p, customer: selectedCust, firm: db.firm);
                            }
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('જમા કરો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
