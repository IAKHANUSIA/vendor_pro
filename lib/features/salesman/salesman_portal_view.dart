import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/customer.dart';
import '../../core/models/item.dart';
import '../../core/models/route.dart';
import '../../core/models/salesman.dart';

class SalesmanPortalView extends StatefulWidget {
  const SalesmanPortalView({super.key});

  @override
  State<SalesmanPortalView> createState() => _SalesmanPortalViewState();
}

class _SalesmanPortalViewState extends State<SalesmanPortalView> with SingleTickerProviderStateMixin {
  int? _selectedRouteId;
  final String _todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final db = DatabaseService.instance;
    if (db.routes.isNotEmpty) {
      _selectedRouteId = db.routes.first.id;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSalesmanMasterDialog([Salesman? salesman]) {
    final db = DatabaseService.instance;
    final nameCtrl = TextEditingController(text: salesman?.name ?? '');
    final mobileCtrl = TextEditingController(text: salesman?.mobile ?? '');
    final addrCtrl = TextEditingController(text: salesman?.address ?? '');
    final commCtrl = TextEditingController(text: salesman?.commissionRate.toString() ?? '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCardDark,
        title: Text(salesman == null ? '➕ નવો હોકર / સેલ્સમેન' : '✏️ વિતરક સુધારો'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'હોકરનું પૂરું નામ')),
            const SizedBox(height: 10),
            TextField(controller: mobileCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'મોબાઈલ નંબર')),
            const SizedBox(height: 10),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'સરનામું')),
            const SizedBox(height: 10),
            TextField(controller: commCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'કમિશન / પગાર (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final id = salesman?.id ?? (db.salesmen.isEmpty ? 1 : db.salesmen.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1);
              final newS = Salesman(
                id: id,
                name: nameCtrl.text.trim(),
                mobile: mobileCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                commissionRate: double.tryParse(commCtrl.text) ?? 0.0,
              );
              if (salesman == null) {
                db.salesmen.add(newS);
              } else {
                final idx = db.salesmen.indexWhere((s) => s.id == salesman.id);
                if (idx != -1) db.salesmen[idx] = newS;
              }
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('સાચવો'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final today = DateTime.now();
    final dayOfWeek = today.weekday % 7;

    // Filter customers for selected route
    final routeCustomers = db.customers.where((c) {
      if (c.status != 'active') return false;
      if (_selectedRouteId != null && c.routeId != _selectedRouteId) return false;
      return true;
    }).toList()
      ..sort((a, b) => (int.tryParse(a.sequenceNo) ?? 0).compareTo(int.tryParse(b.sequenceNo) ?? 0));

    // Calculate line paper counts
    final Map<int, int> linePaperCounts = {};
    for (final c in routeCustomers) {
      final isOnVacation = db.vacations.any((v) => v.customerId == c.id && v.isActiveOn(_todayStr));
      if (isOnVacation) continue;

      for (final itemId in c.subscriptionItemIds) {
        if (c.isSubscribedOnDay(itemId, dayOfWeek, _todayStr)) {
          linePaperCounts[itemId] = (linePaperCounts[itemId] ?? 0) + 1;
        }
      }
    }

    final selectedRoute = db.routes.cast<DeliveryRoute?>().firstWhere((r) => r?.id == _selectedRouteId, orElse: () => null);
    final assignedSalesman = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == selectedRoute?.salesmanId, orElse: () => null);

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
              Tab(icon: Icon(Icons.delivery_dining, size: 18), text: '🚴 સવારની હોકર ડિલિવરી શીટ'),
              Tab(icon: Icon(Icons.people_outline, size: 18), text: '👥 હોકર્સ / સેલ્સમેન માસ્ટર'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Hawker Morning Delivery Sheet
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Selection Row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        value: _selectedRouteId,
                        dropdownColor: AppColors.bgCardDark,
                        decoration: const InputDecoration(labelText: 'લાઇન / રૂટ પસંદ કરો'),
                        items: db.routes.map((r) {
                          final s = db.salesmen.cast<Salesman?>().firstWhere((sm) => sm?.id == r.salesmanId, orElse: () => null);
                          return DropdownMenuItem(
                            value: r.id,
                            child: Text('${r.name} (${r.code}) ${s != null ? "• " + s.name : ""}'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedRouteId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                      ),
                      child: Text(
                        '📅 ${DateFormat('dd/MM/yyyy').format(today)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Line Total Papers Summary Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.newspaper, color: AppColors.primaryTeal, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${selectedRoute?.name ?? "લાઇન"} ના સવારે જોઈતા કુલ પેપર્સ:',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                          if (assignedSalesman != null)
                            Text(
                              'હોકર: ${assignedSalesman.name} (${assignedSalesman.mobile})',
                              style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: linePaperCounts.entries.map((e) {
                          final it = db.items.cast<Item?>().firstWhere((i) => i?.id == e.key, orElse: () => null);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                            ),
                            child: Text(
                              '${it?.name ?? "પેપર"}: ${e.value} નકલ',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Customers Checklist for Hawker
                Expanded(
                  child: routeCustomers.isEmpty
                      ? const Center(child: Text('આ લાઇન પર કોઈ સક્રિય ગ્રાહક નથી'))
                      : ListView.builder(
                          itemCount: routeCustomers.length,
                          itemBuilder: (ctx, i) {
                            final c = routeCustomers[i];
                            final isOnVacation = db.vacations.any((v) => v.customerId == c.id && v.isActiveOn(_todayStr));
                            final status = db.getDeliveryStatus(_todayStr, c.id);

                            // Today's subscribed papers for this customer
                            final todayPapers = c.subscriptionItemIds
                                .where((id) => c.isSubscribedOnDay(id, dayOfWeek, _todayStr))
                                .map((id) => db.items.cast<Item?>().firstWhere((item) => item?.id == id, orElse: () => null)?.name)
                                .where((n) => n != null)
                                .toList();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Sequence Number Badge
                                    Container(
                                      width: 38,
                                      height: 38,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c.sequenceNo,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal, fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Customer info and papers
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                          ),
                                          if (c.address.isNotEmpty)
                                            Text(
                                              '🏠 ${c.address}',
                                              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                            ),
                                          const SizedBox(height: 4),

                                          if (isOnVacation)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.danger.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('🌴 રજા પર (પેપર આપવું નહિ)', style: TextStyle(color: AppColors.dangerLight, fontSize: 11, fontWeight: FontWeight.bold)),
                                            )
                                          else
                                            Wrap(
                                              spacing: 6,
                                              children: todayPapers.map((p) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text('📰 $p', style: const TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.w600)),
                                                );
                                              }).toList(),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Delivery Checkbox / Toggle
                                    if (!isOnVacation)
                                      InkWell(
                                        onTap: () {
                                          final next = status == 'delivered' ? 'skipped' : 'delivered';
                                          setState(() => db.setDeliveryStatus(_todayStr, c.id, next));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: (status == 'delivered' ? AppColors.successGreen : AppColors.warning).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: (status == 'delivered' ? AppColors.successGreen : AppColors.warning).withOpacity(0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                status == 'delivered' ? Icons.check_circle : Icons.radio_button_unchecked,
                                                color: status == 'delivered' ? AppColors.successGreen : AppColors.warning,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                status == 'delivered' ? 'ડિલિવર્ડ' : 'બાકી',
                                                style: TextStyle(
                                                  color: status == 'delivered' ? AppColors.successGreen : AppColors.warning,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
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
                          },
                        ),
                ),
              ],
            ),
          ),

          // Tab 2: Salesmen / Hawkers Master
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ વિતરકો (Hawkers): ${db.salesmen.length}', style: const TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _openSalesmanMasterDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવો હોકર ઉમેરો'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: db.salesmen.isEmpty
                      ? const Center(child: Text('કોઈ હોકર નોંધાયેલ નથી'))
                      : ListView.builder(
                          itemCount: db.salesmen.length,
                          itemBuilder: (ctx, i) {
                            final s = db.salesmen[i];
                            final assignedRoutes = db.routes.where((r) => r.salesmanId == s.id).map((r) => r.name).join(', ');

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.bgSurfaceDark,
                                  child: Text('🚴'),
                                ),
                                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text(
                                  '📞 ${s.mobile} ${s.address.isNotEmpty ? "• 🏠 " + s.address : ""}\nનિયુક્ત લાઇન: ${assignedRoutes.isNotEmpty ? assignedRoutes : "કોઈ નહિ"}',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryLight),
                                      onPressed: () => _openSalesmanMasterDialog(s),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerLight),
                                      onPressed: () => setState(() => db.salesmen.removeAt(i)),
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
        ],
      ),
    );
  }
}
