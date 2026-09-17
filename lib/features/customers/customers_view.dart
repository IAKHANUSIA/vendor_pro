import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/collection_man.dart';
import '../../core/models/customer.dart';
import '../../core/models/item.dart';
import '../../core/models/route.dart';
import '../../core/models/salesman.dart';
import '../../core/models/vacation.dart';
import '../routes/route_order_dialog.dart';

class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedRouteFilter;
  int? _selectedSalesmanFilter;
  int? _selectedCollectionManFilter;
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> get _filteredCustomers {
    final db = DatabaseService.instance;
    return db.customers.where((c) {
      if (_statusFilter == 'active' && !c.isActive) return false;
      if (_statusFilter == 'inactive' && c.isActive) return false;
      if (_selectedRouteFilter != null && c.routeId != _selectedRouteFilter) return false;

      final route = db.routes.cast<DeliveryRoute?>().firstWhere((r) => r?.id == c.routeId, orElse: () => null);
      if (_selectedSalesmanFilter != null && route?.salesmanId != _selectedSalesmanFilter) return false;
      if (_selectedCollectionManFilter != null && route?.collectionManId != _selectedCollectionManFilter) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = c.name.toLowerCase().contains(q);
        final matchMobile = c.mobile.contains(q);
        final matchCode = c.code.toLowerCase().contains(q);
        final matchCustNo = c.custNo.contains(q);
        if (!matchName && !matchMobile && !matchCode && !matchCustNo) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => (int.tryParse(a.sequenceNo) ?? 0).compareTo(int.tryParse(b.sequenceNo) ?? 0));
  }

  void _openRouteOrderDialog([int? routeId]) {
    showDialog(
      context: context,
      builder: (ctx) => RouteOrderDialog(
        initialRouteId: routeId ?? _selectedRouteFilter,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openCustomerDialog([Customer? customer]) {
    showDialog(
      context: context,
      builder: (ctx) => _CustomerFormDialog(
        customer: customer,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openQuickVacationDialog(Customer customer) {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 2));
    final reasonCtrl = TextEditingController(text: 'પ્રવાસ / બહારગામ');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Text('🌴 ', style: TextStyle(fontSize: 20)),
              Text('રજા નોંધો: ${customer.name}', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                decoration: const InputDecoration(labelText: 'કારણ / નોંધ'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton(
              onPressed: () {
                final db = DatabaseService.instance;
                final id = db.vacations.isEmpty ? 1 : db.vacations.map((v) => v.id).reduce((a, b) => a > b ? a : b) + 1;
                db.vacations.add(Vacation(
                  id: id,
                  customerId: customer.id,
                  startDate: DateFormat('yyyy-MM-dd').format(startDate),
                  endDate: DateFormat('yyyy-MM-dd').format(endDate),
                  reason: reasonCtrl.text.trim(),
                ));
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${customer.name} ની રજા સાચવી લેવાઈ!'), backgroundColor: AppColors.successGreen),
                );
              },
              child: const Text('સાચવો'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        title: const Text('ગ્રાહક હટાવો?', style: TextStyle(color: Colors.white)),
        content: Text('શું તમે ખરેખર "${customer.name}" ને હટાવવા માંગો છો?', style: const TextStyle(color: Color(0xFFB0BEC5))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              DatabaseService.instance.customers.removeWhere((c) => c.id == customer.id);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ગ્રાહક "${customer.name}" હટાવાયો.')),
              );
            },
            child: const Text('હટાવો', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String key, String label, int count, Color color) {
    final isSelected = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF141A28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF2A364F),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (key != 'all') ...[
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
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
    final customers = _filteredCustomers;
    final totalCustomers = db.customers.length;
    final activeCount = db.customers.where((c) => c.isActive).length;
    final inactiveCount = db.customers.where((c) => !c.isActive).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header matching Image 2
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, color: AppColors.accentCyan, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'ગ્રાહક માસ્ટર',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.5)),
                  ),
                  child: Text(
                    '$totalCustomers ગ્રાહકો',
                    style: const TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const Spacer(),
                // Reorder Button matching Image 2
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF2A364F)),
                    backgroundColor: const Color(0xFF141A28),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openRouteOrderDialog(_selectedRouteFilter),
                  icon: const Icon(Icons.shuffle, size: 16, color: Color(0xFF42A5F5)),
                  label: const Text('લાઇન ક્રમ ગોઠવો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                // Add Customer Button matching Image 2
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openCustomerDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('નવા ગ્રાહકની નોંધણી', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Bar matching Image 2
            Row(
              children: [
                // Status Filter Pills
                _buildStatusChip('all', 'બધા', totalCustomers, Colors.white),
                const SizedBox(width: 8),
                _buildStatusChip('active', 'સક્રિય', activeCount, const Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                _buildStatusChip('inactive', 'બંધ', inactiveCount, const Color(0xFFEF5350)),
                const SizedBox(width: 14),

                // Search Bar
                SizedBox(
                  width: 240,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'નામ, લાઇન અથવા મોબાઈલ...',
                      prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF78909C)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Salesman Filter Dropdown
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedSalesmanFilter,
                    dropdownColor: const Color(0xFF1A2336),
                    decoration: InputDecoration(
                      labelText: '🚴 બધા વિતરક',
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('બધા વિતરક', style: TextStyle(fontSize: 12, color: Colors.white))),
                      ...db.salesmen.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 12, color: Colors.white)))),
                    ],
                    onChanged: (v) => setState(() => _selectedSalesmanFilter = v),
                  ),
                ),
                const SizedBox(width: 12),

                // Collection Man Filter Dropdown
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedCollectionManFilter,
                    dropdownColor: const Color(0xFF1A2336),
                    decoration: InputDecoration(
                      labelText: '💼 બધા ઉઘરાણી મેન',
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('બધા ઉઘરાણી મેન', style: TextStyle(fontSize: 12, color: Colors.white))),
                      ...db.collectionMen.map((cm) => DropdownMenuItem<int?>(value: cm.id, child: Text(cm.name, style: const TextStyle(fontSize: 12, color: Colors.white)))),
                    ],
                    onChanged: (v) => setState(() => _selectedCollectionManFilter = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Container matching Image 2
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF222F46)),
                ),
                clipBehavior: Clip.antiAlias,
                child: customers.isEmpty
                    ? const Center(
                        child: Text(
                          'કોઈ ગ્રાહક મળ્યા નથી',
                          style: TextStyle(color: Color(0xFF78909C), fontSize: 16),
                        ),
                      )
                    : Column(
                        children: [
                          // Table Header matching Image 2
                          Container(
                            color: const Color(0xFF172033),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: const [
                                SizedBox(width: 60, child: Text('ગ્રાહક નં.', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 55, child: Text('ડિલિવરી\nક્રમ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 11))),
                                SizedBox(width: 55, child: Text('ઉઘરાણી\nક્રમ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 11))),
                                Expanded(flex: 3, child: Text('ગ્રાહકનું નામ', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 3, child: Text('ડિલિવરી લાઇન', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(flex: 3, child: Text('ચાલુ પેપર્સ (સબસ્ક્રિપ્શન)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 75, child: Text('બિલિંગ\nપ્રકાર', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 11))),
                                SizedBox(width: 95, child: Text('મોબાઈલ નંબર', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 70, child: Text('બાકી રકમ (₹)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 11))),
                                SizedBox(width: 75, child: Text('સ્થિતિ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                                SizedBox(width: 90, child: Text('ક્રિયાઓ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFF222F46)),

                          // Table Body matching Image 2
                          Expanded(
                            child: ListView.separated(
                              itemCount: customers.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1E283C)),
                              itemBuilder: (ctx, index) {
                                final c = customers[index];
                                final route = db.routes.cast<DeliveryRoute?>().firstWhere((r) => r?.id == c.routeId, orElse: () => null);
                                final salesman = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == route?.salesmanId, orElse: () => null);
                                final collectionMan = db.collectionMen.cast<CollectionMan?>().firstWhere((cm) => cm?.id == route?.collectionManId, orElse: () => null);

                                final subPapers = c.subscriptionItemIds
                                    .map((id) => db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null)?.name)
                                    .where((n) => n != null)
                                    .toList();

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  color: index.isEven ? Colors.transparent : const Color(0xFF161E2E).withOpacity(0.5),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 1. Cust No
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          '#${c.custNo.isNotEmpty ? c.custNo : c.code}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF42A5F5), fontSize: 13),
                                        ),
                                      ),

                                      // 2. Delivery Sequence
                                      SizedBox(
                                        width: 55,
                                        child: Text(
                                          c.sequenceNo,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),

                                      // 3. Collection Sequence
                                      SizedBox(
                                        width: 55,
                                        child: Text(
                                          '${c.collectionSequence}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),

                                      // 4. Customer Name & Address
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
                                              'C-${c.code} • ${c.address.isNotEmpty ? c.address : (c.societyShort.isNotEmpty ? c.societyShort : "")}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 5. Route Line & Staff Info matching Image 2
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF332A15),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.4)),
                                              ),
                                              child: Text(
                                                route != null ? '${route.name} (${route.code})' : 'કોઈ લાઇન નથી',
                                                style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 11, fontWeight: FontWeight.w600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '🚴 ${salesman?.name ?? "-"}   💼 ${collectionMan?.name ?? "-"}',
                                              style: const TextStyle(fontSize: 10, color: Color(0xFFB0BEC5)),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 6. Subscribed Papers
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          subPapers.isNotEmpty ? subPapers.join(', ') : '-',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFFCFD8DC)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      // 7. Billing Type
                                      SizedBox(
                                        width: 75,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF102A45),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              c.billingType == 'fixed' ? 'ફિક્સ' : 'દૈનિક',
                                              style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 8. Mobile Number
                                      SizedBox(
                                        width: 95,
                                        child: Text(
                                          c.mobile.isNotEmpty ? '📞 ${c.mobile}' : '-',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
                                        ),
                                      ),

                                      // 9. Balance
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          '₹${c.currentBalance.toStringAsFixed(0)}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: c.currentBalance > 0 ? const Color(0xFFFF5252) : const Color(0xFF81C784),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),

                                      // 10. Status Pill matching Image 2
                                      SizedBox(
                                        width: 75,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: c.isActive ? const Color(0xFF1B3830) : const Color(0xFF381E24),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: c.isActive ? const Color(0xFF4CAF50).withOpacity(0.5) : const Color(0xFFEF5350).withOpacity(0.5),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.circle, size: 8, color: c.isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  c.isActive ? 'સક્રિય' : 'બંધ',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: c.isActive ? const Color(0xFF81C784) : const Color(0xFFE57373),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 11. Actions
                                      SizedBox(
                                        width: 90,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // WhatsApp Action
                                            if (c.mobile.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 16),
                                                splashRadius: 14,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  final mob = c.whatsapp.isNotEmpty ? c.whatsapp : c.mobile;
                                                  final url = 'https://wa.me/91$mob';
                                                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                                },
                                                tooltip: 'WhatsApp',
                                              ),
                                            const SizedBox(width: 6),
                                            // Edit Action
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Color(0xFFFFA726), size: 16),
                                              splashRadius: 14,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _openCustomerDialog(c),
                                              tooltip: 'સુધારો (Edit)',
                                            ),
                                            const SizedBox(width: 6),
                                            // Vacation / Leave Action
                                            IconButton(
                                              icon: const Icon(Icons.beach_access, color: Color(0xFF4FC3F7), size: 16),
                                              splashRadius: 14,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _openQuickVacationDialog(c),
                                              tooltip: 'રજા નોંધો (Leave)',
                                            ),
                                            const SizedBox(width: 6),
                                            // Delete Action
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 16),
                                              splashRadius: 14,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _deleteCustomer(c),
                                              tooltip: 'હટાવો (Delete)',
                                            ),
                                          ],
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
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Add / Edit Customer Form Dialog matching Image 1
// -------------------------------------------------------------
class _CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  final VoidCallback onSaved;

  const _CustomerFormDialog({this.customer, required this.onSaved});

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _seqCtrl;
  late TextEditingController _colSeqCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _societyCtrl;
  late TextEditingController _delChargeAmtCtrl;
  late TextEditingController _balanceCtrl;

  late int _routeId;
  int? _insertAfterSeq;
  String _insertAfterHelpText = '';
  String _billingType = 'daily';
  bool _delChargeEnabled = false;
  bool _printEnabled = true;
  bool _isActive = true;

  final Map<int, Set<String>> _paperSubscriptions = {};

  final ScrollController _papersScrollCtrl = ScrollController();

  final List<Map<String, String>> _allDays = const [
    {'code': 'mon', 'label': 'સોમ'},
    {'code': 'tue', 'label': 'મંગળ'},
    {'code': 'wed', 'label': 'બુધ'},
    {'code': 'thu', 'label': 'ગુરુ'},
    {'code': 'fri', 'label': 'શુક્ર'},
    {'code': 'sat', 'label': 'શનિ'},
    {'code': 'sun', 'label': 'રવિ'},
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    final db = DatabaseService.instance;

    _routeId = c?.routeId ?? (db.routes.isNotEmpty ? db.routes.first.id : 1);
    final routeCusts = db.customers.where((item) => item.routeId == _routeId && item.id != c?.id).toList();
    final maxSeq = routeCusts.fold<int>(0, (max, item) => (int.tryParse(item.sequenceNo) ?? 0) > max ? (int.tryParse(item.sequenceNo) ?? 0) : max);
    final defaultSeq = c?.sequenceNo ?? '${maxSeq + 1}';

    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _codeCtrl = TextEditingController(text: c?.code.isNotEmpty == true ? c!.code : (c?.custNo ?? '${db.customers.length + 101}'));
    _seqCtrl = TextEditingController(text: defaultSeq);
    _colSeqCtrl = TextEditingController(text: c != null ? '${c.collectionSequence}' : '$defaultSeq');
    _mobileCtrl = TextEditingController(text: c?.mobile ?? '');
    _whatsappCtrl = TextEditingController(text: c?.whatsapp.isNotEmpty == true ? c!.whatsapp : (c?.mobile ?? ''));
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _societyCtrl = TextEditingController(text: c?.societyShort ?? '');
    _delChargeAmtCtrl = TextEditingController(text: (c?.delChargeAmt ?? 10.0).toStringAsFixed(0));
    _balanceCtrl = TextEditingController(text: (c?.currentBalance ?? 0.0).toStringAsFixed(0));

    _billingType = c?.billingType ?? 'daily';
    _delChargeEnabled = c?.delChargeEnabled ?? false;
    _isActive = c?.isActive ?? true;

    if (c != null && c.subscriptions != null) {
      if (c.subscriptions is List) {
        for (final item in (c.subscriptions as List)) {
          final itemId = int.tryParse(item.toString());
          if (itemId != null) {
            _paperSubscriptions[itemId] = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
          }
        }
      } else if (c.subscriptions is Map) {
        final subMap = c.subscriptions as Map;
        subMap.forEach((k, v) {
          final itemId = int.tryParse(k.toString());
          if (itemId != null) {
            if (v is List) {
              _paperSubscriptions[itemId] = v.map((d) => d.toString().toLowerCase()).toSet();
            } else if (v is Map && v['days'] is List) {
              _paperSubscriptions[itemId] = (v['days'] as List).map((d) => d.toString().toLowerCase()).toSet();
            } else {
              _paperSubscriptions[itemId] = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
            }
          }
        });
      }
    } else if (c == null && db.items.isNotEmpty) {
      _paperSubscriptions[db.items.first.id] = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
    }
  }

  void _onRouteChange(int newRouteId) {
    setState(() {
      _routeId = newRouteId;
      _insertAfterSeq = null;
      if (widget.customer == null) {
        final db = DatabaseService.instance;
        final routeCusts = db.customers.where((item) => item.routeId == _routeId).toList();
        final maxSeq = routeCusts.fold<int>(0, (max, item) => (int.tryParse(item.sequenceNo) ?? 0) > max ? (int.tryParse(item.sequenceNo) ?? 0) : max);
        final nextSeq = maxSeq + 1;
        _seqCtrl.text = '$nextSeq';
        _colSeqCtrl.text = '$nextSeq';
        _insertAfterHelpText = 'લાઇનનો છેલ્લો ક્રમ $nextSeq અપાશે';
      }
    });
  }

  @override
  void dispose() {
    _papersScrollCtrl.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _seqCtrl.dispose();
    _colSeqCtrl.dispose();
    _mobileCtrl.dispose();
    _whatsappCtrl.dispose();
    _addressCtrl.dispose();
    _societyCtrl.dispose();
    _delChargeAmtCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final db = DatabaseService.instance;
    final id = widget.customer?.id ?? (db.customers.isEmpty ? 1 : db.customers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

    final Map<String, List<String>> savedSubscriptions = {};
    _paperSubscriptions.forEach((itemId, days) {
      if (days.isNotEmpty) {
        savedSubscriptions[itemId.toString()] = days.toList();
      }
    });

    final newCust = Customer(
      id: id,
      code: _codeCtrl.text.trim(),
      custNo: _codeCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      sequenceNo: _seqCtrl.text.trim(),
      collectionSequence: _colSeqCtrl.text.trim().isNotEmpty ? _colSeqCtrl.text.trim() : _seqCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim().isNotEmpty ? _whatsappCtrl.text.trim() : _mobileCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      societyShort: _societyCtrl.text.trim(),
      routeId: _routeId,
      billingType: _billingType,
      delChargeEnabled: _delChargeEnabled,
      delChargeAmt: _delChargeEnabled ? (double.tryParse(_delChargeAmtCtrl.text) ?? 10.0) : 0.0,
      fixedMonthlyAmount: 0.0,
      currentBalance: double.tryParse(_balanceCtrl.text) ?? 0.0,
      status: _isActive ? 'active' : 'inactive',
      subscriptions: savedSubscriptions,
    );

    if (widget.customer == null) {
      final targetSeq = int.tryParse(_seqCtrl.text);
      db.insertCustomerAtSequence(newCust, targetSeq, _routeId, syncCollectionSeq: true);
    } else {
      final idx = db.customers.indexWhere((c) => c.id == widget.customer!.id);
      if (idx != -1) db.customers[idx] = newCust;
    }

    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final routeCustomers = db.customers
        .where((c) => c.routeId == _routeId && c.id != widget.customer?.id)
        .toList()
      ..sort((a, b) => (int.tryParse(a.sequenceNo) ?? 0).compareTo(int.tryParse(b.sequenceNo) ?? 0));

    return Dialog(
      backgroundColor: const Color(0xFF161E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 780,
        constraints: const BoxConstraints(maxHeight: 820),
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header matching Image 1
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF102A45),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.5)),
                        ),
                        child: Text(
                          _codeCtrl.text.isNotEmpty ? '#${_codeCtrl.text}' : 'નવો ગ્રાહક',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64B5F6)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.customer == null ? 'નવા ગ્રાહકની નોંધણી' : 'ગ્રાહકની વિગત બદલો',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Line Selector & Customer Name
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              value: _routeId,
                              dropdownColor: const Color(0xFF1A2336),
                              decoration: InputDecoration(
                                labelText: 'ડિલિવરી લાઇન (Route)',
                                filled: true,
                                fillColor: const Color(0xFF111722),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              ),
                              items: db.routes.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.name} (${r.code})', style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
                              onChanged: (v) {
                                if (v != null) _onRouteChange(v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: InputDecoration(
                                labelText: 'ગ્રાહકનું પૂરું નામ *',
                                hintText: 'દા.ત. પટેલ રમેશભાઈ',
                                filled: true,
                                fillColor: const Color(0xFF111722),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              ),
                              validator: (v) => v?.trim().isEmpty == true ? 'નામ લખો' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Insert After Box matching Image 1
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141F32),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.4), style: BorderStyle.solid),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.location_on, color: Color(0xFFEF5350), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'કયા જૂના ગ્રાહક પછી ગોઠવવો? (Insert After)',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF42A5F5), fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int?>(
                              value: _insertAfterSeq,
                              dropdownColor: const Color(0xFF1A2336),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF111722),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('-- લાઇનના અંતે ઉમેરો (Add to End) --', style: TextStyle(color: Colors.white, fontSize: 13)),
                                ),
                                ...routeCustomers.map((rc) => DropdownMenuItem<int?>(
                                      value: int.tryParse(rc.sequenceNo) ?? 0,
                                      child: Text(
                                        '[ક્રમ ${rc.sequenceNo}] #${rc.custNo.isNotEmpty ? rc.custNo : rc.code} ${rc.name}',
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _insertAfterSeq = v;
                                  if (v != null && v > 0) {
                                    final nextSeq = v + 1;
                                    _seqCtrl.text = '$nextSeq';
                                    _colSeqCtrl.text = '$nextSeq';
                                  } else {
                                    final maxSeq = routeCustomers.fold<int>(0, (max, item) => (int.tryParse(item.sequenceNo) ?? 0) > max ? (int.tryParse(item.sequenceNo) ?? 0) : max);
                                    final nextSeq = maxSeq + 1;
                                    _seqCtrl.text = '$nextSeq';
                                    _colSeqCtrl.text = '$nextSeq';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Sequence Number & Collection Seq matching Image 1
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ડિલિવરી ક્રમ (Seq)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _seqCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF111722),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ઉઘરાણી ક્રમ (Col. Seq)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _colSeqCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF111722),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 4. Del.Charge, Amount, Print, Status Row matching Image 1
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Del.Charge(Y/N)
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Del.Charge(Y/N)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<bool>(
                                  value: _delChargeEnabled,
                                  dropdownColor: const Color(0xFF1A2336),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF111722),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: false, child: Text('NO', style: TextStyle(color: Colors.white, fontSize: 13))),
                                    DropdownMenuItem(value: true, child: Text('YES', style: TextStyle(color: Colors.white, fontSize: 13))),
                                  ],
                                  onChanged: (v) => setState(() => _delChargeEnabled = v ?? false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Charge Amount
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ચાર્જ રકમ (₹)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _delChargeAmtCtrl,
                                  enabled: _delChargeEnabled,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF111722),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Print(Y/N)
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Print(Y/N)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<bool>(
                                  value: _printEnabled,
                                  dropdownColor: const Color(0xFF1A2336),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF111722),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: true, child: Text('Yes', style: TextStyle(color: Colors.white, fontSize: 13))),
                                    DropdownMenuItem(value: false, child: Text('No', style: TextStyle(color: Colors.white, fontSize: 13))),
                                  ],
                                  onChanged: (v) => setState(() => _printEnabled = v ?? true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Status Dropdown matching Image 1
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('સ્થિતિ (Status)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<bool>(
                                  value: _isActive,
                                  dropdownColor: const Color(0xFF1A2336),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFF111722),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: true,
                                      child: Row(
                                        children: [
                                          Icon(Icons.circle, color: Color(0xFF4CAF50), size: 10),
                                          SizedBox(width: 6),
                                          Text('સક્રિય (Active)', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: false,
                                      child: Row(
                                        children: [
                                          Icon(Icons.circle, color: Color(0xFFEF5350), size: 10),
                                          SizedBox(width: 6),
                                          Text('બંધ (Inactive)', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) => setState(() => _isActive = v ?? true),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 5. Mobile, WhatsApp, Old Balance matching Image 1
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('મોબાઈલ નંબર', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _mobileCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: '98250 00000',
                                    filled: true,
                                    fillColor: const Color(0xFF111722),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                  ),
                                  onChanged: (v) {
                                    if (_whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _mobileCtrl.text.substring(0, _mobileCtrl.text.length > 0 ? _mobileCtrl.text.length - 1 : 0)) {
                                      _whatsappCtrl.text = v;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('વૉટ્સએપ નંબર', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _whatsappCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: '98250 00000',
                                    filled: true,
                                    fillColor: const Color(0xFF111722),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('જૂની બાકી રકમ (₹)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _balanceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    filled: true,
                                    fillColor: const Color(0xFF111722),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 6. Billing Type matching Image 1
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('બિલિંગ પ્રકાર', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _billingType,
                            dropdownColor: const Color(0xFF1A2336),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF111722),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'daily', child: Text('રોજિંદો ભાવ (દૈનિક ગણતરી)', style: TextStyle(color: Colors.white, fontSize: 13))),
                              DropdownMenuItem(value: 'fixed', child: Text('માસિક ફિક્સ બિલ', style: TextStyle(color: Colors.white, fontSize: 13))),
                              DropdownMenuItem(value: 'weekly', child: Text('સાપ્તાહિક (Weekly)', style: TextStyle(color: Colors.white, fontSize: 13))),
                            ],
                            onChanged: (v) => setState(() => _billingType = v ?? 'daily'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 7. Address & Society
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _addressCtrl,
                              decoration: InputDecoration(
                                labelText: 'સરનામું / મકાન નં.',
                                filled: true,
                                fillColor: const Color(0xFF111722),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _societyCtrl,
                              decoration: InputDecoration(
                                labelText: 'સોસાયટી શોર્ટ (દા.ત. A-12)',
                                filled: true,
                                fillColor: const Color(0xFF111722),
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 8. Newspaper Selection matching Image 1
                      const Text(
                        'ચાલુ પેપર્સ (સબસ્ક્રિપ્શન)',
                        style: TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      // Dedicated Scrollable Box with 2 Columns matching Image 1
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFF101724),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2A364F)),
                        ),
                        child: Scrollbar(
                          controller: _papersScrollCtrl,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _papersScrollCtrl,
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column (Even indices)
                                Expanded(
                                  child: Column(
                                    children: [
                                      for (int i = 0; i < db.items.length; i += 2)
                                        _buildPaperSubscriptionTile(db.items[i]),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Right Column (Odd indices)
                                Expanded(
                                  child: Column(
                                    children: [
                                      for (int i = 1; i < db.items.length; i += 2)
                                        _buildPaperSubscriptionTile(db.items[i]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Footer Actions matching Image 1
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF263238),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('રદ કરો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _save,
                    child: const Text('ગ્રાહક સાચવો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaperSubscriptionTile(Item item) {
    final isSubscribed = _paperSubscriptions.containsKey(item.id);
    final selectedDays = _paperSubscriptions[item.id] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isSubscribed ? const Color(0xFF132238) : const Color(0xFF161E2E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSubscribed ? const Color(0xFF1E88E5) : const Color(0xFF263248),
          width: isSubscribed ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Paper Title & Checkbox
          InkWell(
            onTap: () {
              setState(() {
                if (isSubscribed) {
                  _paperSubscriptions.remove(item.id);
                } else {
                  _paperSubscriptions[item.id] = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
                }
              });
            },
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: isSubscribed,
                    activeColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _paperSubscriptions[item.id] = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
                        } else {
                          _paperSubscriptions.remove(item.id);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSubscribed ? const Color(0xFF64B5F6) : const Color(0xFF90A4AE),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (isSubscribed) ...[
            const SizedBox(height: 5),
            // Row 1: Weekdays (Mon - Fri) matching Image 1
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _allDays.take(5).map((d) {
                final dCode = d['code']!;
                final dLabel = d['label']!;
                final isDayActive = selectedDays.contains(dCode);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isDayActive) {
                        selectedDays.remove(dCode);
                      } else {
                        selectedDays.add(dCode);
                      }
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: Checkbox(
                          value: isDayActive,
                          activeColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedDays.add(dCode);
                              } else {
                                selectedDays.remove(dCode);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        dLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDayActive ? Colors.white : const Color(0xFF78909C),
                          fontWeight: isDayActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            // Row 2: Weekend (Sat - Sun) matching Image 1
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _allDays.skip(5).map((d) {
                final dCode = d['code']!;
                final dLabel = d['label']!;
                final isDayActive = selectedDays.contains(dCode);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isDayActive) {
                        selectedDays.remove(dCode);
                      } else {
                        selectedDays.add(dCode);
                      }
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: Checkbox(
                          value: isDayActive,
                          activeColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedDays.add(dCode);
                              } else {
                                selectedDays.remove(dCode);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        dLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDayActive ? Colors.white : const Color(0xFF78909C),
                          fontWeight: isDayActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
