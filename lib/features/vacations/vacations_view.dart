import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/customer.dart';
import '../../core/models/item.dart';
import '../../core/models/mass_issue.dart';
import '../../core/models/vacation.dart';

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

  // 1. Customer Vacation Dialog
  void _openVacationDialog() {
    final db = DatabaseService.instance;
    int? selectedCustId = db.customers.isNotEmpty ? db.customers.first.id : null;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 3));
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgCardDark,
          title: const Text('🌴 નવી ગ્રાહક રજા (Customer Vacation)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedCustId,
                  dropdownColor: AppColors.bgCardDark,
                  decoration: const InputDecoration(labelText: 'ગ્રાહક પસંદ કરો'),
                  items: db.customers.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.code.isNotEmpty ? c.code : c.sequenceNo})'))).toList(),
                  onChanged: (v) => setDlgState(() => selectedCustId = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final p = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (p != null) setDlgState(() => startDate = p);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'શરૂ તારીખ'),
                          child: Text(DateFormat('dd/MM/yyyy').format(startDate), style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final p = await showDatePicker(context: ctx, initialDate: endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (p != null) setDlgState(() => endDate = p);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'અંતિમ તારીખ'),
                          child: Text(DateFormat('dd/MM/yyyy').format(endDate), style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'કારણ / નોંધ (વિકલ્પિક)'),
                ),
              ],
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
        ),
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

  // 3. Paper Festival Holiday Dialog
  void _openPaperHolidayDialog() {
    final db = DatabaseService.instance;
    int? selectedItemId = 0; // 0 means All Papers
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    final reasonCtrl = TextEditingController(text: 'તહેવાર / પ્રેસ રજા');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgCardDark,
          title: const Text('📰 નવી પેપર / તહેવાર રજા ઉમેરો'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int?>(
                  value: selectedItemId,
                  dropdownColor: AppColors.bgCardDark,
                  decoration: const InputDecoration(labelText: 'પેપર પસંદ કરો'),
                  items: [
                    const DropdownMenuItem<int?>(value: 0, child: Text('🌐 બધા જ પેપરો (All Papers Holiday)')),
                    ...db.items.map((i) => DropdownMenuItem<int?>(value: i.id, child: Text('${i.name} (${i.code})'))),
                  ],
                  onChanged: (v) => setDlgState(() => selectedItemId = v ?? 0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final p = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (p != null) {
                            setDlgState(() {
                              startDate = p;
                              if (endDate.isBefore(startDate)) endDate = startDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'શરૂ તારીખ'),
                          child: Text(DateFormat('dd/MM/yyyy').format(startDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final p = await showDatePicker(context: ctx, initialDate: endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (p != null) setDlgState(() => endDate = p);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'અંતિમ તારીખ'),
                          child: Text(DateFormat('dd/MM/yyyy').format(endDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'તહેવાર / રજાનું નામ (દા.ત. દિવાળી બેસતું વર્ષ, ધૂળેટી)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton(
              onPressed: () {
                final id = db.paperHolidays.isEmpty ? 1 : db.paperHolidays.map((h) => h.id).reduce((a, b) => a > b ? a : b) + 1;
                final sDate = DateFormat('yyyy-MM-dd').format(startDate);
                final eDate = DateFormat('yyyy-MM-dd').format(endDate);
                final reason = reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : 'પ્રેસ રજા';

                if (selectedItemId == 0) {
                  // Add for all items
                  for (final it in db.items) {
                    final hId = db.paperHolidays.isEmpty ? 1 : db.paperHolidays.map((h) => h.id).reduce((a, b) => a > b ? a : b) + 1;
                    db.paperHolidays.add(PaperHoliday(
                      id: hId,
                      itemId: it.id,
                      startDate: sDate,
                      endDate: eDate,
                      reason: reason,
                    ));
                  }
                } else {
                  db.paperHolidays.add(PaperHoliday(
                    id: id,
                    itemId: selectedItemId!,
                    startDate: sDate,
                    endDate: eDate,
                    reason: reason,
                  ));
                }

                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('સાચવો (Save)'),
            ),
          ],
        ),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: _openPaperHolidayDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવી પેપર રજા ઉમેરો'),
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
