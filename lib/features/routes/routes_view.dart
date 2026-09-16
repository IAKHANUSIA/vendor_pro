import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/route.dart';
import '../../core/models/salesman.dart';

class RoutesView extends StatefulWidget {
  const RoutesView({super.key});

  @override
  State<RoutesView> createState() => _RoutesViewState();
}

class _RoutesViewState extends State<RoutesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRouteDialog([DeliveryRoute? route]) {
    final db = DatabaseService.instance;
    final codeCtrl = TextEditingController(text: route?.code ?? '');
    final nameCtrl = TextEditingController(text: route?.name ?? '');
    int? selectedSalesmanId = route?.salesmanId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgCardDark,
          title: Text(route == null ? '➕ નવી લાઇન ઉમેરો' : '✏️ લાઇનમાં ફેરફાર'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'લાઇન કોડ (દા.ત. L1)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'લાઇનનું નામ (દા.ત. મેઇન બજાર)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedSalesmanId,
                dropdownColor: AppColors.bgCardDark,
                decoration: const InputDecoration(labelText: 'નિયુક્ત વિતરક (Hawker)'),
                items: db.salesmen.map((s) {
                  return DropdownMenuItem<int>(
                    value: s.id,
                    child: Text(s.name),
                  );
                }).toList(),
                onChanged: (v) => setDlgState(() => selectedSalesmanId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('રદ કરો'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                final id = route?.id ?? (db.routes.isEmpty ? 1 : db.routes.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
                final newRoute = DeliveryRoute(
                  id: id,
                  code: codeCtrl.text.trim().toUpperCase(),
                  name: nameCtrl.text.trim(),
                  salesmanId: selectedSalesmanId,
                );
                if (route == null) {
                  db.routes.add(newRoute);
                } else {
                  final idx = db.routes.indexWhere((r) => r.id == route.id);
                  if (idx != -1) db.routes[idx] = newRoute;
                }
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

  void _openSalesmanDialog([Salesman? salesman]) {
    final db = DatabaseService.instance;
    final nameCtrl = TextEditingController(text: salesman?.name ?? '');
    final mobileCtrl = TextEditingController(text: salesman?.mobile ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCardDark,
        title: Text(salesman == null ? '➕ નવો વિતરક (Hawker) ઉમેરો' : '✏️ વિતરકમાં ફેરફાર'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'વિતરકનું નામ'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'મોબાઈલ નંબર'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('રદ કરો'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final id = salesman?.id ?? (db.salesmen.isEmpty ? 1 : db.salesmen.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
              final newSalesman = Salesman(
                id: id,
                name: nameCtrl.text.trim(),
                mobile: mobileCtrl.text.trim(),
              );
              if (salesman == null) {
                db.salesmen.add(newSalesman);
              } else {
                final idx = db.salesmen.indexWhere((s) => s.id == salesman.id);
                if (idx != -1) db.salesmen[idx] = newSalesman;
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
              Tab(icon: Icon(Icons.alt_route, size: 18), text: 'ડિલિવરી લાઇન / રૂટ'),
              Tab(icon: Icon(Icons.pedal_bike, size: 18), text: 'છાપાં વિતરક (Hawkers)'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Routes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ લાઇન: ${db.routes.length}', style: const TextStyle(color: AppColors.textSecondaryDark)),
                    ElevatedButton.icon(
                      onPressed: () => _openRouteDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવી લાઇન ઉમેરો'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: db.routes.length,
                    itemBuilder: (ctx, i) {
                      final r = db.routes[i];
                      final sm = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == r.salesmanId, orElse: () => null);
                      final custCount = db.customers.where((c) => c.routeId == r.id && c.status == 'active').length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: Text(r.code, style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'વિતરક: ${sm?.name ?? "કોઈ નહીં"} • ગ્રાહકો: $custCount',
                            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryLight),
                            onPressed: () => _openRouteDialog(r),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tab 2: Salesmen
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ વિતરકો: ${db.salesmen.length}', style: const TextStyle(color: AppColors.textSecondaryDark)),
                    ElevatedButton.icon(
                      onPressed: () => _openSalesmanDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવો વિતરક ઉમેરો'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: db.salesmen.length,
                    itemBuilder: (ctx, i) {
                      final s = db.salesmen[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.success.withOpacity(0.15),
                            child: const Text('🚴', style: TextStyle(fontSize: 16)),
                          ),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            s.mobile.isNotEmpty ? '📞 ${s.mobile}' : 'મોબાઈલ નંબર નથી',
                            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryLight),
                            onPressed: () => _openSalesmanDialog(s),
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
