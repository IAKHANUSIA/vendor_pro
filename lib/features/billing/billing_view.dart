import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/bill.dart';
import '../../core/models/customer.dart';
import '../../core/models/route.dart';
import '../../core/models/salesman.dart';
import '../../core/providers/app_providers.dart';
import '../../core/printing/print_service.dart';
import 'whatsapp_express_dialog.dart';
import 'bill_image_modal.dart';
import '../payments/dynamic_upi_dialog.dart';

class BillingView extends ConsumerStatefulWidget {
  const BillingView({super.key});

  @override
  ConsumerState<BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends ConsumerState<BillingView> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int? _selectedRouteId;
  String _selectedStatus = 'all'; // 'all', 'pending', 'partial', 'paid'
  final TextEditingController _searchController = TextEditingController();

  final List<String> _monthNamesGu = [
    'જાન્યુઆરી', 'ફેબ્રુઆરી', 'માર્ચ', 'એપ્રિલ', 'મે', 'જૂન',
    'જુલાઇ', 'ઓગસ્ટ', 'સપ્ટેમ્બર', 'ઓક્ટોબર', 'નવેમ્બર', 'ડિસેમ્બર'
  ];

  String get _currentMonthKey => '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    // Auto-calculate bills if none exist for current month
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = ref.read(databaseProvider);
      if (db.bills.where((b) => b.monthYear == _currentMonthKey).isEmpty) {
        db.calculateMonthlyBills(_selectedYear, _selectedMonth);
        notifyDbChanged(ref);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBills = ref.watch(billsProvider);
    final routes = ref.watch(routesProvider);
    final firm = ref.watch(firmProvider);

    final monthBills = allBills.where((b) => b.monthYear == _currentMonthKey).toList();

    // Filter by Route, Status, Search
    final filteredBills = monthBills.where((b) {
      if (_selectedRouteId != null && b.routeId != _selectedRouteId) return false;
      if (_selectedStatus != 'all' && b.status != _selectedStatus) return false;
      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.trim().toLowerCase();
        final matchName = b.customerName.toLowerCase().contains(q);
        final matchNo = b.customerNo.toLowerCase().contains(q);
        final matchBill = b.billNo.toLowerCase().contains(q);
        if (!matchName && !matchNo && !matchBill) return false;
      }
      return true;
    }).toList();

    final totalBilled = monthBills.fold(0.0, (sum, b) => sum + b.finalPayable);
    final totalReceived = monthBills.fold(0.0, (sum, b) => sum + b.paymentReceived);
    final totalDue = monthBills.fold(0.0, (sum, b) => sum + b.balanceDue);
    final paidCount = monthBills.where((b) => b.status == 'paid').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Month Selector & Action
            LayoutBuilder(
              builder: (context, headerConstraints) {
                final isHeaderNarrow = headerConstraints.maxWidth < 850;
                final headerInfo = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long, color: AppColors.primaryTeal, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'માસિક બિલિંગ મેનેજમેન્ટ (Monthly Billing)',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          Text(
                            '${_monthNamesGu[_selectedMonth - 1]} $_selectedYear ના ગ્રાહક બિલો',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final actionControls = Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    // Month dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorderDark),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedMonth,
                          dropdownColor: AppColors.cardDark,
                          items: List.generate(12, (i) => i + 1).map((m) {
                            return DropdownMenuItem<int>(
                              value: m,
                              child: Text(_monthNamesGu[m - 1], style: const TextStyle(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMonth = val);
                              final db = ref.read(databaseProvider);
                              if (db.bills.where((b) => b.monthYear == _currentMonthKey).isEmpty) {
                                db.calculateMonthlyBills(_selectedYear, _selectedMonth);
                                notifyDbChanged(ref);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    // Year dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorderDark),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          dropdownColor: AppColors.cardDark,
                          items: [2025, 2026, 2027].map((y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text('$y', style: const TextStyle(fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedYear = val);
                          },
                        ),
                      ),
                    ),
                    // Calculate Bills Action Button
                    ElevatedButton.icon(
                      onPressed: () => _showCalculateBillsDialog(context),
                      icon: const Icon(Icons.calculate, size: 18),
                      label: const Text('બિલ ગણો (Calculate)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    // WhatsApp Express Bulk Queue Action Button
                    ElevatedButton.icon(
                      onPressed: () => WhatsAppExpressDialog.show(
                        context,
                        monthBills: monthBills,
                        firm: firm,
                        monthYear: '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}',
                      ),
                      icon: const Icon(Icons.rocket_launch, size: 18),
                      label: const Text('WhatsApp Express'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    // Print All Bills PDF Formats Button
                    OutlinedButton.icon(
                      onPressed: () => _showBulkPrintFormatDialog(context, filteredBills, firm),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('A4 પ્રિન્ટ ફોર્મેટ્સ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentGold,
                        side: const BorderSide(color: AppColors.accentGold),
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
                      actionControls,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: headerInfo),
                    actionControls,
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // KPI Stats Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;
                return GridView.count(
                  crossAxisCount: isNarrow ? 2 : 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isNarrow ? 1.8 : 2.4,
                  children: [
                    _buildKpiCard('કુલ બિલ સંખ્યા', '${monthBills.length} બિલો', Icons.receipt, AppColors.primaryTeal, 'પેઇડ: $paidCount / ${monthBills.length}'),
                    _buildKpiCard('કુલ બિલિંગ રકમ', '₹${totalBilled.toStringAsFixed(0)}', Icons.account_balance_wallet, AppColors.accentGold, 'વિતરણ + પેપર્સ'),
                    _buildKpiCard('જમા મળેલ રકમ', '₹${totalReceived.toStringAsFixed(0)}', Icons.check_circle, AppColors.successGreen, 'રિકવરી: ${totalBilled > 0 ? ((totalReceived / totalBilled) * 100).toStringAsFixed(1) : 0}%'),
                    _buildKpiCard('કુલ બાકી લેણી રકમ', '₹${totalDue.toStringAsFixed(0)}', Icons.pending_actions, AppColors.errorRed, 'બાકી ગ્રાહકો: ${monthBills.where((b) => b.balanceDue > 0).length}'),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Filter Bar (Search, Route Filter, Status Pills)
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
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Search field
                      SizedBox(
                        width: isFilterNarrow ? double.infinity : 260,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'ગ્રાહક નામ / નંબર / બિલ નં...',
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
                  // Route Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedRouteId,
                        hint: const Text('બધી લાઇનો (All Routes)'),
                        dropdownColor: AppColors.cardDark,
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('બધી લાઇનો (All Routes)')),
                          ...routes.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text('${r.code} - ${r.name}'))),
                        ],
                        onChanged: (val) => setState(() => _selectedRouteId = val),
                      ),
                    ),
                  ),
                  // Status Filter Chips
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildStatusFilterChip('all', 'બધા (${monthBills.length})'),
                      _buildStatusFilterChip('pending', 'બાકી (${monthBills.where((b) => b.status == 'pending').length})', AppColors.errorRed),
                      _buildStatusFilterChip('partial', 'અડધું ચૂકવેલ (${monthBills.where((b) => b.status == 'partial').length})', AppColors.accentGold),
                      _buildStatusFilterChip('paid', 'ચૂકવેલ (${monthBills.where((b) => b.status == 'paid').length})', AppColors.successGreen),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),

            // Bills Data Table / List
            if (filteredBills.isEmpty)
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
                    Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMutedDark.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('આ મહિનાના કોઈ બિલો મળ્યા નથી.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('ઉપર આપેલ "બિલ ગણો (Calculate)" બટન દબાવીને તાજા બિલો જનરેટ કરો.', style: TextStyle(color: AppColors.textMutedDark)),
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
                  itemCount: filteredBills.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorderDark),
                  itemBuilder: (context, index) {
                    final bill = filteredBills[index];
                    return _buildBillRow(context, bill, firm);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(String key, String label, [Color? color]) {
    final isSelected = _selectedStatus == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: (color ?? AppColors.primaryTeal).withOpacity(0.25),
      backgroundColor: AppColors.surfaceDark,
      onSelected: (_) => setState(() => _selectedStatus = key),
      side: BorderSide(color: isSelected ? (color ?? AppColors.primaryTeal) : Colors.transparent),
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
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
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
                Text(subtext, style: const TextStyle(fontSize: 10, color: AppColors.textMutedDark), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(BuildContext context, Bill bill, dynamic firm) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 750) {
      return _buildMobileBillCard(context, bill, firm);
    }

    final statusColor = bill.status == 'paid'
        ? AppColors.successGreen
        : (bill.status == 'partial' ? AppColors.accentGold : AppColors.errorRed);
    final statusText = bill.status == 'paid'
        ? 'ચૂકવેલ'
        : (bill.status == 'partial' ? 'અડધું ચૂકવેલ' : 'બાકી');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Bill No & Customer Info
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorderDark),
            ),
            child: Column(
              children: [
                const Text('બિલ નં', style: TextStyle(fontSize: 9, color: AppColors.textMutedDark)),
                Text(bill.billNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bill.customerName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    if (bill.customerNo.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('કોડ #${bill.customerNo}', style: const TextStyle(fontSize: 10, color: AppColors.primaryTeal)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'વિતરણ દિવસ: ${bill.deliveryDays}  |  રજા કપાત: ${bill.vacationDays} દિવસ (-₹${bill.vacationDeduction.toStringAsFixed(0)})  |  ચાર્જ: ₹${bill.deliveryCharge.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                ),
              ],
            ),
          ),
          // Amount Breakdown
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${bill.finalPayable.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                const SizedBox(height: 2),
                if (bill.pastBalance > 0)
                  Text('પાછલી બાકી: ₹${bill.pastBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                if (bill.paymentReceived > 0)
                  Text('જમા: ₹${bill.paymentReceived.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.successGreen)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
          ),
          const SizedBox(width: 16),
          // Actions: Preview, Bill Image Card, WhatsApp, UPI QR, Payment
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 18, color: AppColors.primaryTeal),
                tooltip: 'બિલ વિગતો (Preview)',
                onPressed: () => _showBillPreviewModal(context, bill, firm),
              ),
              IconButton(
                icon: const Icon(Icons.image, size: 18, color: AppColors.accentCyan),
                tooltip: 'બિલ ઈમેજ કાર્ડ / ડાઉનલોડ (Image Card)',
                onPressed: () {
                  final cust = ref.read(customersProvider).cast<Customer?>().firstWhere((c) => c?.id == bill.customerId, orElse: () => null);
                  final route = ref.read(routesProvider).cast<DeliveryRoute?>().firstWhere((r) => r?.id == bill.routeId, orElse: () => null);
                  final salesman = route != null ? ref.read(salesmenProvider).cast<Salesman?>().firstWhere((s) => s?.id == route.salesmanId, orElse: () => null) : null;
                  BillImageModal.show(context, bill: bill, firm: firm, customer: cust, route: route, salesman: salesman);
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat, size: 18, color: AppColors.successGreen),
                tooltip: 'WhatsApp બિલ / ઈમેજ મોકલો',
                onPressed: () => _sendWhatsAppBill(context, bill, firm),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code, size: 18, color: AppColors.accentGold),
                tooltip: 'લાઇવ UPI QR સ્કેન',
                onPressed: () {
                  final cust = ref.read(customersProvider).cast<Customer?>().firstWhere((c) => c?.id == bill.customerId, orElse: () => null);
                  DynamicUpiDialog.show(context, firm: firm, bill: bill, customer: cust);
                },
              ),
              IconButton(
                icon: const Icon(Icons.payments, size: 18, color: AppColors.successGreen),
                tooltip: 'ચૂકવણી જમા કરો (Receive Payment)',
                onPressed: () => _showReceivePaymentModal(context, bill),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBillCard(BuildContext context, Bill bill, dynamic firm) {
    final statusColor = bill.status == 'paid'
        ? AppColors.successGreen
        : (bill.status == 'partial' ? AppColors.accentGold : AppColors.errorRed);
    final statusText = bill.status == 'paid'
        ? 'ચૂકવેલ'
        : (bill.status == 'partial' ? 'અડધું ચૂકવેલ' : 'બાકી');

    return Container(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Bill No pill, Customer Name, Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                ),
                child: Text('#${bill.billNo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.customerName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bill.customerNo.isNotEmpty)
                      Text('ગ્રાહક કોડ: #${bill.customerNo}', style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Delivery details & Financial amounts
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('વિતરણ: ${bill.deliveryDays} દિવસ  |  રજા: ${bill.vacationDays}', style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                    if (bill.pastBalance > 0)
                      Text('પાછલી બાકી: ₹${bill.pastBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.errorRed)),
                    if (bill.paymentReceived > 0)
                      Text('જમા: ₹${bill.paymentReceived.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.successGreen)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('ચૂકવવાપાત્ર રકમ', style: TextStyle(fontSize: 10, color: AppColors.textMutedDark)),
                    Text('₹${bill.finalPayable.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Action Buttons nicely distributed
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMobileActionBtn(
                icon: Icons.visibility,
                label: 'વિગતો',
                color: AppColors.primaryTeal,
                onPressed: () => _showBillPreviewModal(context, bill, firm),
              ),
              _buildMobileActionBtn(
                icon: Icons.image,
                label: 'કાર્ડ',
                color: AppColors.accentCyan,
                onPressed: () {
                  final cust = ref.read(customersProvider).cast<Customer?>().firstWhere((c) => c?.id == bill.customerId, orElse: () => null);
                  final route = ref.read(routesProvider).cast<DeliveryRoute?>().firstWhere((r) => r?.id == bill.routeId, orElse: () => null);
                  final salesman = route != null ? ref.read(salesmenProvider).cast<Salesman?>().firstWhere((s) => s?.id == route.salesmanId, orElse: () => null) : null;
                  BillImageModal.show(context, bill: bill, firm: firm, customer: cust, route: route, salesman: salesman);
                },
              ),
              _buildMobileActionBtn(
                icon: Icons.chat,
                label: 'WhatsApp',
                color: AppColors.successGreen,
                onPressed: () => _sendWhatsAppBill(context, bill, firm),
              ),
              _buildMobileActionBtn(
                icon: Icons.qr_code,
                label: 'UPI QR',
                color: AppColors.accentGold,
                onPressed: () {
                  final cust = ref.read(customersProvider).cast<Customer?>().firstWhere((c) => c?.id == bill.customerId, orElse: () => null);
                  DynamicUpiDialog.show(context, firm: firm, bill: bill, customer: cust);
                },
              ),
              _buildMobileActionBtn(
                icon: Icons.payments,
                label: 'જમા કરો',
                color: AppColors.successGreen,
                onPressed: () => _showReceivePaymentModal(context, bill),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // 1. Calculate Bills Dialog
  void _showCalculateBillsDialog(BuildContext context) {
    String format = 'sequential';
    String prefix = '';
    int startNum = 1001;
    int padding = 4;
    String sortBy = 'salesman_delivery';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Row(
            children: [
              const Icon(Icons.calculate, color: AppColors.primaryTeal),
              const SizedBox(width: 10),
              Text('${_monthNamesGu[_selectedMonth - 1]} $_selectedYear - બિલ ગણતરી'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const Text(
                  'બધા ગ્રાહકોના રોજિંદા પેપર દર, રજા કપાત, બોનસ પેપર્સ અને વિતરણ ચાર્જ ગણીને તાજા બિલો તૈયાર થશે.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: format,
                  decoration: const InputDecoration(labelText: 'બિલ નંબર શૈલી (Format)', isDense: true),
                  dropdownColor: AppColors.cardDark,
                  items: const [
                    DropdownMenuItem(value: 'sequential', child: Text('ક્રમિક નંબર (દા.ત. 1001, 1002)')),
                    DropdownMenuItem(value: 'month_seq', child: Text('મહિના સાથે (દા.ત. SEP26-1001)')),
                  ],
                  onChanged: (v) => setDialogState(() => format = v ?? 'sequential'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: prefix,
                        decoration: const InputDecoration(labelText: 'પ્રીફિક્સ (Prefix)', hintText: 'દા.ત. VP-'),
                        onChanged: (v) => prefix = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: startNum.toString(),
                        decoration: const InputDecoration(labelText: 'શરૂઆત નંબર (Start No)'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => startNum = int.tryParse(v) ?? 1001,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sortBy,
                  decoration: const InputDecoration(labelText: 'ક્રમ ગોઠવણી (Sort Order)', isDense: true),
                  dropdownColor: AppColors.cardDark,
                  items: const [
                    DropdownMenuItem(value: 'salesman_delivery', child: Text('સેલ્સમેન + ડિલિવરી ક્રમ')),
                    DropdownMenuItem(value: 'delivery_salesman', child: Text('ડિલિવરી મેન + સેલ્સમેન ક્રમ')),
                    DropdownMenuItem(value: 'route_salesman', child: Text('લાઇન + સેલ્સમેન ક્રમ')),
                    DropdownMenuItem(value: 'route_delivery', child: Text('લાઇન + ડિલિવરી ક્રમ')),
                    DropdownMenuItem(value: 'salesman_salesman', child: Text('સેલ્સમેન + સેલ્સમેન ક્રમ')),
                    DropdownMenuItem(value: 'delivery_delivery', child: Text('ડિલિવરી મેન + ડિલિવરી ક્રમ')),
                  ],
                  onChanged: (v) => setDialogState(() => sortBy = v ?? 'salesman_delivery'),
                ),
              ],
            ),
          ),
        ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                db.calculateMonthlyBills(
                  _selectedYear,
                  _selectedMonth,
                  format: format,
                  prefix: prefix,
                  startNum: startNum,
                  padding: padding,
                  sortBy: sortBy,
                );
                notifyDbChanged(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_monthNamesGu[_selectedMonth - 1]} $_selectedYear ના બિલો સફળતાપૂર્વક ગણાઈ ગયા!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              icon: const Icon(Icons.done),
              label: const Text('બિલ તૈયાર કરો'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Bill Preview Modal
  void _showBillPreviewModal(BuildContext context, Bill bill, dynamic firm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Firm Info
              Center(
                child: Column(
                  children: [
                    Text(firm.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accentGold)),
                    const SizedBox(height: 2),
                    Text('${firm.address} | મો: ${firm.phone}', style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                  ],
                ),
              ),
              const Divider(height: 24, color: AppColors.cardBorderDark),
              // Customer & Bill Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ગ્રાહક: ${bill.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('ગ્રાહક કોડ: #${bill.customerNo}', style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('બિલ નં: ${bill.billNo}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                      Text('મહિનો: ${bill.monthYear}', style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Itemized Table
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('પેપર / સામયિક', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(child: Text('દિવસ', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          Expanded(child: Text('રકમ (₹)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.cardBorderDark),
                    ...bill.paperBreakdown.values.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(item.name, style: const TextStyle(fontSize: 13))),
                              Expanded(child: Text('${item.daysCount}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                              Expanded(child: Text('₹${item.totalCost.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Summary Totals
              if (bill.deliveryCharge > 0)
                _buildSummaryRow('માસિક વિતરણ ચાર્જ (Delivery):', '₹${bill.deliveryCharge.toStringAsFixed(0)}'),
              if (bill.vacationDeduction > 0)
                _buildSummaryRow('રજા કપાત (${bill.vacationDays} દિવસ):', '-₹${bill.vacationDeduction.toStringAsFixed(0)}', color: AppColors.errorRed),
              if (bill.pastBalance > 0)
                _buildSummaryRow('પાછલી બાકી રકમ (Old Arrears):', '₹${bill.pastBalance.toStringAsFixed(0)}'),
              const Divider(height: 16, color: AppColors.cardBorderDark),
              _buildSummaryRow('કુલ ચૂકવવાપાત્ર રકમ (Total Due):', '₹${bill.finalPayable.toStringAsFixed(0)}', isBold: true, color: AppColors.accentGold),
              if (bill.paymentReceived > 0)
                _buildSummaryRow('જમા મળેલ (Paid):', '₹${bill.paymentReceived.toStringAsFixed(0)}', color: AppColors.successGreen),
              if (firm.billNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('* ${firm.billNotes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMutedDark)),
              ],
            ],
          ),
        ),
      ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('બંધ કરો')),
          IconButton(
            tooltip: 'UPI QR સ્કેન',
            icon: const Icon(Icons.qr_code, color: AppColors.accentCyan),
            onPressed: () {
              final cust = ref.read(customersProvider).cast<Customer?>().firstWhere((c) => c?.id == bill.customerId, orElse: () => null);
              DynamicUpiDialog.show(context, firm: firm, bill: bill, customer: cust);
            },
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final cust = ref.read(customersProvider).cast<Customer?>().firstWhere((c) => c?.id == bill.customerId, orElse: () => null);
              final route = ref.read(routesProvider).cast<DeliveryRoute?>().firstWhere((r) => r?.id == bill.routeId, orElse: () => null);
              final salesman = route != null ? ref.read(salesmenProvider).cast<Salesman?>().firstWhere((s) => s?.id == route.salesmanId, orElse: () => null) : null;
              BillImageModal.show(context, bill: bill, firm: firm, customer: cust, route: route, salesman: salesman);
            },
            icon: const Icon(Icons.image, size: 16),
            label: const Text('બિલ ઈમેજ / WhatsApp'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              PrintService.printSingleBillPdf(context, bill, firm);
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('પ્રિન્ટ'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.textMutedDark)),
          Text(value, style: TextStyle(fontSize: isBold ? 16 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? Colors.white)),
        ],
      ),
    );
  }

  // 3. WhatsApp Bill Sender / Digital Image Modal
  void _sendWhatsAppBill(BuildContext context, Bill bill, dynamic firm) {
    final cust = ref.read(customersProvider).cast<Customer?>().firstWhere((c) => c?.id == bill.customerId, orElse: () => null);
    final route = ref.read(routesProvider).cast<DeliveryRoute?>().firstWhere((r) => r?.id == bill.routeId, orElse: () => null);
    final salesman = route != null ? ref.read(salesmenProvider).cast<Salesman?>().firstWhere((s) => s?.id == route.salesmanId, orElse: () => null) : null;
    BillImageModal.show(context, bill: bill, firm: firm, customer: cust, route: route, salesman: salesman);
  }

  // 4. Quick Payment Modal
  void _showReceivePaymentModal(BuildContext context, Bill bill) {
    double amount = bill.balanceDue;
    String mode = 'cash';
    String notes = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: Row(
            children: [
              const Icon(Icons.payments, color: AppColors.accentGold),
              const SizedBox(width: 10),
              Text('ચૂકવણી જમા (${bill.customerName})'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('કુલ બાકી રકમ: ₹${bill.balanceDue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.errorRed)),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: amount.toStringAsFixed(0),
                  decoration: const InputDecoration(labelText: 'જમા મળતી રકમ (₹)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => amount = double.tryParse(v) ?? 0.0,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: mode,
                  decoration: const InputDecoration(labelText: 'ચૂકવણી પદ્ધતિ (Payment Mode)', isDense: true),
                  dropdownColor: AppColors.cardDark,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('રોકડ (Cash)')),
                    DropdownMenuItem(value: 'gpay', child: Text('Google Pay / UPI')),
                    DropdownMenuItem(value: 'phonepe', child: Text('PhonePe')),
                    DropdownMenuItem(value: 'cheque', child: Text('ચેક (Cheque)')),
                  ],
                  onChanged: (v) => setModalState(() => mode = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'નોંધ (Notes / Receipt No)'),
                  onChanged: (v) => notes = v,
                ),
              ],
            ),
          ),
        ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton.icon(
              onPressed: () {
                if (amount <= 0) return;
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                final p = Payment(
                  id: DateTime.now().millisecondsSinceEpoch,
                  customerId: bill.customerId,
                  date: DateTime.now().toIso8601String().split('T')[0],
                  amount: amount,
                  paymentMode: mode,
                  billMonthYear: bill.monthYear,
                  notes: notes,
                );
                db.recordPayment(p);
                notifyDbChanged(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('₹${amount.toStringAsFixed(0)} ની ચૂકવણી સફળતાપૂર્વક જમા થઈ ગઈ!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('જમા કરો (Save)'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Bulk Print Formats Selector Modal
  void _showBulkPrintFormatDialog(BuildContext context, List<Bill> bills, dynamic firm) {
    BillPrintFormat selectedFormat = BillPrintFormat.fourInOneClassic;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Row(
            children: [
              Icon(Icons.print, color: AppColors.accentGold),
              SizedBox(width: 10),
              Text('A4 બલ્ક બિલ પ્રિન્ટિંગ'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  'પસંદ કરેલ ${bills.length} બિલો માટે પ્રિન્ટ ફોર્મેટ પસંદ કરો:',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BillPrintFormat>(
                  value: selectedFormat,
                  decoration: const InputDecoration(labelText: 'પ્રિન્ટ લેઆઉટ / ફોર્મેટ', isDense: true),
                  dropdownColor: AppColors.cardDark,
                  items: const [
                    DropdownMenuItem(
                      value: BillPrintFormat.fourInOneClassic,
                      child: Text('✂️ A4 ૪-ઇન-૧: ક્લાસિક B/W ક્રેડિટ મેમો'),
                    ),
                    DropdownMenuItem(
                      value: BillPrintFormat.fourInOneModern,
                      child: Text('✂️ A4 ૪-ઇન-૧: મોડર્ન બ્લુ કાર્ડ (Slate)'),
                    ),
                    DropdownMenuItem(
                      value: BillPrintFormat.fourInOneStub,
                      child: Text('✂️ A4 ૪-ઇન-૧: સ્લિપ + ઉઘરાણી પાવતી (Stub)'),
                    ),
                    DropdownMenuItem(
                      value: BillPrintFormat.threeInOneStrip,
                      child: Text('📑 A4 ૩-ઇન-૧: વાઇડ હોરિઝોન્ટલ સ્લિપ'),
                    ),
                    DropdownMenuItem(
                      value: BillPrintFormat.twoInOneHalfPage,
                      child: Text('📑 A4 ૨-ઇન-૧: વિગતવાર હાફ પેજ બિલ'),
                    ),
                    DropdownMenuItem(
                      value: BillPrintFormat.singleThermal,
                      child: Text('🧾 ૫૮/૮૦mm થર્મલ પીઓએસ રોલ સ્લિપ'),
                    ),
                    DropdownMenuItem(
                      value: BillPrintFormat.fullPageA4,
                      child: Text('📄 A4 સંપૂર્ણ પેજ સ્ટેટમેન્ટ ઇન્વોઇસ'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedFormat = val);
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorderDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: AppColors.primaryTeal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getFormatDescription(selectedFormat, bills.length),
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                PrintService.printMonthBillsPdf(
                  context,
                  bills,
                  firm,
                  '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}',
                  format: selectedFormat,
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('પીડીએફ / પ્રિન્ટ કરો'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatDescription(BillPrintFormat format, int billCount) {
    switch (format) {
      case BillPrintFormat.fourInOneClassic:
        final pages = (billCount / 4).ceil();
        return '૧ A4 પેજ પર ૪ કોમ્પેક્ટ ક્રેડિટ મેમો છપાશે (કુલ $pages પેજ). ઓછો કાગળ અને ઓછા ઇંક વપરાશ માટે શ્રેષ્ઠ.';
      case BillPrintFormat.fourInOneModern:
        final pages = (billCount / 4).ceil();
        return '૧ A4 પેજ પર ૪ પ્રીમિયમ કાર્ડ્સ છપાશે (કુલ $pages પેજ). સુંદર બોર્ડર અને સ્લેટ બ્લુ લેઆઉટ.';
      case BillPrintFormat.fourInOneStub:
        final pages = (billCount / 4).ceil();
        return '૧ A4 પેજ પર ૪ બિલ + જમણી બાજુ કલેક્શન કાઉન્ટરફોઇલ પાવતી (Stub) છપાશે (કુલ $pages પેજ).';
      case BillPrintFormat.threeInOneStrip:
        final pages = (billCount / 3).ceil();
        return '૧ A4 પેજ પર ૩ આડી વાઇડ સ્લિપ્સ + સાઇડ રિસીપ્ટ પાવતી છપાશે (કુલ $pages પેજ).';
      case BillPrintFormat.twoInOneHalfPage:
        final pages = (billCount / 2).ceil();
        return '૧ A4 પેજ પર ૨ વિગતવાર કમર્શિયલ ઇન્વોઇસ છપાશે (કુલ $pages પેજ).';
      case BillPrintFormat.singleThermal:
        return '૫૮mm અથવા ૮૦mm થર્મલ પ્રિન્ટર માટે રોલ પ્રિન્ટઆઉટ.';
      case BillPrintFormat.fullPageA4:
        return 'દરેક ગ્રાહક માટે ૧ આખું A4 પેજ સ્ટેટમેન્ટ છપાશે (કુલ $billCount પેજ).';
    }
  }
}

