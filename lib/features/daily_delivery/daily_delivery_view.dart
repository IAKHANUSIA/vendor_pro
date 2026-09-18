import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/customer.dart';
import '../../core/models/item.dart';
import '../../core/models/salesman.dart';
import '../../core/models/collection_man.dart';
import '../../core/models/route.dart';
import '../../core/models/vacation.dart';
import '../../core/printing/print_service.dart';
import '../../core/services/cloud_sync_service.dart';
import '../../core/providers/app_providers.dart';
import '../routes/route_order_dialog.dart';

class DailyDeliveryView extends ConsumerStatefulWidget {
  const DailyDeliveryView({super.key});

  @override
  ConsumerState<DailyDeliveryView> createState() => _DailyDeliveryViewState();
}

class _DailyDeliveryViewState extends ConsumerState<DailyDeliveryView> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedRouteId;
  int? _selectedSalesmanFilter;
  int? _selectedCollectionManFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _dayNamesGu = [
    'રવિવાર', 'સોમવાર', 'મંગળવાર', 'બુધવાર', 'ગુરુવાર', 'શુક્રવાર', 'શનિવાર'
  ];

  @override
  void initState() {
    super.initState();
    final db = DatabaseService.instance;
    if (db.routes.isNotEmpty) {
      _selectedRouteId = db.routes.first.id;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _markAllDelivered(List<Customer> list, String dateStr) {
    final db = DatabaseService.instance;
    for (final c in list) {
      db.setDeliveryStatus(dateStr, c.id, 'delivered');
    }
    notifyDbChanged(ref);
    if (db.storageMode == 'cloud') {
      CloudSyncService.instance.syncToCloud(db);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('આ લાઇનના બધા ગ્રાહકોને "પહોંચાડ્યા" માર્ક કરવામાં આવ્યા! ✅')),
    );
  }

  void _printSheet(BuildContext context, DeliveryRoute? route, Salesman? salesman, List<Customer> customers, Map<String, int> paperSummary) {
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('આ લાઇન પર કોઈ ગ્રાહક નથી.')),
      );
      return;
    }
    final db = DatabaseService.instance;
    PrintService.printMorningDeliverySheetPdf(
      context: context,
      route: route ?? (db.routes.isNotEmpty ? db.routes.first : DeliveryRoute(id: 1, name: 'લાઇન', code: 'L1', salesmanId: 1, collectionManId: 1)),
      date: _selectedDate,
      customers: customers,
      firm: db.firm,
      salesman: salesman,
      paperSummary: paperSummary,
    );
  }

  void _openRouteOrderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => RouteOrderDialog(
        initialRouteId: _selectedRouteId,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openQuickVacationDialog(Customer customer) {
    final db = DatabaseService.instance;
    DateTime startDate = _selectedDate;
    DateTime endDate = _selectedDate.add(const Duration(days: 2));
    final reasonCtrl = TextEditingController(text: 'દૈનિક વિતરણમાંથી રજા');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgCardDark,
          title: Row(
            children: [
              const Icon(Icons.beach_access, color: AppColors.accentGold),
              const SizedBox(width: 8),
              Text('🌴 ${customer.name} - રજા નોંધો', style: const TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('કોડ: ${customer.code} • લાઇન: ${db.routes.firstWhere((r) => r.id == customer.routeId, orElse: () => db.routes.first).name}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                const SizedBox(height: 14),
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
                          child: Text(DateFormat('dd/MM/yyyy').format(startDate), style: const TextStyle(color: Colors.white, fontSize: 13)),
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
                          decoration: const InputDecoration(labelText: 'અંતિમ તારીખ', isDense: true),
                          child: Text(DateFormat('dd/MM/yyyy').format(endDate), style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'કારણ / નોંધ', isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton(
              onPressed: () {
                final id = db.vacations.isEmpty ? 1 : db.vacations.map((v) => v.id).reduce((a, b) => a > b ? a : b) + 1;
                db.vacations.add(Vacation(
                  id: id,
                  customerId: customer.id,
                  startDate: DateFormat('yyyy-MM-dd').format(startDate),
                  endDate: DateFormat('yyyy-MM-dd').format(endDate),
                  reason: reasonCtrl.text.trim(),
                ));
                notifyDbChanged(ref);
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.warning,
                    content: Text('🌴 ${customer.name} ની રજા ${DateFormat('dd/MM/yyyy').format(startDate)} થી ${DateFormat('dd/MM/yyyy').format(endDate)} સુધી નોંધાઈ ગઈ!'),
                  ),
                );
              },
              child: const Text('સાચવો'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayOfWeek = _selectedDate.weekday % 7;
    final dayName = _dayNamesGu[dayOfWeek];

    final currentRoute = _selectedRouteId != null
        ? db.routes.cast<DeliveryRoute?>().firstWhere((r) => r?.id == _selectedRouteId, orElse: () => null)
        : null;
    final currentSalesman = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == currentRoute?.salesmanId, orElse: () => null);

    // Filter customers
    final lineCustomers = db.customers.where((c) {
      if (c.status != 'active') return false;
      if (_selectedRouteId != null && c.routeId != _selectedRouteId) return false;

      final r = db.routes.cast<DeliveryRoute?>().firstWhere((rt) => rt?.id == c.routeId, orElse: () => null);
      if (_selectedSalesmanFilter != null && r?.salesmanId != _selectedSalesmanFilter) return false;
      if (_selectedCollectionManFilter != null && r?.collectionManId != _selectedCollectionManFilter) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = c.name.toLowerCase().contains(q);
        final matchMobile = c.mobile.contains(q);
        final matchCode = c.code.toLowerCase().contains(q);
        if (!matchName && !matchMobile && !matchCode) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => (int.tryParse(a.sequenceNo) ?? 0).compareTo(int.tryParse(b.sequenceNo) ?? 0));

    // Calculate today's paper summary count
    final Map<String, int> paperSummary = {};
    for (final c in lineCustomers) {
      final onVacation = db.vacations.any((v) => v.customerId == c.id && v.isActiveOn(dateStr));
      if (onVacation) continue;

      for (final id in c.subscriptionItemIds) {
        if (c.isSubscribedOnDay(id, dayOfWeek, dateStr)) {
          final item = db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null);
          if (item != null) {
            final code = item.code.isNotEmpty ? item.code : item.name;
            paperSummary[code] = (paperSummary[code] ?? 0) + 1;
          }
        }
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isNarrow ? 10 : 16),
        child: Column(
          children: [
            // Top Toolbar: Date, Route, Salesman, Collection Filter & Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: isNarrow
                    ? Column(
                        children: [
                          Row(
                            children: [
                              // Search Bar
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondaryDark, size: 18),
                                    hintText: 'ગ્રાહક શોધો...',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Date Picker
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) setState(() => _selectedDate = picked);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurfaceDark,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderDark),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: AppColors.accentCyan),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('dd/MM').format(_selectedDate),
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Route Selector
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  value: _selectedRouteId,
                                  dropdownColor: AppColors.bgCardDark,
                                  isExpanded: true,
                                  decoration: const InputDecoration(isDense: true, labelText: 'રૂટ/લાઇન'),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text('બધી લાઇન')),
                                    ...db.routes.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text('${r.code} - ${r.name}'))),
                                  ],
                                  onChanged: (v) => setState(() => _selectedRouteId = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Salesman / Delivery Filter
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  value: _selectedSalesmanFilter,
                                  dropdownColor: AppColors.bgCardDark,
                                  isExpanded: true,
                                  decoration: const InputDecoration(isDense: true, labelText: '🚴 વિતરક'),
                                  items: [
                                    const DropdownMenuItem<int?>(value: null, child: Text('બધા વિતરક')),
                                    ...db.salesmen.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
                                  ],
                                  onChanged: (v) => setState(() => _selectedSalesmanFilter = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primaryTeal),
                                    foregroundColor: AppColors.primaryTeal,
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  ),
                                  onPressed: lineCustomers.isEmpty
                                      ? null
                                      : () => _printSheet(context, currentRoute, currentSalesman, lineCustomers, paperSummary),
                                  icon: const Icon(Icons.print, size: 14),
                                  label: const Text('પ્રિન્ટ', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.accentCyan),
                                    foregroundColor: AppColors.accentCyan,
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  ),
                                  onPressed: _openRouteOrderDialog,
                                  icon: const Icon(Icons.swap_vert, size: 14),
                                  label: const Text('ક્રમ', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  ),
                                  onPressed: lineCustomers.isEmpty ? null : () => _markAllDelivered(lineCustomers, dateStr),
                                  icon: const Icon(Icons.done_all, size: 14),
                                  label: const Text('બધા', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          // Search Bar
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search, color: AppColors.textSecondaryDark, size: 18),
                                hintText: 'ગ્રાહક શોધો...',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Route Selector
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int?>(
                              value: _selectedRouteId,
                              dropdownColor: AppColors.bgCardDark,
                              decoration: const InputDecoration(isDense: true, labelText: 'ડિલિવરી લાઇન / રૂટ'),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('બધી લાઇન (All Routes)')),
                                ...db.routes.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text('${r.code} - ${r.name}'))),
                              ],
                              onChanged: (v) => setState(() => _selectedRouteId = v),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Salesman / Delivery Filter
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int?>(
                              value: _selectedSalesmanFilter,
                              dropdownColor: AppColors.bgCardDark,
                              decoration: const InputDecoration(isDense: true, labelText: '🚴 વિતરક'),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('બધા વિતરક')),
                                ...db.salesmen.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
                              ],
                              onChanged: (v) => setState(() => _selectedSalesmanFilter = v),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Collection Man Filter
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int?>(
                              value: _selectedCollectionManFilter,
                              dropdownColor: AppColors.bgCardDark,
                              decoration: const InputDecoration(isDense: true, labelText: '💼 ઉઘરાણીદાર'),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('બધા ઉઘરાણીદાર')),
                                ...db.collectionMen.map((cm) => DropdownMenuItem<int?>(value: cm.id, child: Text(cm.name))),
                              ],
                              onChanged: (v) => setState(() => _selectedCollectionManFilter = v),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Date Picker
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setState(() => _selectedDate = picked);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurfaceDark,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderDark),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: AppColors.accentCyan),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${DateFormat('dd/MM/yyyy').format(_selectedDate)} ($dayName)',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Print Morning Sheet Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryTeal),
                              foregroundColor: AppColors.primaryTeal,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            onPressed: lineCustomers.isEmpty
                                ? null
                                : () => _printSheet(context, currentRoute, currentSalesman, lineCustomers, paperSummary),
                            icon: const Icon(Icons.print, size: 16),
                            label: const Text('🖨️ શીટ પ્રિન્ટ'),
                          ),
                          const SizedBox(width: 6),

                          // Reorder Street Sequence Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.accentCyan),
                              foregroundColor: AppColors.accentCyan,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            onPressed: _openRouteOrderDialog,
                            icon: const Icon(Icons.swap_vert, size: 16),
                            label: const Text('🔀 ક્રમ'),
                          ),
                          const SizedBox(width: 6),

                          // Mark All Delivered Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onPressed: lineCustomers.isEmpty ? null : () => _markAllDelivered(lineCustomers, dateStr),
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text('બધા પહોંચાડ્યા'),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // Paper Metrics Pills Banner & Assigned Salesman
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (paperSummary.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A3447)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('📰 પેપર કાઉન્ટર: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accentCyan)),
                          const SizedBox(width: 8),
                          ...paperSummary.entries.map((e) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryTeal.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                                ),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accentCyan),
                                ),
                              )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentAmber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.accentAmber.withOpacity(0.4)),
                            ),
                            child: Text(
                              'કુલ: ${paperSummary.values.fold<int>(0, (a, b) => a + b)} નકલો',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accentAmber),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (currentSalesman != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      '🚴‍♂️ વિતરક: ${currentSalesman.name} (${currentSalesman.mobile})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontSize: 11),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Customers Table Body (Adaptive)
            Expanded(
              child: lineCustomers.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.bgCardDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: const Text(
                        'આ ફિલ્ટરમાં કોઈ સક્રિય ગ્રાહક મળ્યા નથી',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 15),
                      ),
                    )
                  : isNarrow
                      // Mobile Delivery Card List (Touch-friendly, Zero Overflow)
                      ? ListView.builder(
                        itemCount: lineCustomers.length,
                        itemBuilder: (ctx, index) {
                          final c = lineCustomers[index];
                          final onVacation = db.vacations.any((v) => v.customerId == c.id && v.isActiveOn(dateStr));
                          final isDelivered = db.getDeliveryStatus(dateStr, c.id) == 'delivered';

                          final todayPapers = c.subscriptionItemIds.where((id) {
                            return c.isSubscribedOnDay(id, dayOfWeek, dateStr);
                          }).map((id) {
                            return db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null)?.name;
                          }).where((n) => n != null).toList();

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: onVacation ? AppColors.danger.withOpacity(0.08) : AppColors.bgCardDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: onVacation ? AppColors.danger.withOpacity(0.3) : AppColors.borderDark,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#${c.sequenceNo.isNotEmpty ? c.sequenceNo : (index + 1).toString()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                          ),
                                          if (c.code.isNotEmpty || c.mobile.isNotEmpty)
                                            Text(
                                              '${c.code.isNotEmpty ? c.code : "C-" + c.id.toString()}${c.mobile.isNotEmpty ? " • 📞 " + c.mobile : ""}',
                                              style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (c.mobile.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.call_outlined, size: 18, color: Color(0xFF64B5F6)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => launchUrl(Uri.parse('tel:${c.mobile}'), mode: LaunchMode.externalApplication),
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.beach_access, size: 18, color: AppColors.accentGold),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _openQuickVacationDialog(c),
                                      tooltip: 'રજા નોંધો',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Subscribed Papers / Vacation Badge
                                if (onVacation)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('🌴 રજા પર છે', style: TextStyle(color: AppColors.dangerLight, fontSize: 11, fontWeight: FontWeight.bold)),
                                  )
                                else if (todayPapers.isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: todayPapers.map((p) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryTeal.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.35)),
                                        ),
                                        child: Text(
                                          p!.toUpperCase(),
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                if (c.address.isNotEmpty || c.societyShort.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '📍 ${c.address.isNotEmpty ? c.address : c.societyShort}',
                                    style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                // Delivery Status Action Toggle Button
                                SizedBox(
                                  width: double.infinity,
                                  child: InkWell(
                                    onTap: onVacation
                                        ? null
                                        : () {
                                            final newStatus = isDelivered ? 'undelivered' : 'delivered';
                                            db.setDeliveryStatus(dateStr, c.id, newStatus);
                                            notifyDbChanged(ref);
                                            if (db.storageMode == 'cloud') {
                                              CloudSyncService.instance.syncToCloud(db);
                                            }
                                            setState(() {});
                                          },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDelivered
                                            ? const Color(0xFF1B4D3E).withOpacity(0.7)
                                            : AppColors.surfaceDark,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDelivered ? AppColors.successGreen : AppColors.borderDark,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isDelivered ? Icons.check_circle : Icons.radio_button_unchecked,
                                            size: 16,
                                            color: isDelivered ? AppColors.successLight : AppColors.textMutedDark,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isDelivered ? 'આપી દીધું (Delivered)' : 'બાકી છે (Tap to Mark Delivered)',
                                            style: TextStyle(
                                              color: isDelivered ? AppColors.successLight : AppColors.textSecondaryDark,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      // Desktop & Tablet Table Layout (Horizontal Scroll Safe)
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.bgCardDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 960,
                              child: Column(
                                children: [
                                  // Table Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF131924),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                    ),
                                    child: const Row(
                                      children: [
                                        SizedBox(
                                          width: 90,
                                          child: Text('વિતરણ ક્રમ નંબર', style: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('ગ્રાહક', style: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text('પેપર્સ', style: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text('સરનામું', style: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(
                                          width: 130,
                                          child: Text('વિતરણ સ્થિતિ', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        SizedBox(
                                          width: 90,
                                          child: Text('ક્રિયાઓ', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: AppColors.borderDark),
                                  // Table Body
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: lineCustomers.length,
                                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFF1E2838)),
                                      itemBuilder: (ctx, index) {
                                        final c = lineCustomers[index];
                                        final onVacation = db.vacations.any((v) => v.customerId == c.id && v.isActiveOn(dateStr));
                                        final isDelivered = db.getDeliveryStatus(dateStr, c.id) == 'delivered';

                                        final todayPapers = c.subscriptionItemIds.where((id) {
                                          return c.isSubscribedOnDay(id, dayOfWeek, dateStr);
                                        }).map((id) {
                                          return db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null)?.name;
                                        }).where((n) => n != null).toList();

                                        return Container(
                                          color: onVacation ? AppColors.danger.withOpacity(0.06) : null,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              // 1. Sequence Number
                                              SizedBox(
                                                width: 90,
                                                child: Text(
                                                  c.sequenceNo.isNotEmpty ? c.sequenceNo : '${index + 1}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 14),
                                                ),
                                              ),

                                              // 2. Customer Name, Code, Phone
                                              Expanded(
                                                flex: 3,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      c.name,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${c.code.isNotEmpty ? c.code : "C-" + c.id.toString()}${c.mobile.isNotEmpty ? " • 📞 " + c.mobile : ""}',
                                                      style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // 3. Papers Badges
                                              Expanded(
                                                flex: 3,
                                                child: onVacation
                                                    ? Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.danger.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Text('🌴 રજા પર છે', style: TextStyle(color: AppColors.dangerLight, fontSize: 11, fontWeight: FontWeight.bold)),
                                                      )
                                                    : Wrap(
                                                        spacing: 4,
                                                        runSpacing: 4,
                                                        children: todayPapers.isEmpty
                                                            ? [const Text('-', style: TextStyle(color: AppColors.textMutedDark))]
                                                            : todayPapers.map((p) {
                                                                return Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                  decoration: BoxDecoration(
                                                                    color: AppColors.primaryTeal.withOpacity(0.18),
                                                                    borderRadius: BorderRadius.circular(4),
                                                                    border: Border.all(color: AppColors.primaryTeal.withOpacity(0.35)),
                                                                  ),
                                                                  child: Text(
                                                                    p!.toUpperCase(),
                                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                                                                  ),
                                                                );
                                                              }).toList(),
                                                      ),
                                              ),

                                              // 4. Address
                                              Expanded(
                                                flex: 4,
                                                child: Text(
                                                  c.address.isNotEmpty ? c.address : (c.societyShort.isNotEmpty ? c.societyShort : '-'),
                                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),

                                              // 5. Delivery Status (Instant toggle)
                                              SizedBox(
                                                width: 130,
                                                child: Center(
                                                  child: InkWell(
                                                    onTap: onVacation
                                                        ? null
                                                        : () {
                                                            final newStatus = isDelivered ? 'undelivered' : 'delivered';
                                                            db.setDeliveryStatus(dateStr, c.id, newStatus);
                                                            notifyDbChanged(ref);
                                                            if (db.storageMode == 'cloud') {
                                                              CloudSyncService.instance.syncToCloud(db);
                                                            }
                                                            setState(() {});
                                                          },
                                                    borderRadius: BorderRadius.circular(20),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        color: isDelivered
                                                            ? const Color(0xFF1B4D3E).withOpacity(0.7)
                                                            : AppColors.surfaceDark,
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: Border.all(
                                                          color: isDelivered ? AppColors.successGreen : AppColors.borderDark,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            isDelivered ? Icons.check : Icons.radio_button_unchecked,
                                                            size: 14,
                                                            color: isDelivered ? AppColors.successLight : AppColors.textMutedDark,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            isDelivered ? 'આપી દીધું' : 'બાકી',
                                                            style: TextStyle(
                                                              color: isDelivered ? AppColors.successLight : AppColors.textSecondaryDark,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // 6. Actions (🌴 રજા Quick Button)
                                              SizedBox(
                                                width: 90,
                                                child: Center(
                                                  child: OutlinedButton.icon(
                                                    style: OutlinedButton.styleFrom(
                                                      side: const BorderSide(color: AppColors.accentGold, width: 0.8),
                                                      foregroundColor: AppColors.accentGold,
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                    onPressed: () => _openQuickVacationDialog(c),
                                                    icon: const Icon(Icons.beach_access, size: 13),
                                                    label: const Text('રજા', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
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
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
