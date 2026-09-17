import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/customer.dart';
import '../../core/models/item.dart';
import '../../core/models/mass_issue.dart';
import '../../core/models/vacation.dart';
import '../../core/models/route.dart';

class VacationsView extends StatefulWidget {
  const VacationsView({super.key});

  @override
  State<VacationsView> createState() => _VacationsViewState();
}

class _VacationsViewState extends State<VacationsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  // 1. Customer Vacation Dialog (with Search Bar & Salesman Combo)
  void _openVacationDialog() {
    final db = DatabaseService.instance;
    int? selectedCustId = db.customers.isNotEmpty ? db.customers.first.id : null;
    int? selectedSalesmanId;
    String custSearchQuery = '';
    final searchCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 3));
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          // Filter customers by salesman and search query
          final filteredCusts = db.customers.where((c) {
            if (c.status != 'active') return false;

            if (selectedSalesmanId != null) {
              final r = db.routes.cast<DeliveryRoute?>().firstWhere((rt) => rt?.id == c.routeId, orElse: () => null);
              if (r?.salesmanId != selectedSalesmanId) return false;
            }

            if (custSearchQuery.trim().isNotEmpty) {
              final q = custSearchQuery.toLowerCase();
              final matchName = c.name.toLowerCase().contains(q);
              final matchMobile = c.mobile.contains(q);
              final matchCode = c.code.toLowerCase().contains(q);
              final matchCustNo = c.custNo.contains(q);
              final matchSeq = c.sequenceNo.contains(q);
              if (!matchName && !matchMobile && !matchCode && !matchCustNo && !matchSeq) return false;
            }

            return true;
          }).toList();

          final selectedCust = db.customers.cast<Customer?>().firstWhere((c) => c?.id == selectedCustId, orElse: () => null);

          return AlertDialog(
            backgroundColor: AppColors.bgCardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.beach_access, color: AppColors.accentGold),
                SizedBox(width: 8),
                Text('🌴 નવી ગ્રાહક રજા (Customer Vacation)'),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Salesman combo & Search Bar
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<int?>(
                            value: selectedSalesmanId,
                            dropdownColor: AppColors.bgCardDark,
                            decoration: const InputDecoration(labelText: '🚴 વિતરક પસંદ કરો', isDense: true),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('બધા વિતરક (All)')),
                              ...db.salesmen.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
                            ],
                            onChanged: (v) => setDlgState(() {
                              selectedSalesmanId = v;
                            }),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: searchCtrl,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search, size: 18),
                              labelText: 'ગ્રાહક શોધો (નામ, કોડ, મોબાઇલ)',
                              isDense: true,
                            ),
                            onChanged: (v) => setDlgState(() {
                              custSearchQuery = v;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Customer Selection list
                    const Text('ગ્રાહક પસંદ કરો:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: filteredCusts.isEmpty
                          ? const Center(child: Text('કોઈ ગ્રાહક મળ્યા નથી', style: TextStyle(color: AppColors.textMutedDark)))
                          : ListView.builder(
                              itemCount: filteredCusts.length,
                              itemBuilder: (cCtx, i) {
                                final cust = filteredCusts[i];
                                final isSel = cust.id == selectedCustId;
                                final route = db.routes.cast<DeliveryRoute?>().firstWhere((r) => r?.id == cust.routeId, orElse: () => null);

                                return InkWell(
                                  onTap: () => setDlgState(() => selectedCustId = cust.id),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSel ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                                      border: Border(bottom: BorderSide(color: AppColors.borderDark.withOpacity(0.4))),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(isSel ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: isSel ? AppColors.accentCyan : AppColors.textMutedDark),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(cust.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSel ? AppColors.accentCyan : Colors.white)),
                                              Text('${cust.code.isNotEmpty ? cust.code : "C-" + cust.id.toString()} • ${route?.name ?? "લાઇન"} • 📞 ${cust.mobile}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (selectedCust != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.primaryTeal, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'પસંદ કરેલ: ${selectedCust.name} (${selectedCust.code}) - 📞 ${selectedCust.mobile}',
                                style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Date range
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final p = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (p != null) setDlgState(() => startDate = p);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'શરૂ તારીખ', isDense: true),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat('dd/MM/yyyy').format(startDate), style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  const Icon(Icons.calendar_today, size: 14, color: AppColors.accentCyan),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final p = await showDatePicker(context: ctx, initialDate: endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (p != null) setDlgState(() => endDate = p);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'અંતિમ તારીખ', isDense: true),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat('dd/MM/yyyy').format(endDate), style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  const Icon(Icons.calendar_today, size: 14, color: AppColors.accentCyan),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(labelText: 'કારણ / નોંધ (વિકલ્પિક)', isDense: true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
              ElevatedButton(
                onPressed: () {
                  if (selectedCustId == null) return;
                  final id = db.vacations.isEmpty ? 1 : db.vacations.map((v) => v.id).reduce((a, b) => a > b ? a : b) + 1;
                  db.vacations.add(Vacation(
                    id: id,
                    customerId: selectedCustId!,
                    startDate: DateFormat('yyyy-MM-dd').format(startDate),
                    endDate: DateFormat('yyyy-MM-dd').format(endDate),
                    reason: reasonCtrl.text.trim(),
                  ));
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: const Text('સાચવો'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 2. Mass Issue (Bonus Paper) Dialog
  void _openMassIssueDialog() {
    final db = DatabaseService.instance;
    int selectedItemId = db.items.isNotEmpty ? db.items.first.id : 1;
    DateTime date = DateTime.now().add(const Duration(days: 1));
    String targetType = 'all'; // 'all' or 'day_wise'
    final saleCtrl = TextEditingController(text: '5.0');
    final purCtrl = TextEditingController(text: '3.32');
    final reasonCtrl = TextEditingController();
    bool holidayForOthers = true;

    final dayNamesGu = ['રવિવાર', 'સોમવાર', 'મંગળવાર', 'બુધવાર', 'ગુરુવાર', 'શુક્રવાર', 'શનિવાર'];

    void updateRates(StateSetter setDlgState) {
      final it = db.items.cast<Item?>().firstWhere((i) => i?.id == selectedItemId, orElse: () => null);
      if (it != null) {
        final rates = it.getRateForDay(date.weekday % 7);
        saleCtrl.text = rates.sale.toString();
        purCtrl.text = rates.purchase.toString();
      }
      setDlgState(() {});
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final dayName = dayNamesGu[date.weekday % 7];

          return AlertDialog(
            backgroundColor: AppColors.bgCardDark,
            title: const Text('🎁 નવું બોનસ પેપર (Mass Issue)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedItemId,
                    dropdownColor: AppColors.bgCardDark,
                    decoration: const InputDecoration(labelText: 'પેપર પસંદ કરો'),
                    items: db.items.map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.code})'))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        selectedItemId = v;
                        updateRates(setDlgState);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () async {
                      final p = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (p != null) {
                        date = p;
                        updateRates(setDlgState);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'તારીખ'),
                      child: Text('${DateFormat('dd/MM/yyyy').format(date)} ($dayName)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🎯 કયા ગ્રાહકોને બોનસ પેપર આપવું છે?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 13)),
                        const SizedBox(height: 6),
                        RadioListTile<String>(
                          value: 'all',
                          groupValue: targetType,
                          title: const Text('🌐 તમારા બધા જ ગ્રાહકોને (All Customers)', style: TextStyle(fontSize: 13)),
                          subtitle: const Text('તમામ સક્રિય ગ્રાહકોને વિતરણ થશે', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (v) => setDlgState(() => targetType = v!),
                        ),
                        RadioListTile<String>(
                          value: 'day_wise',
                          groupValue: targetType,
                          title: Text('📅 $dayName ના બધા ગ્રાહકોને', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warningLight)),
                          subtitle: Text('માત્ર $dayName ના રોજ પેપર લેતા ગ્રાહકોને જ મળશે', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (v) => setDlgState(() => targetType = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: saleCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'વેચાણ ભાવ (MRP) ₹', prefixText: '₹'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: purCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'ડેપો ખરીદ ભાવ (PTR) ₹',
                            prefixText: '₹',
                            labelStyle: TextStyle(color: AppColors.dangerLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  CheckboxListTile(
                    value: holidayForOthers,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('આ દિવસે અન્ય પેપરોની રજા રાખવી?', style: TextStyle(fontSize: 13)),
                    onChanged: (v) => setDlgState(() => holidayForOthers = v ?? true),
                  ),
                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(labelText: 'નોંધ / કારણ (દા.ત. દિવાળી વિશેષાંક)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
              ElevatedButton(
                onPressed: () {
                  final id = db.massIssues.isEmpty ? 1 : db.massIssues.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
                  db.massIssues.add(MassIssue(
                    id: id,
                    itemId: selectedItemId,
                    date: DateFormat('yyyy-MM-dd').format(date),
                    rate: double.tryParse(saleCtrl.text) ?? 0.0,
                    purchaseRate: double.tryParse(purCtrl.text) ?? 0.0,
                    targetType: targetType,
                    holidayForOthers: holidayForOthers,
                    reason: reasonCtrl.text.trim(),
                  ));
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: const Text('સાચવો (Save)'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 3. Paper Festival Holiday Dialog (Matching Image 1)
  void _openPaperHolidayDialog() {
    final db = DatabaseService.instance;
    final selectedPaperIds = db.items.map((i) => i.id).toSet();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final items = db.items;

          return Dialog(
            backgroundColor: const Color(0xFF1E2638),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              width: 680,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'addPaperHoliday',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header bar: Title and Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.description_outlined, color: AppColors.accentCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'રજા રાખવાના પેપર્સ ટીક કરો',
                            style: TextStyle(
                              color: AppColors.accentCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Select All Button
                          InkWell(
                            onTap: () {
                              setDlgState(() {
                                selectedPaperIds.clear();
                                selectedPaperIds.addAll(items.map((i) => i.id));
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B3830),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.6)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.check_box, color: Color(0xFF4CAF50), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'બધા પસંદ કરો',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Deselect All Button
                          InkWell(
                            onTap: () {
                              setDlgState(() {
                                selectedPaperIds.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF381E24),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.6)),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.cancel, color: Color(0xFFEF5350), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'બધા હટાવો',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2-Column Grid of Papers
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141A28),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A364F)),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: items.isEmpty
                        ? const Center(child: Text('કોઈ પેપર ઉપલબ્ધ નથી', style: TextStyle(color: Colors.white54)))
                        : Scrollbar(
                            thumbVisibility: true,
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 4.6,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final item = items[i];
                                final isChecked = selectedPaperIds.contains(item.id);

                                return InkWell(
                                  onTap: () {
                                    setDlgState(() {
                                      if (isChecked) {
                                        selectedPaperIds.remove(item.id);
                                      } else {
                                        selectedPaperIds.add(item.id);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E283C),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isChecked ? const Color(0xFF1976D2).withOpacity(0.7) : const Color(0xFF2D3B55),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: isChecked,
                                            activeColor: const Color(0xFF1E88E5),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                            onChanged: (v) {
                                              setDlgState(() {
                                                if (v == true) {
                                                  selectedPaperIds.add(item.id);
                                                } else {
                                                  selectedPaperIds.remove(item.id);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${item.name} (${item.code})',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),

                  // Hint Text
                  const Text(
                    'જે પેપર્સમાં રજા રાખવી હોય તે ટીક કરો (દા.ત. દિવાળી કે રાષ્ટ્રીય રજા પર બધા પસંદ કરો)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
                  ),
                  const SizedBox(height: 16),

                  // Dates Row
                  Row(
                    children: [
                      // Start Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'આ તારીખથી',
                              style: TextStyle(fontSize: 13, color: Color(0xFFB0BEC5), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final p = await showDatePicker(
                                  context: ctx,
                                  initialDate: startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (p != null) {
                                  setDlgState(() {
                                    startDate = p;
                                    if (endDate.isBefore(startDate)) endDate = startDate;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141A28),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF2D3B55)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(startDate),
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    const Icon(Icons.calendar_month, color: Color(0xFF78909C), size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // End Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'આ તારીખ સુધી',
                              style: TextStyle(fontSize: 13, color: Color(0xFFB0BEC5), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final p = await showDatePicker(
                                  context: ctx,
                                  initialDate: endDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (p != null) {
                                  setDlgState(() => endDate = p);
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141A28),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF2D3B55)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(endDate),
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    const Icon(Icons.calendar_month, color: Color(0xFF78909C), size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF263238),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('રદ કરો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (selectedPaperIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('કૃપા કરીને ઓછામાં ઓછું એક પેપર પસંદ કરો!')),
                            );
                            return;
                          }

                          final sDate = DateFormat('yyyy-MM-dd').format(startDate);
                          final eDate = DateFormat('yyyy-MM-dd').format(endDate);

                          for (final itemId in selectedPaperIds) {
                            final hId = db.paperHolidays.isEmpty ? 1 : db.paperHolidays.map((h) => h.id).reduce((a, b) => a > b ? a : b) + 1;
                            db.paperHolidays.add(PaperHoliday(
                              id: hId,
                              itemId: itemId,
                              startDate: sDate,
                              endDate: eDate,
                              reason: 'પ્રેસ રજા',
                            ));
                          }

                          Navigator.pop(ctx);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${selectedPaperIds.length} પેપરોની રજા સાચવી લેવામાં આવી!'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        },
                        child: const Text('રજા સાચવો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.bgCardDark,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondaryDark,
            tabs: const [
              Tab(icon: Icon(Icons.beach_access, size: 18), text: 'ગ્રાહક રજાઓ (Vacations)'),
              Tab(icon: Icon(Icons.card_giftcard, size: 18), text: 'બોનસ પેપર્સ (Mass Issues)'),
              Tab(icon: Icon(Icons.event_busy, size: 18), text: 'પેપર તહેવાર રજાઓ (Holidays)'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Customer Vacations
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ ગ્રાહક રજાઓ: ${db.vacations.length}', style: const TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600)),
                    ElevatedButton.icon(
                      onPressed: _openVacationDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવી રજા ઉમેરો'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: db.vacations.isEmpty
                      ? const Center(child: Text('કોઈ ગ્રાહક રજા નોંધાયેલ નથી'))
                      : ListView.builder(
                          itemCount: db.vacations.length,
                          itemBuilder: (ctx, i) {
                            final v = db.vacations[i];
                            final cust = db.customers.cast<Customer?>().firstWhere((c) => c?.id == v.customerId, orElse: () => null);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.bgSurfaceDark,
                                  child: Text('🌴'),
                                ),
                                title: Text(cust?.name ?? 'ગ્રાહક #${v.customerId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('તારીખ: ${v.startDate} થી ${v.endDate} ${v.reason.isNotEmpty ? "• " + v.reason : ""}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerLight),
                                  onPressed: () {
                                    setState(() => db.vacations.removeAt(i));
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Tab 2: Mass Issues
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ બોનસ પેપર્સ: ${db.massIssues.length}', style: const TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600)),
                    ElevatedButton.icon(
                      onPressed: _openMassIssueDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવું બોનસ પેપર'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: db.massIssues.isEmpty
                      ? const Center(child: Text('કોઈ બોનસ પેપર નોંધાયેલ નથી'))
                      : ListView.builder(
                          itemCount: db.massIssues.length,
                          itemBuilder: (ctx, i) {
                            final m = db.massIssues[i];
                            final it = db.items.cast<Item?>().firstWhere((item) => item?.id == m.itemId, orElse: () => null);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.bgSurfaceDark,
                                  child: Text('🎁'),
                                ),
                                title: Text(it?.name ?? 'પેપર #${m.itemId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  'તારીખ: ${m.date} • વેચાણ: ₹${m.rate} • ખરીદ (PTR): ₹${m.purchaseRate} • લક્ષિત: ${m.targetType == "day_wise" ? "વાર મુજબ" : "બધા ગ્રાહકો"}',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerLight),
                                  onPressed: () {
                                    setState(() => db.massIssues.removeAt(i));
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Tab 3: Paper Festival Holidays
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ પેપર તહેવાર રજાઓ: ${db.paperHolidays.length}', style: const TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _openPaperHolidayDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવી પેપર રજા ઉમેરો', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: db.paperHolidays.isEmpty
                      ? const Center(child: Text('કોઈ પેપર તહેવાર રજા નોંધાયેલ નથી'))
                      : ListView.builder(
                          itemCount: db.paperHolidays.length,
                          itemBuilder: (ctx, i) {
                            final h = db.paperHolidays[i];
                            final it = db.items.cast<Item?>().firstWhere((item) => item?.id == h.itemId, orElse: () => null);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.bgSurfaceDark,
                                  child: Text('🚫'),
                                ),
                                title: Text(it?.name ?? 'પેપર #${h.itemId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text(
                                  'તારીખ: ${h.startDate} થી ${h.endDate} • ${h.reason.isNotEmpty ? h.reason : "પ્રેસ રજા"}',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerLight),
                                  onPressed: () {
                                    setState(() => db.paperHolidays.removeAt(i));
                                  },
                                ),
                              ),
                            );
                          },
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
