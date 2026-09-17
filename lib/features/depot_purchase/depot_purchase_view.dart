import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/item.dart';
import '../../core/models/press_return.dart';
import '../../core/printing/print_service.dart';
import '../../core/providers/app_providers.dart';

class DepotPurchaseView extends ConsumerStatefulWidget {
  const DepotPurchaseView({super.key});

  @override
  ConsumerState<DepotPurchaseView> createState() => _DepotPurchaseViewState();
}

class _DepotPurchaseViewState extends ConsumerState<DepotPurchaseView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 1));
  final Map<int, int> _customExtraCopies = {};

  String _selectedMonthYear = DateFormat('yyyy-MM').format(DateTime.now());

  final List<String> _dayNamesGu = [
    'રવિવાર', 'સોમવાર', 'મંગળવાર', 'બુધવાર', 'ગુરુવાર', 'શુક્રવાર', 'શનિવાર'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onExtraCopiesChanged(int itemId, String val) {
    final count = int.tryParse(val) ?? 0;
    setState(() {
      _customExtraCopies[itemId] = count;
    });
  }

  void _openAddReturnDialog() {
    final db = DatabaseService.instance;
    DateTime returnDate = DateTime.now();
    int? selectedItemId = db.items.isNotEmpty ? db.items.first.id : null;
    final copiesCtrl = TextEditingController(text: '5');
    final notesCtrl = TextEditingController(text: 'વધેલા પેપર્સ પ્રેસમાં પરત');

    Item? selectedItem = db.items.cast<Item?>().firstWhere((i) => i?.id == selectedItemId, orElse: () => null);
    double creditRate = selectedItem?.defaultPurchaseRate ?? 3.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgCardDark,
          title: const Row(
            children: [
              Text('🔄 ', style: TextStyle(fontSize: 20)),
              Text('વધેલા / ન વેચાયેલા પેપર રીટર્ન એન્ટ્રી', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: returnDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDlgState(() => returnDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('રીટર્ન તારીખ:', style: TextStyle(color: AppColors.textMutedDark)),
                        Text(DateFormat('dd/MM/yyyy').format(returnDate), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Item Dropdown
                DropdownButtonFormField<int>(
                  value: selectedItemId,
                  dropdownColor: AppColors.bgCardDark,
                  decoration: const InputDecoration(labelText: 'અખબાર / પેપર પસંદ કરો'),
                  items: db.items.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.code})'))).toList(),
                  onChanged: (v) {
                    setDlgState(() {
                      selectedItemId = v;
                      selectedItem = db.items.cast<Item?>().firstWhere((i) => i?.id == v, orElse: () => null);
                      creditRate = selectedItem?.defaultPurchaseRate ?? 3.0;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Copies
                TextField(
                  controller: copiesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'પરત આપેલ નકલો (Copies)', suffixText: 'નકલ'),
                ),
                const SizedBox(height: 12),

                // Credit rate display
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ખરીદ ભાવ (Credit Rate):', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                      Text('₹${creditRate.toStringAsFixed(2)} / નકલ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'નોંધ (Remarks)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton(
              onPressed: () {
                final copies = int.tryParse(copiesCtrl.text) ?? 0;
                if (copies <= 0 || selectedItemId == null) return;

                final creditAmt = copies * creditRate;
                final rId = db.pressReturns.isEmpty ? 1 : db.pressReturns.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;

                db.pressReturns.add(PressReturnEntry(
                  id: rId,
                  date: DateFormat('yyyy-MM-dd').format(returnDate),
                  itemId: selectedItemId!,
                  itemName: selectedItem?.name ?? 'પેપર',
                  copies: copies,
                  creditRate: creditRate,
                  creditAmount: creditAmt,
                  notes: notesCtrl.text.trim(),
                ));

                notifyDbChanged(ref);
                Navigator.pop(ctx);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.successGreen,
                    content: Text('✅ $copies નકલ પેપર રીટર્ન જમા થઈ! (ક્રેડિટ: ₹${creditAmt.toStringAsFixed(2)})'),
                  ),
                );
              },
              child: const Text('જમા કરો'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String val, Color valColor, {String? subtitle, IconData? icon}) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: valColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: valColor, size: 22),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                  const SizedBox(height: 4),
                  Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valColor)),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
                  ],
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
    final db = DatabaseService.instance;
    final dateStr = DateFormat('yyyy-MM-dd').format(_targetDate);
    final dayOfWeek = _targetDate.weekday % 7;
    final dayName = _dayNamesGu[dayOfWeek];

    final sheet = db.getDepotPurchaseSheet(dateStr, _customExtraCopies);
    final pressReturns = ref.watch(pressReturnsProvider);
    final reconciliation = db.getPressReconciliation(_selectedMonthYear);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.bgCardDark,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryTeal,
            labelColor: AppColors.primaryTeal,
            unselectedLabelColor: AppColors.textSecondaryDark,
            tabs: const [
              Tab(icon: Icon(Icons.storefront, size: 18), text: '🏬 દૈનિક ડેપો ઓર્ડર શીટ'),
              Tab(icon: Icon(Icons.assignment_return, size: 18), text: '🔄 ન વેચાયેલા પેપર્સ રીટર્ન'),
              Tab(icon: Icon(Icons.receipt_long, size: 18), text: '📊 માસિક પ્રેસ ખરીદી સ્ટેટમેન્ટ'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tomorrow's / Target Date Demand & Order Sheet (Matching Image 4)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Date Selector, Quick Buttons & Info Row (Matching Image 4)
                Card(
                  color: const Color(0xFF161E2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF222F46))),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storefront, color: Color(0xFF42A5F5), size: 22),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🏬 ડેપો ખરીદી ઓર્ડર શીટ (સાંજનું સેલ)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                Text(
                                  'તારીખ: ${DateFormat("dd/MM/yyyy").format(_targetDate)} ($dayName)',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFFFB74D), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Date Action Buttons Group
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Date Picker Box
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _targetDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setState(() => _targetDate = picked);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111722),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF2A364F)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_month, size: 16, color: Color(0xFF42A5F5)),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_targetDate),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_drop_down, color: Color(0xFF90A4AE), size: 18),
                                  ],
                                ),
                              ),
                            ),

                            // Quick "📅 આવતીકાલ" Button
                            Builder(
                              builder: (context) {
                                final isTomorrow = DateFormat('yyyy-MM-dd').format(_targetDate) ==
                                    DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));
                                return ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isTomorrow ? const Color(0xFF00ACC1) : const Color(0xFF141F32),
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: isTomorrow ? const Color(0xFF26C6DA) : const Color(0xFF1E88E5).withOpacity(0.4)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _targetDate = DateTime.now().add(const Duration(days: 1));
                                    });
                                  },
                                  icon: const Icon(Icons.event, size: 16),
                                  label: const Text('📅 આવતીકાલ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                );
                              },
                            ),

                            // Quick "📅 આજે" Button
                            Builder(
                              builder: (context) {
                                final isToday = DateFormat('yyyy-MM-dd').format(_targetDate) ==
                                    DateFormat('yyyy-MM-dd').format(DateTime.now());
                                return ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isToday ? const Color(0xFF2E7D32) : const Color(0xFF141F32),
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: isToday ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32).withOpacity(0.4)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _targetDate = DateTime.now();
                                    });
                                  },
                                  icon: const Icon(Icons.today, size: 16),
                                  label: const Text('📅 આજે', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                );
                              },
                            ),

                            // Print Slip Button
                            ElevatedButton.icon(
                              onPressed: () {
                                PrintService.printDepotPurchaseSheetPdf(context, sheet, db.firm);
                              },
                              icon: const Icon(Icons.print, size: 16),
                              label: const Text('🖨️ ડેપો સ્લિપ પ્રિન્ટ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 4 Summary KPI Cards (Matching Image 4)
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'કુલ ખરીદવાની નકલ',
                        '${sheet.totalCopies}',
                        AppColors.primaryLight,
                        subtitle: 'ગ્રાહક: ${sheet.totalCustomerCopies} + કાઉન્ટર: ${sheet.totalExtraCopies}',
                        icon: Icons.inventory_2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        'ડેપોને ચૂકવવાની રકમ',
                        '₹${sheet.totalPurchaseAmount.toStringAsFixed(2)}',
                        AppColors.dangerLight,
                        subtitle: 'ખરીદ ભાવ (PTR) મુજબ ચૂકવણી',
                        icon: Icons.send,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        'અપેક્ષિત વેચાણ રકમ',
                        '₹${sheet.totalSalesValue.toStringAsFixed(0)}',
                        AppColors.accentGold,
                        subtitle: 'વેચાણ ભાવ (MRP) મુજબ ગણતરી',
                        icon: Icons.monetization_on,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        'અપેક્ષિત નફો / માર્જિન',
                        '₹${sheet.totalProfit.toStringAsFixed(2)}',
                        AppColors.successLight,
                        subtitle: 'કુલ નફો / માર્જિન',
                        icon: Icons.auto_awesome,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Item-wise Purchase Table with 10 Columns (Matching Image 4 & 2)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '📋 પેપર મુજબ ખરીદી અને ચૂકવણી વિગત ($dayName, ${DateFormat('dd/MM/yyyy').format(_targetDate)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                            const Text(
                              '* કાઉન્ટર/વધારાની નકલ બદલીને Enter દબાવો',
                              style: TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Table(
                          border: TableBorder(
                            horizontalInside: BorderSide(color: AppColors.borderDark.withOpacity(0.5)),
                          ),
                          columnWidths: const {
                            0: FixedColumnWidth(90),  // કોડ
                            1: FlexColumnWidth(2.5),  // પેપરનું નામ
                            2: FixedColumnWidth(85),  // ગ્રાહક માંગ
                            3: FixedColumnWidth(80),  // કાઉન્ટર નકલ (Compact width matching Image 2!)
                            4: FixedColumnWidth(85),  // કુલ ખરીદી
                            5: FixedColumnWidth(95),  // ખરીદ ભાવ (PTR)
                            6: FixedColumnWidth(115), // ડેપોને ચૂકવવાના
                            7: FixedColumnWidth(95),  // વેચાણ ભાવ (MRP)
                            8: FixedColumnWidth(100), // વેચાણ રકમ
                            9: FixedColumnWidth(100), // નફો
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: AppColors.surfaceDark.withOpacity(0.6)),
                              children: const [
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('કોડ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('પેપરનું નામ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('ગ્રાહક માંગ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('કાઉન્ટર', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('કુલ ખરીદી', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('ખરીદ ભાવ', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('ડેપોને ચૂકવવાના', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('વેચાણ ભાવ', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('વેચાણ રકમ', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), child: Text('નફો (₹)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark, fontSize: 12))),
                              ],
                            ),
                            ...sheet.items.map((it) {
                              final codeText = it.code.isNotEmpty ? it.code : it.name.split(' ').first;

                              return TableRow(
                                children: [
                                  // 1. Code Badge
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                                      ),
                                      child: Text(
                                        codeText,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),

                                  // 2. Paper Name
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            it.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (it.isHoliday) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('રજા', style: TextStyle(fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // 3. Customer Demand
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    child: Text(
                                      '${it.customerCopies}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontSize: 13),
                                    ),
                                  ),

                                  // 4. Counter Extra Copies (Compact Input Box matching Image 2!)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    child: Center(
                                      child: SizedBox(
                                        width: 58,
                                        height: 28,
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.zero,
                                            hintText: '${it.extraCopies}',
                                            hintStyle: const TextStyle(color: AppColors.textMutedDark),
                                            fillColor: AppColors.surfaceDark,
                                            filled: true,
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(color: AppColors.borderDark),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(14),
                                              borderSide: const BorderSide(color: AppColors.accentCyan, width: 1.2),
                                            ),
                                          ),
                                          onChanged: (v) => _onExtraCopiesChanged(it.id, v),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 5. Total Purchase
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    child: Text(
                                      '${it.totalCopies}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                  ),

                                  // 6. PTR Purchase Rate
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    child: Text('₹${it.purchaseRate.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                                  ),

                                  // 7. Depot Payable (Rs)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    child: Text('₹${it.purchaseAmount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dangerLight, fontSize: 12)),
                                  ),

                                  // 8. MRP Sale Rate
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    child: Text('₹${it.saleRate.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                                  ),

                                  // 9. Sales Value (Rs)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    child: Text('₹${it.salesValue.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                                  ),

                                  // 10. Profit (Rs)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    child: Text('₹${it.profit.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successLight, fontSize: 12)),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab 2: Unsold Returns & Credit Notes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ રીટર્ન એન્ટ્રીઓ: ${pressReturns.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                      onPressed: _openAddReturnDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવી રીટર્ન એન્ટ્રી ઉમેરો'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: pressReturns.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_return_outlined, size: 48, color: AppColors.textMutedDark),
                              SizedBox(height: 12),
                              Text('કોઈ પેપર રીટર્ન એન્ટ્રી નોંધાયેલ નથી', style: TextStyle(color: AppColors.textSecondaryDark)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: pressReturns.length,
                          itemBuilder: (ctx, i) {
                            final r = pressReturns[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.newspaper, color: AppColors.primaryTeal, size: 20),
                                ),
                                title: Row(
                                  children: [
                                    Text(r.itemName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${r.copies} નકલ પરત',
                                        style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '📅 તારીખ: ${r.date} | ખરીદ દર: ₹${r.creditRate.toStringAsFixed(2)} ${r.notes.isNotEmpty ? "\n💬 " + r.notes : ""}',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '+₹${r.creditAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.successGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerLight),
                                      onPressed: () {
                                        setState(() => db.pressReturns.removeAt(i));
                                        notifyDbChanged(ref);
                                      },
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

          // Tab 3: Monthly Press Supply & Reconciliation Statement
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Picker & Action Banner
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt_long, color: AppColors.purple, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📊 માસિક પ્રેસ ખરીદી અને સપ્લાય સ્ટેટમેન્ટ',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                Text(
                                  'કુલ સપ્લાય થયેલ નકલો - રીટર્ન ક્રેડિટ = પ્રેસને નેટ ચૂકવણી',
                                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Month Dropdown
                        DropdownButton<String>(
                          value: _selectedMonthYear,
                          dropdownColor: AppColors.bgCardDark,
                          items: [
                            DropdownMenuItem(value: DateFormat('yyyy-MM').format(DateTime.now()), child: Text('ચાલુ મહિનો (${DateFormat('MMMM yyyy').format(DateTime.now())})')),
                            DropdownMenuItem(value: DateFormat('yyyy-MM').format(DateTime.now().subtract(const Duration(days: 30))), child: Text('ગત મહિનો (${DateFormat('MMMM yyyy').format(DateTime.now().subtract(const Duration(days: 30)))})')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedMonthYear = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Reconciliation KPI Summary
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final count = constraints.maxWidth >= 900 ? 4 : 2;
                    return GridView.count(
                      crossAxisCount: count,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: [
                        _buildSummaryCard('કુલ સપ્લાય નકલો', '${reconciliation.totalSuppliedCopies} નકલ', Colors.white),
                        _buildSummaryCard('ગ્રોસ ખરીદી રકમ', '₹${reconciliation.totalGrossPurchase.toStringAsFixed(2)}', AppColors.dangerLight),
                        _buildSummaryCard('રીટર્ન ક્રેડિટ કપાત', '-₹${reconciliation.totalReturnCredits.toStringAsFixed(2)}', AppColors.successLight),
                        _buildSummaryCard('પ્રેસને નેટ ચૂકવવાપાત્ર', '₹${reconciliation.netPayableToPress.toStringAsFixed(2)}', AppColors.accentGold),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Reconciliation Items Table
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📰 પેપર વાઇઝ માસિક ખરીદી અને રીટર્ન વિગત',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Table(
                          border: TableBorder(
                            horizontalInside: BorderSide(color: AppColors.borderDark.withOpacity(0.5)),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(2.5),
                            1: FlexColumnWidth(1.2),
                            2: FlexColumnWidth(1.2),
                            3: FlexColumnWidth(1.5),
                            4: FlexColumnWidth(1.2),
                            5: FlexColumnWidth(1.5),
                            6: FlexColumnWidth(1.5),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: AppColors.surfaceDark.withOpacity(0.5)),
                              children: const [
                                Padding(padding: EdgeInsets.all(8), child: Text('અખબાર / પેપર', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                                Padding(padding: EdgeInsets.all(8), child: Text('સપ્લાય નકલ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                                Padding(padding: EdgeInsets.all(8), child: Text('સરેરાશ દર', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                                Padding(padding: EdgeInsets.all(8), child: Text('ગ્રોસ ખરીદી (₹)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                                Padding(padding: EdgeInsets.all(8), child: Text('રીટર્ન નકલ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                                Padding(padding: EdgeInsets.all(8), child: Text('રીટર્ન ક્રેડિટ (₹)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                                Padding(padding: EdgeInsets.all(8), child: Text('નેટ ચૂકવવાપાત્ર (₹)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                              ],
                            ),
                            ...reconciliation.itemsSummary.map((it) {
                              return TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(8), child: Text(it.itemName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('${it.suppliedCopies}', textAlign: TextAlign.center)),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('₹${it.avgPurchaseRate.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('₹${it.grossPurchase.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.dangerLight))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('${it.returnedCopies}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.warning))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('-₹${it.returnCredits.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.successLight))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('₹${it.netPayable.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold))),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
