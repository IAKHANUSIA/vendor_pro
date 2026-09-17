import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/collection_man.dart';
import '../../core/models/route.dart';
import '../../core/models/salesman.dart';
import 'route_order_dialog.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRouteOrderDialog([int? routeId]) {
    showDialog(
      context: context,
      builder: (ctx) => RouteOrderDialog(
        initialRouteId: routeId,
        onSaved: () => setState(() {}),
      ),
    );
  }

  // 1. Line / Route Dialog with Salesman & Collection Man Combos
  void _openRouteDialog([DeliveryRoute? route]) {
    final db = DatabaseService.instance;
    final codeCtrl = TextEditingController(text: route?.code ?? '');
    final nameCtrl = TextEditingController(text: route?.name ?? '');
    final chargeCtrl = TextEditingController(text: (route?.defaultDeliveryCharge ?? 0.0).toStringAsFixed(0));
    int? selectedSalesmanId = route?.salesmanId;
    int? selectedCollectionManId = route?.collectionManId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgCardDark,
          title: Text(route == null ? '➕ નવી લાઇન ઉમેરો' : '✏️ લાઇનમાં ફેરફાર'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(labelText: 'લાઇન કોડ (દા.ત. L1)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'લાઇનનું નામ (દા.ત. મેઇન બજાર)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Salesman Combo (Dropdown)
                DropdownButtonFormField<int?>(
                  value: selectedSalesmanId,
                  dropdownColor: AppColors.bgCardDark,
                  decoration: const InputDecoration(
                    labelText: '🚴 વિતરક (Salesman) પસંદ કરો',
                    labelStyle: TextStyle(color: AppColors.primaryTeal),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('કોઈ વિતરક નહિ')),
                    ...db.salesmen.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text('${s.name} (${s.mobile})'))),
                  ],
                  onChanged: (v) => setDlgState(() => selectedSalesmanId = v),
                ),
                const SizedBox(height: 12),

                // Collection Man Combo (Dropdown)
                DropdownButtonFormField<int?>(
                  value: selectedCollectionManId,
                  dropdownColor: AppColors.bgCardDark,
                  decoration: const InputDecoration(
                    labelText: '💼 ઉઘરાણીદાર (Collection Man) પસંદ કરો',
                    labelStyle: TextStyle(color: AppColors.purpleLight),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('કોઈ ઉઘરાણીદાર નહિ')),
                    ...db.collectionMen.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text('${c.name} (${c.mobile})'))),
                  ],
                  onChanged: (v) => setDlgState(() => selectedCollectionManId = v),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: chargeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ડિફોલ્ટ ડિલિવરી ચાર્જ (₹/મહિને)', prefixText: '₹'),
                ),
              ],
            ),
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
                  collectionManId: selectedCollectionManId,
                  defaultDeliveryCharge: double.tryParse(chargeCtrl.text) ?? 0.0,
                  status: route?.status ?? 'active',
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

  // 2. Salesman Dialog
  void _openSalesmanDialog([Salesman? salesman]) {
    final db = DatabaseService.instance;
    final nameCtrl = TextEditingController(text: salesman?.name ?? '');
    final mobileCtrl = TextEditingController(text: salesman?.mobile ?? '');
    final addrCtrl = TextEditingController(text: salesman?.address ?? '');
    final commCtrl = TextEditingController(text: salesman?.commissionRate.toString() ?? '0');
    final pinCtrl = TextEditingController(text: salesman?.pin ?? '1111');
    bool obscurePin = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgCardDark,
          title: Text(salesman == null ? '➕ નવો વિતરક (Salesman) ઉમેરો' : '✏️ વિતરકમાં ફેરફાર'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'વિતરકનું નામ'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'મોબાઈલ નંબર'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'સરનામું'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: commCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'કમિશન / પગાર (₹)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  obscureText: obscurePin,
                  decoration: InputDecoration(
                    labelText: '🔐 લૉગિન PIN (૪ થી ૮ આંકડા)',
                    helperText: 'ડિફોલ્ટ PIN: 1111 (ન્યૂનતમ ૪ થી મહત્તમ ૮ આંકડા)',
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(obscurePin ? Icons.visibility : Icons.visibility_off, size: 20),
                      onPressed: () => setDlgState(() => obscurePin = !obscurePin),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('રદ કરો'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final pinText = pinCtrl.text.trim();
                if (pinText.isNotEmpty && (pinText.length < 4 || pinText.length > 8)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ PIN ૪ થી ૮ આંકડાનો હોવો જોઈએ!')),
                  );
                  return;
                }
                final id = salesman?.id ?? (db.salesmen.isEmpty ? 1 : db.salesmen.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
                final newSalesman = Salesman(
                  id: id,
                  name: nameCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  commissionRate: double.tryParse(commCtrl.text) ?? 0.0,
                  status: salesman?.status ?? 'active',
                  pin: pinText.isEmpty ? '1111' : pinText,
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
      ),
    );
  }

  // 3. Collection Man Dialog
  void _openCollectionManDialog([CollectionMan? collectionMan]) {
    final db = DatabaseService.instance;
    final nameCtrl = TextEditingController(text: collectionMan?.name ?? '');
    final mobileCtrl = TextEditingController(text: collectionMan?.mobile ?? '');
    final addrCtrl = TextEditingController(text: collectionMan?.address ?? '');
    final commCtrl = TextEditingController(text: (collectionMan?.commissionRate ?? 0.0).toStringAsFixed(0));
    final pinCtrl = TextEditingController(text: collectionMan?.pin ?? '1111');
    bool obscurePin = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgCardDark,
          title: Text(collectionMan == null ? '➕ નવો ઉઘરાણીદાર (Collection Man) ઉમેરો' : '✏️ ઉઘરાણીદારમાં ફેરફાર'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'ઉઘરાણીદારનું નામ'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'મોબાઈલ નંબર'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'સરનામું'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: commCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'કમિશન / પગાર (₹)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  obscureText: obscurePin,
                  decoration: InputDecoration(
                    labelText: '🔐 લૉગિન PIN (૪ થી ૮ આંકડા)',
                    helperText: 'ડિફોલ્ટ PIN: 1111 (ન્યૂનતમ ૪ થી મહત્તમ ૮ આંકડા)',
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(obscurePin ? Icons.visibility : Icons.visibility_off, size: 20),
                      onPressed: () => setDlgState(() => obscurePin = !obscurePin),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('રદ કરો'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final pinText = pinCtrl.text.trim();
                if (pinText.isNotEmpty && (pinText.length < 4 || pinText.length > 8)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚠️ PIN ૪ થી ૮ આંકડાનો હોવો જોઈએ!')),
                  );
                  return;
                }
                final id = collectionMan?.id ?? (db.collectionMen.isEmpty ? 1 : db.collectionMen.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
                final newCollectionMan = CollectionMan(
                  id: id,
                  name: nameCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  commissionRate: double.tryParse(commCtrl.text) ?? 0.0,
                  status: collectionMan?.status ?? 'active',
                  pin: pinText.isEmpty ? '1111' : pinText,
                );
                if (collectionMan == null) {
                  db.collectionMen.add(newCollectionMan);
                } else {
                  final idx = db.collectionMen.indexWhere((c) => c.id == collectionMan.id);
                  if (idx != -1) db.collectionMen[idx] = newCollectionMan;
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
            indicatorColor: AppColors.primaryTeal,
            labelColor: AppColors.primaryTeal,
            unselectedLabelColor: AppColors.textSecondaryDark,
            tabs: const [
              Tab(icon: Icon(Icons.alt_route, size: 18), text: '🗺️ લાઇન માસ્ટર (Routes)'),
              Tab(icon: Icon(Icons.pedal_bike, size: 18), text: '🚴 વિતરક માસ્ટર (Salesman)'),
              Tab(icon: Icon(Icons.work_outline, size: 18), text: '💼 ઉઘરાણીદાર માસ્ટર (Collection)'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Line Master
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ લાઇનો: ${db.routes.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark)),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.accentCyan),
                            foregroundColor: AppColors.accentCyan,
                          ),
                          onPressed: db.routes.isEmpty ? null : () => _openRouteOrderDialog(),
                          icon: const Icon(Icons.swap_vert, size: 18),
                          label: const Text('🔀 લાઇન ક્રમ ગોઠવો (Reorder)'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _openRouteDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('નવી લાઇન ઉમેરો'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: db.routes.isEmpty
                      ? const Center(child: Text('કોઈ લાઇન નોંધાયેલ નથી'))
                      : ListView.builder(
                          itemCount: db.routes.length,
                          itemBuilder: (ctx, i) {
                            final r = db.routes[i];
                            final custCount = db.customers.where((c) => c.routeId == r.id).length;
                            final salesman = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == r.salesmanId, orElse: () => null);
                            final collectionMan = db.collectionMen.cast<CollectionMan?>().firstWhere((c) => c?.id == r.collectionManId, orElse: () => null);
                            final isActive = r.isActive;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: (isActive ? AppColors.primaryTeal : Colors.grey).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    r.code,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? AppColors.accentCyan : Colors.grey),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isActive ? AppColors.successGreen : AppColors.danger).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isActive ? 'સક્રિય' : 'નિષ્ક્રિય',
                                        style: TextStyle(fontSize: 10, color: isActive ? AppColors.successLight : AppColors.dangerLight, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  'ગ્રાહકો: $custCount | વિતરક: ${salesman?.name ?? "કોઈ નહિ"} | ઉઘરાણીદાર: ${collectionMan?.name ?? "કોઈ નહિ"}',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.swap_vert, size: 20, color: AppColors.accentCyan),
                                      tooltip: 'આ લાઇનનો ગ્રાહક ક્રમ ગોઠવો',
                                      onPressed: () => _openRouteOrderDialog(r.id),
                                    ),
                                    // Active / Inactive Switch
                                    Switch(
                                      value: isActive,
                                      activeColor: AppColors.successGreen,
                                      onChanged: (val) {
                                        setState(() => r.status = val ? 'active' : 'inactive');
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryLight),
                                      onPressed: () => _openRouteDialog(r),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerLight),
                                      onPressed: () => setState(() => db.routes.removeAt(i)),
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

          // Tab 2: Salesman Master
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ વિતરકો (Salesmen): ${db.salesmen.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark)),
                    ElevatedButton.icon(
                      onPressed: () => _openSalesmanDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવો વિતરક ઉમેરો'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: db.salesmen.isEmpty
                      ? const Center(child: Text('કોઈ વિતરક નોંધાયેલ નથી'))
                      : ListView.builder(
                          itemCount: db.salesmen.length,
                          itemBuilder: (ctx, i) {
                            final s = db.salesmen[i];
                            final assignedRoutes = db.routes.where((r) => r.salesmanId == s.id).map((r) => r.name).join(', ');
                            final isActive = s.isActive;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.bgSurfaceDark,
                                  child: Text('🚴'),
                                ),
                                title: Row(
                                  children: [
                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isActive ? AppColors.successGreen : AppColors.danger).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isActive ? 'સક્રિય' : 'નિષ્ક્રિય',
                                        style: TextStyle(fontSize: 10, color: isActive ? AppColors.successLight : AppColors.dangerLight, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentCyan.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '🔒 PIN: ${s.pin}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '📞 ${s.mobile} ${s.address.isNotEmpty ? "• 🏠 " + s.address : ""}\nલાઇનો: ${assignedRoutes.isNotEmpty ? assignedRoutes : "કોઈ નહિ"}',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Active / Inactive Switch
                                    Switch(
                                      value: isActive,
                                      activeColor: AppColors.successGreen,
                                      onChanged: (val) {
                                        setState(() => s.status = val ? 'active' : 'inactive');
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryLight),
                                      onPressed: () => _openSalesmanDialog(s),
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

          // Tab 3: Collection Man Master
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('કુલ ઉઘરાણીદાર (Collection Men): ${db.collectionMen.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
                      onPressed: () => _openCollectionManDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('નવો ઉઘરાણીદાર ઉમેરો'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: db.collectionMen.isEmpty
                      ? const Center(child: Text('કોઈ ઉઘરાણીદાર નોંધાયેલ નથી'))
                      : ListView.builder(
                          itemCount: db.collectionMen.length,
                          itemBuilder: (ctx, i) {
                            final c = db.collectionMen[i];
                            final assignedRoutes = db.routes.where((r) => r.collectionManId == c.id).map((r) => r.name).join(', ');
                            final isActive = c.isActive;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.bgSurfaceDark,
                                  child: Text('💼'),
                                ),
                                title: Row(
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isActive ? AppColors.successGreen : AppColors.danger).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isActive ? 'સક્રિય' : 'નિષ્ક્રિય',
                                        style: TextStyle(fontSize: 10, color: isActive ? AppColors.successLight : AppColors.dangerLight, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.purple.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '🔒 PIN: ${c.pin}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.purple, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '📞 ${c.mobile} ${c.address.isNotEmpty ? "• 🏠 " + c.address : ""}\nઉઘરાણી લાઇનો: ${assignedRoutes.isNotEmpty ? assignedRoutes : "કોઈ નહિ"}',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Active / Inactive Switch
                                    Switch(
                                      value: isActive,
                                      activeColor: AppColors.successGreen,
                                      onChanged: (val) {
                                        setState(() => c.status = val ? 'active' : 'inactive');
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryLight),
                                      onPressed: () => _openCollectionManDialog(c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerLight),
                                      onPressed: () => setState(() => db.collectionMen.removeAt(i)),
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
