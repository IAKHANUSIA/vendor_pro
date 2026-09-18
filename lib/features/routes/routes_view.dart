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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _cleanName(String raw) {
    if (raw.contains('à²') || raw.contains('à³')) {
      return raw.replaceAll(RegExp(r'à[^\s]+\s*'), 'લાઇન ');
    }
    return raw;
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

  // 1. Line / Route Dialog matching Image 2
  void _openRouteDialog([DeliveryRoute? route]) {
    final db = DatabaseService.instance;
    final codeCtrl = TextEditingController(text: route?.code ?? '');
    final nameCtrl = TextEditingController(text: route != null ? _cleanName(route.name) : '');
    final chargeCtrl = TextEditingController(text: (route?.defaultDeliveryCharge ?? 0.0).toStringAsFixed(0));
    int? selectedSalesmanId = route?.salesmanId;
    int? selectedCollectionManId = route?.collectionManId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(route == null ? '➕ નવી લાઇન ઉમેરો' : '✏️ લાઇનમાં ફેરફાર', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: codeCtrl,
                          decoration: InputDecoration(
                            labelText: 'લાઇન કોડ (દા.ત. L-A)',
                            filled: true,
                            fillColor: const Color(0xFF141A28),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'લાઇનનું નામ (દા.ત. લાઇન A (Line A))',
                            filled: true,
                            fillColor: const Color(0xFF141A28),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Salesman Combo
                  DropdownButtonFormField<int?>(
                    value: selectedSalesmanId,
                    dropdownColor: const Color(0xFF1A2336),
                    decoration: InputDecoration(
                      labelText: '🚴 વિતરક (Salesman) પસંદ કરો',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('કોઈ વિતરક નહિ', style: TextStyle(color: Color(0xFF90A4AE)))),
                      ...db.salesmen.map((s) => DropdownMenuItem<int?>(
                        value: s.id,
                        child: Text(
                          s.isActive ? s.name : '${s.name} (❌ નોકરી છોડેલ)',
                          style: TextStyle(color: s.isActive ? Colors.white : const Color(0xFFEF5350)),
                        ),
                      )),
                    ],
                    onChanged: (v) => setDlgState(() => selectedSalesmanId = v),
                  ),
                  const SizedBox(height: 12),

                  // Collection Man Combo
                  DropdownButtonFormField<int?>(
                    value: selectedCollectionManId,
                    dropdownColor: const Color(0xFF1A2336),
                    decoration: InputDecoration(
                      labelText: '💼 ઉઘરાણીદાર (Collection Man) પસંદ કરો',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('કોઈ ઉઘરાણીદાર નહિ', style: TextStyle(color: Color(0xFF90A4AE)))),
                      ...db.collectionMen.map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(
                          c.isActive ? c.name : '${c.name} (❌ નોકરી છોડેલ)',
                          style: TextStyle(color: c.isActive ? Colors.white : const Color(0xFFEF5350)),
                        ),
                      )),
                    ],
                    onChanged: (v) => setDlgState(() => selectedCollectionManId = v),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: chargeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'ડિફોલ્ટ ડિલિવરી ચાર્જ (₹/મહિને)',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('રદ કરો', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
              child: const Text('સાચવો', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Salesman Dialog matching Image 1
  void _openSalesmanDialog([Salesman? salesman]) {
    final db = DatabaseService.instance;
    final nameCtrl = TextEditingController(text: salesman?.name ?? '');
    final mobileCtrl = TextEditingController(text: salesman?.mobile ?? '');
    final addrCtrl = TextEditingController(text: salesman?.address ?? '');
    final salaryCtrl = TextEditingController(text: (salesman != null && salesman.salary > 0) ? salesman.salary.toStringAsFixed(0) : '');
    final notesCtrl = TextEditingController(text: salesman?.notes ?? '');
    final pinCtrl = TextEditingController(text: salesman?.pin ?? '1111');
    String status = salesman?.status ?? 'active';
    bool obscurePin = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(salesman == null ? '➕ નવો વિતરક (Salesman) ઉમેરો' : '✏️ વિતરકમાં ફેરફાર', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'વિતરકનું નામ (Salesman Name) *',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: mobileCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'મોબાઈલ નંબર',
                            hintText: '98250 00000',
                            filled: true,
                            fillColor: const Color(0xFF141A28),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: salaryCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'માસિક પગાર (Salary ₹)',
                            prefixText: '₹ ',
                            hintText: 'દા.ત. 2500',
                            filled: true,
                            fillColor: const Color(0xFF141A28),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addrCtrl,
                    decoration: InputDecoration(
                      labelText: 'સરનામું / વિસ્તાર',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'નોંધ (Notes)',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    obscureText: obscurePin,
                    decoration: InputDecoration(
                      labelText: '🔐 લૉગિન PIN (૪ થી ૮ આંકડા)',
                      helperText: 'ડિફોલ્ટ PIN: 1111 (ન્યૂનતમ ૪ થી મહત્તમ ૮ આંકડા)',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePin ? Icons.visibility : Icons.visibility_off, size: 20, color: Colors.white70),
                        onPressed: () => setDlgState(() => obscurePin = !obscurePin),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    dropdownColor: const Color(0xFF1E2638),
                    decoration: InputDecoration(
                      labelText: 'નોકરીની સ્થિતિ (Staff Status)',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                            SizedBox(width: 8),
                            Text('✅ સક્રિય (Active - નોકરી ચાલુ)', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Color(0xFFEF5350), size: 16),
                            SizedBox(width: 8),
                            Text('❌ નિષ્ક્રિય (Inactive - નોકરી છોડેલ)', style: TextStyle(color: Color(0xFFEF5350))),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => status = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('રદ કરો', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
                  salary: double.tryParse(salaryCtrl.text) ?? 0.0,
                  notes: notesCtrl.text.trim(),
                  status: status,
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
              child: const Text('સાચવો', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Collection Man Dialog matching Image 1
  void _openCollectionManDialog([CollectionMan? collectionMan]) {
    final db = DatabaseService.instance;
    final nameCtrl = TextEditingController(text: collectionMan?.name ?? '');
    final mobileCtrl = TextEditingController(text: collectionMan?.mobile ?? '');
    final addrCtrl = TextEditingController(text: collectionMan?.address ?? '');
    final salaryCtrl = TextEditingController(text: (collectionMan != null && collectionMan.salary > 0) ? collectionMan.salary.toStringAsFixed(0) : '');
    final notesCtrl = TextEditingController(text: collectionMan?.notes ?? '');
    final pinCtrl = TextEditingController(text: collectionMan?.pin ?? '1111');
    String status = collectionMan?.status ?? 'active';
    bool obscurePin = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(collectionMan == null ? '➕ નવો ઉઘરાણી સ્ટાફ (Collection Men) ઉમેરો' : '✏️ ઉઘરાણી સ્ટાફમાં ફેરફાર', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ઉઘરાણીદારનું નામ (Name) *',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: mobileCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'મોબાઈલ નંબર',
                            hintText: '98250 00000',
                            filled: true,
                            fillColor: const Color(0xFF141A28),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: salaryCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'માસિક પગાર (Salary ₹)',
                            prefixText: '₹ ',
                            hintText: 'દા.ત. 2000',
                            filled: true,
                            fillColor: const Color(0xFF141A28),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addrCtrl,
                    decoration: InputDecoration(
                      labelText: 'સરનામું / વિસ્તાર',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'નોંધ (Notes)',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: pinCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    obscureText: obscurePin,
                    decoration: InputDecoration(
                      labelText: '🔐 લૉગિન PIN (૪ થી ૮ આંકડા)',
                      helperText: 'ડિફોલ્ટ PIN: 1111 (ન્યૂનતમ ૪ થી મહત્તમ ૮ આંકડા)',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePin ? Icons.visibility : Icons.visibility_off, size: 20, color: Colors.white70),
                        onPressed: () => setDlgState(() => obscurePin = !obscurePin),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    dropdownColor: const Color(0xFF1E2638),
                    decoration: InputDecoration(
                      labelText: 'નોકરીની સ્થિતિ (Staff Status)',
                      filled: true,
                      fillColor: const Color(0xFF141A28),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                            SizedBox(width: 8),
                            Text('✅ સક્રિય (Active - નોકરી ચાલુ)', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Color(0xFFEF5350), size: 16),
                            SizedBox(width: 8),
                            Text('❌ નિષ્ક્રિય (Inactive - નોકરી છોડેલ)', style: TextStyle(color: Color(0xFFEF5350))),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => status = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('રદ કરો', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
                  salary: double.tryParse(salaryCtrl.text) ?? 0.0,
                  notes: notesCtrl.text.trim(),
                  status: status,
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
              child: const Text('સાચવો', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final activeTab = _tabController.index;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar matching Image 1 & 2
            Row(
              children: [
                const Icon(Icons.menu_book, color: Color(0xFF42A5F5), size: 24),
                const SizedBox(width: 10),
                const Text(
                  'ડિલિવરી લાઇન અને સ્ટાફ માસ્ટર',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (activeTab == 0) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF42A5F5)),
                      foregroundColor: const Color(0xFF42A5F5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onPressed: db.routes.isEmpty ? null : () => _openRouteOrderDialog(),
                    icon: const Icon(Icons.swap_vert, size: 18),
                    label: const Text('🔀 લાઇન ક્રમ ગોઠવો'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _openRouteDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('નવી લાઇન ઉમેરો', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ] else if (activeTab == 1) ...[
                  ElevatedButton.icon(
                    onPressed: () => _openSalesmanDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('નવો વિતરક (Salesman)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => _openCollectionManDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('નવો ઉઘરાણી સ્ટાફ (Collection Men)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Modern Pill Navigation Bar matching Image 1 & 2
            Row(
              children: [
                _buildTabPill(0, '🗺️ ડિલિવરી લાઇન (Lines)', Icons.alt_route),
                const SizedBox(width: 10),
                _buildTabPill(1, '🚴 વિતરક / હોકર માસ્ટર (Salesmen)', Icons.pedal_bike),
                const SizedBox(width: 10),
                _buildTabPill(2, '💼 ઉઘરાણી સ્ટાફ (Collection Men)', Icons.work_outline),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Views Container
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Line Master Table (Image 2)
                  _buildLinesTable(db),

                  // Tab 2: Salesman Master Table (Image 1)
                  _buildSalesmenTable(db),

                  // Tab 3: Collection Men Master Table (Image 1 & 2)
                  _buildCollectionMenTable(db),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label, IconData icon) {
    final isSelected = _tabController.index == index;
    return InkWell(
      onTap: () => _tabController.animateTo(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFF141A28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF2A364F),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF90A4AE),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: LINE MASTER TABLE MATCHING IMAGE 2
  // -------------------------------------------------------------
  Widget _buildLinesTable(DatabaseService db) {
    if (db.routes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131B2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF222F46)),
        ),
        child: const Center(
          child: Text('કોઈ લાઇન નોંધાયેલ નથી', style: TextStyle(color: Color(0xFF78909C), fontSize: 16)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222F46)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            color: const Color(0xFF172033),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: const [
                SizedBox(width: 90, child: Text('લાઇન કોડ', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 3, child: Text('લાઇન / રૂટનું નામ', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 3, child: Text('નિયુક્ત વિતરક (હોકર)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 3, child: Text('નિયુક્ત કલેક્શન મેન', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 110, child: Text('કુલ ગ્રાહકો', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 90, child: Text('ક્રિયાઓ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF222F46)),

          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: db.routes.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1E283C)),
              itemBuilder: (ctx, index) {
                final r = db.routes[index];
                final custCount = db.customers.where((c) => c.routeId == r.id).length;
                final salesman = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == r.salesmanId, orElse: () => null);
                final collectionMan = db.collectionMen.cast<CollectionMan?>().firstWhere((c) => c?.id == r.collectionManId, orElse: () => null);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: index.isEven ? Colors.transparent : const Color(0xFF161E2E).withOpacity(0.5),
                  child: Row(
                    children: [
                      // Code Badge (Golden / Amber pill matching Image 2)
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E2415),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.5)),
                            ),
                            child: Text(
                              r.code,
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Line / Route Name (Cleaned)
                      Expanded(
                        flex: 3,
                        child: Text(
                          _cleanName(r.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Assigned Salesman matching Image 2
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            const Icon(Icons.pedal_bike, size: 14, color: Color(0xFF42A5F5)),
                            const SizedBox(width: 5),
                            Text(
                              salesman != null ? salesman.name.toUpperCase() : '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '(📞 ${salesman != null && salesman.mobile.isNotEmpty ? salesman.mobile : "-"})',
                              style: const TextStyle(
                                color: Color(0xFFEF5350),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Assigned Collection Man matching Image 2
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            const Icon(Icons.work_outline, size: 14, color: Color(0xFFFFA726)),
                            const SizedBox(width: 5),
                            Text(
                              collectionMan != null ? collectionMan.name.toUpperCase() : '-',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '(📞 ${collectionMan != null && collectionMan.mobile.isNotEmpty ? collectionMan.mobile : "-"})',
                              style: const TextStyle(
                                color: Color(0xFFEF5350),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Customer Count matching Image 2
                      SizedBox(
                        width: 110,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2B48),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.4)),
                            ),
                            child: Text(
                              '$custCount ગ્રાહકો',
                              style: const TextStyle(
                                color: Color(0xFF64B5F6),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Actions
                      SizedBox(
                        width: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E283C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFFFFA726), size: 16),
                                onPressed: () => _openRouteDialog(r),
                                tooltip: 'સુધારો (Edit)',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E283C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 16),
                                onPressed: () => setState(() => db.routes.removeAt(index)),
                                tooltip: 'હટાવો (Delete)',
                              ),
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
    );
  }

  // -------------------------------------------------------------
  // TAB 2: SALESMAN MASTER TABLE MATCHING IMAGE 1
  // -------------------------------------------------------------
  Widget _buildSalesmenTable(DatabaseService db) {
    if (db.salesmen.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131B2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF222F46)),
        ),
        child: const Center(
          child: Text('કોઈ વિતરક નોંધાયેલ નથી', style: TextStyle(color: Color(0xFF78909C), fontSize: 16)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222F46)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            color: const Color(0xFF172033),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('વિતરકનું નામ (SALESMAN)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('મોબાઇલ નંબર', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 4, child: Text('સંભાળતી લાઇન', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 130, child: Text('માસિક પગાર (SALARY ₹)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 110, child: Text('સ્થિતિ (STATUS)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 80, child: Text('નોંધ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 90, child: Text('ક્રિયા', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF222F46)),

          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: db.salesmen.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1E283C)),
              itemBuilder: (ctx, index) {
                final s = db.salesmen[index];
                final assignedRoutes = db.routes
                    .where((r) => r.salesmanId == s.id)
                    .map((r) => '${r.code} (${_cleanName(r.name).replaceAll(RegExp(r'લાઇન\s*'), '')})')
                    .join(', ');

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: index.isEven ? Colors.transparent : const Color(0xFF161E2E).withOpacity(0.5),
                  child: Row(
                    children: [
                      // Salesman Name matching Image 1
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Icon(Icons.pedal_bike, size: 15, color: s.isActive ? const Color(0xFF42A5F5) : const Color(0xFF78909C)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: s.isActive ? Colors.white : const Color(0xFF90A4AE),
                                  fontSize: 13,
                                  decoration: s.isActive ? null : TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mobile Number matching Image 1
                      Expanded(
                        flex: 2,
                        child: s.mobile.isNotEmpty
                            ? Row(
                                children: [
                                  Icon(Icons.phone, size: 13, color: s.isActive ? const Color(0xFFEF5350) : const Color(0xFF78909C)),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.mobile,
                                    style: TextStyle(
                                      color: s.isActive ? Colors.white : const Color(0xFF90A4AE),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : const Text('-', style: TextStyle(color: Color(0xFF78909C), fontSize: 13)),
                      ),

                      // Assigned Handling Lines matching Image 1
                      Expanded(
                        flex: 4,
                        child: assignedRoutes.isNotEmpty
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F2B48),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    assignedRoutes,
                                    style: const TextStyle(
                                      color: Color(0xFF90CAF9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A2336),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('-', style: TextStyle(color: Color(0xFF78909C), fontSize: 11)),
                                ),
                              ),
                      ),

                      // Monthly Salary matching Image 1
                      SizedBox(
                        width: 130,
                        child: Text(
                          s.salary > 0 ? '₹${s.salary.toStringAsFixed(0)}' : '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Status Toggle Chip
                      SizedBox(
                        width: 110,
                        child: Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                s.status = s.isActive ? 'inactive' : 'active';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(s.isActive
                                      ? '✅ ${s.name} ને સક્રિય કર્યા.'
                                      : '❌ ${s.name} ને નિષ્ક્રિય (નોકરી છોડેલ) તરીકે માર્ક કર્યા.'),
                                  backgroundColor: s.isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Tooltip(
                              message: 'સ્થિતિ બદલવા ક્લિક કરો',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: s.isActive
                                      ? const Color(0xFF1B5E20).withOpacity(0.25)
                                      : const Color(0xFFB71C1C).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: s.isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      s.isActive ? Icons.check_circle : Icons.cancel,
                                      size: 13,
                                      color: s.isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      s.isActive ? 'સક્રિય' : 'છોડેલ',
                                      style: TextStyle(
                                        color: s.isActive ? const Color(0xFF81C784) : const Color(0xFFE57373),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Notes matching Image 1
                      SizedBox(
                        width: 80,
                        child: Text(
                          s.notes.isNotEmpty ? s.notes : '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF78909C),
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Actions matching Image 1
                      SizedBox(
                        width: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E283C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFFFFA726), size: 16),
                                onPressed: () => _openSalesmanDialog(s),
                                tooltip: 'સુધારો (Edit)',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E283C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 16),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dlgCtx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E2638),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text('⚠️ ${s.name} - સ્ટાફ મેનેજમેન્ટ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      content: const Text(
                                        'જો આ કર્મચારી નોકરી છોડી ગયા હોય, તો જૂના ડિલિવરી રેકોર્ડ્સ અને હિસાબો સાચવવા માટે "નિષ્ક્રિય (છોડેલ)" માર્ક કરવાની સલાહ આપવામાં આવે છે.\n\nતમે શું કરવા માંગો છો?',
                                        style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 13, height: 1.4),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dlgCtx),
                                          child: const Text('રદ કરો', style: TextStyle(color: Colors.white70)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                                          onPressed: () {
                                            setState(() => s.status = 'inactive');
                                            Navigator.pop(dlgCtx);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('❌ ${s.name} ને નિષ્ક્રિય માર્ક કર્યા')),
                                            );
                                          },
                                          child: const Text('નોકરી છોડેલ માર્ક કરો', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF5350)),
                                          onPressed: () {
                                            setState(() => db.salesmen.removeAt(index));
                                            Navigator.pop(dlgCtx);
                                          },
                                          child: const Text('કાયમ હટાવો', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                tooltip: 'હટાવો અથવા નિષ્ક્રિય કરો',
                              ),
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
    );
  }

  // -------------------------------------------------------------
  // TAB 3: COLLECTION MEN MASTER TABLE
  // -------------------------------------------------------------
  Widget _buildCollectionMenTable(DatabaseService db) {
    if (db.collectionMen.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131B2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF222F46)),
        ),
        child: const Center(
          child: Text('કોઈ ઉઘરાણીદાર નોંધાયેલ નથી', style: TextStyle(color: Color(0xFF78909C), fontSize: 16)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222F46)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            color: const Color(0xFF172033),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('ઉઘરાણીદારનું નામ (COLLECTION MAN)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('મોબાઇલ નંબર', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 4, child: Text('સંભાળતી લાઇન', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 130, child: Text('માસિક પગાર (SALARY ₹)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 110, child: Text('સ્થિતિ (STATUS)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 80, child: Text('નોંધ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 90, child: Text('ક્રિયા', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF222F46)),

          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: db.collectionMen.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1E283C)),
              itemBuilder: (ctx, index) {
                final c = db.collectionMen[index];
                final assignedRoutes = db.routes
                    .where((r) => r.collectionManId == c.id)
                    .map((r) => '${r.code} (${_cleanName(r.name).replaceAll(RegExp(r'લાઇન\s*'), '')})')
                    .join(', ');

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: index.isEven ? Colors.transparent : const Color(0xFF161E2E).withOpacity(0.5),
                  child: Row(
                    children: [
                      // Collection Man Name
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Icon(Icons.work_outline, size: 15, color: c.isActive ? const Color(0xFFFFA726) : const Color(0xFF78909C)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.name.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: c.isActive ? Colors.white : const Color(0xFF90A4AE),
                                  fontSize: 13,
                                  decoration: c.isActive ? null : TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mobile Number
                      Expanded(
                        flex: 2,
                        child: c.mobile.isNotEmpty
                            ? Row(
                                children: [
                                  Icon(Icons.phone, size: 13, color: c.isActive ? const Color(0xFFEF5350) : const Color(0xFF78909C)),
                                  const SizedBox(width: 4),
                                  Text(
                                    c.mobile,
                                    style: TextStyle(
                                      color: c.isActive ? Colors.white : const Color(0xFF90A4AE),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : const Text('-', style: TextStyle(color: Color(0xFF78909C), fontSize: 13)),
                      ),

                      // Handling Lines
                      Expanded(
                        flex: 4,
                        child: assignedRoutes.isNotEmpty
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F2B48),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    assignedRoutes,
                                    style: const TextStyle(
                                      color: Color(0xFF90CAF9),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A2336),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('-', style: TextStyle(color: Color(0xFF78909C), fontSize: 11)),
                                ),
                              ),
                      ),

                      // Monthly Salary
                      SizedBox(
                        width: 130,
                        child: Text(
                          c.salary > 0 ? '₹${c.salary.toStringAsFixed(0)}' : '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Status Toggle Chip
                      SizedBox(
                        width: 110,
                        child: Center(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                c.status = c.isActive ? 'inactive' : 'active';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(c.isActive
                                      ? '✅ ${c.name} ને સક્રિય કર્યા.'
                                      : '❌ ${c.name} ને નિષ્ક્રિય (નોકરી છોડેલ) તરીકે માર્ક કર્યા.'),
                                  backgroundColor: c.isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Tooltip(
                              message: 'સ્થિતિ બદલવા ક્લિક કરો',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: c.isActive
                                      ? const Color(0xFF1B5E20).withOpacity(0.25)
                                      : const Color(0xFFB71C1C).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: c.isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      c.isActive ? Icons.check_circle : Icons.cancel,
                                      size: 13,
                                      color: c.isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.isActive ? 'સક્રિય' : 'છોડેલ',
                                      style: TextStyle(
                                        color: c.isActive ? const Color(0xFF81C784) : const Color(0xFFE57373),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Notes
                      SizedBox(
                        width: 80,
                        child: Text(
                          c.notes.isNotEmpty ? c.notes : '-',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF78909C),
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Actions
                      SizedBox(
                        width: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E283C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFFFFA726), size: 16),
                                onPressed: () => _openCollectionManDialog(c),
                                tooltip: 'સુધારો (Edit)',
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E283C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 16),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (dlgCtx) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E2638),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: Text('⚠️ ${c.name} - સ્ટાફ મેનેજમેન્ટ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      content: const Text(
                                        'જો આ ઉઘરાણી સ્ટાફ નોકરી છોડી ગયા હોય, તો જૂની ઉઘરાણી પહોંચ અને હિસાબો સાચવવા માટે "નિષ્ક્રિય (છોડેલ)" માર્ક કરવાની સલાહ આપવામાં આવે છે.\n\nતમે શું કરવા માંગો છો?',
                                        style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 13, height: 1.4),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dlgCtx),
                                          child: const Text('રદ કરો', style: TextStyle(color: Colors.white70)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA726)),
                                          onPressed: () {
                                            setState(() => c.status = 'inactive');
                                            Navigator.pop(dlgCtx);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('❌ ${c.name} ને નિષ્ક્રિય માર્ક કર્યા')),
                                            );
                                          },
                                          child: const Text('નોકરી છોડેલ માર્ક કરો', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF5350)),
                                          onPressed: () {
                                            setState(() => db.collectionMen.removeAt(index));
                                            Navigator.pop(dlgCtx);
                                          },
                                          child: const Text('કાયમ હટાવો', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                tooltip: 'હટાવો અથવા નિષ્ક્રિય કરો',
                              ),
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
    );
  }
}
