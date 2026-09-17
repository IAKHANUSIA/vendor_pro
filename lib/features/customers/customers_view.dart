import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/collection_man.dart';
import '../../core/models/customer.dart';
import '../../core/models/item.dart';
import '../../core/models/route.dart';
import '../../core/models/salesman.dart';
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
        initialRouteId: routeId,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openSwitchPaperDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => _SwitchPaperDialog(
        customer: customer,
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

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCardDark,
        title: const Text('ગ્રાહક હટાવો?'),
        content: Text('શું તમે ખરેખર "${customer.name}" ને હટાવવા માંગો છો?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
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
            child: const Text('હટાવો'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final customers = _filteredCustomers;

    final activeCount = db.customers.where((c) => c.isActive).length;
    final inactiveCount = db.customers.where((c) => !c.isActive).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Bar Row 1: Search & Dropdowns
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondaryDark),
                      hintText: 'નામ, લાઇન, મોબાઇલ, કોડથી શોધો...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Route Filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedRouteFilter,
                    dropdownColor: AppColors.bgCardDark,
                    decoration: const InputDecoration(isDense: true, labelText: 'લાઇન ફિલ્ટર'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('બધી લાઇન')),
                      ...db.routes.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedRouteFilter = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Salesman / Delivery Filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedSalesmanFilter,
                    dropdownColor: AppColors.bgCardDark,
                    decoration: const InputDecoration(isDense: true, labelText: '🚴 વિતરક ફિલ્ટર'),
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
                // Status Filter Dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    dropdownColor: AppColors.bgCardDark,
                    decoration: const InputDecoration(isDense: true, labelText: 'સ્થિતિ (Status)'),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('બધા ($activeCount સક્રિય / $inactiveCount બંધ)')),
                      const DropdownMenuItem(value: 'active', child: Text('🟢 ફક્ત સક્રિય')),
                      const DropdownMenuItem(value: 'inactive', child: Text('🔴 ફક્ત બંધ')),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accentCyan),
                    foregroundColor: AppColors.accentCyan,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  onPressed: () => _openRouteOrderDialog(_selectedRouteFilter),
                  icon: const Icon(Icons.swap_vert, size: 16),
                  label: const Text('🔀 ક્રમ'),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onPressed: () => _openCustomerDialog(),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('નવો ગ્રાહક'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Cards List
            Expanded(
              child: customers.isEmpty
                  ? const Center(
                      child: Text(
                        'કોઈ ગ્રાહક મળ્યા નથી',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (ctx, index) {
                        final c = customers[index];
                        final route = db.routes.cast<DeliveryRoute?>().firstWhere((r) => r?.id == c.routeId, orElse: () => null);
                        final salesman = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == route?.salesmanId, orElse: () => null);
                        final collectionMan = db.collectionMen.cast<CollectionMan?>().firstWhere((cm) => cm?.id == route?.collectionManId, orElse: () => null);

                        final subPapers = c.subscriptionItemIds
                            .map((id) => db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null)?.name)
                            .where((n) => n != null)
                            .toList();

                        final isPending = c.currentBalance > 0;
                        final isActive = c.isActive;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Sequence badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    c.code.isNotEmpty ? c.code : c.sequenceNo,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? AppColors.primaryLight : Colors.grey, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Customer Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isActive ? Colors.white : Colors.grey,
                                                decoration: isActive ? null : TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ),
                                          // Active status pill
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
                                          const SizedBox(width: 8),
                                          // Balance badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isPending ? AppColors.danger : AppColors.success).withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: (isPending ? AppColors.danger : AppColors.success).withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              isPending ? 'બાકી: ₹${c.currentBalance.toStringAsFixed(0)}' : 'ચુકતે (₹0)',
                                              style: TextStyle(
                                                color: isPending ? AppColors.dangerLight : AppColors.successLight,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Line, Salesman, Collection Man, Mobile, Address
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          if (route != null)
                                            Text('🗺️ ${route.name}', style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                                          if (salesman != null)
                                            Text('🚴 વિતરક: ${salesman.name}', style: const TextStyle(color: AppColors.primaryTeal, fontSize: 12)),
                                          if (collectionMan != null)
                                            Text('💼 ઉઘરાણીદાર: ${collectionMan.name}', style: const TextStyle(color: AppColors.purpleLight, fontSize: 12)),
                                          if (c.mobile.isNotEmpty)
                                            Text('📞 ${c.mobile}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                                          if (c.address.isNotEmpty)
                                            Text('🏠 ${c.address}', style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // Subscribed Papers list
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: subPapers.map((p) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text('📰 $p', style: const TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),

                                // Actions & Active Toggle Switch
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: isActive,
                                      activeColor: AppColors.successGreen,
                                      onChanged: (val) {
                                        setState(() {
                                          c.status = val ? 'active' : 'inactive';
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.swap_horiz, size: 20, color: AppColors.accentCyan),
                                      onPressed: () => _openSwitchPaperDialog(c),
                                      tooltip: '🔄 પેપર બદલો (Switch Paper)',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryLight),
                                      onPressed: () => _openCustomerDialog(c),
                                      tooltip: 'સુધારો',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerLight),
                                      onPressed: () => _deleteCustomer(c),
                                      tooltip: 'હટાવો',
                                    ),
                                  ],
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
    );
  }
}

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
  late TextEditingController _mobileCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _societyCtrl;
  late TextEditingController _delChargeAmtCtrl;
  late TextEditingController _fixedAmtCtrl;
  late TextEditingController _balanceCtrl;

  late int _routeId;
  int? _insertAfterSeq;
  String _insertAfterHelpText = '';
  String _billingType = 'daily';
  bool _delChargeEnabled = false;
  bool _printEnabled = true;
  bool _isActive = true;

  // Paper Subscription mapping: ItemId -> Set of selected day codes
  final Map<int, Set<String>> _paperSubscriptions = {};

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
    _mobileCtrl = TextEditingController(text: c?.mobile ?? '');
    _whatsappCtrl = TextEditingController(text: c?.whatsapp.isNotEmpty == true ? c!.whatsapp : (c?.mobile ?? ''));
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _societyCtrl = TextEditingController(text: c?.societyShort ?? '');
    _delChargeAmtCtrl = TextEditingController(text: (c?.delChargeAmt ?? 10.0).toStringAsFixed(0));
    _fixedAmtCtrl = TextEditingController(text: c?.fixedMonthlyAmount.toString() ?? '0');
    _balanceCtrl = TextEditingController(text: c?.currentBalance.toString() ?? '0');

    _billingType = c?.billingType ?? 'daily';
    _delChargeEnabled = c?.delChargeEnabled ?? false;
    _isActive = c?.isActive ?? true;

    if (c == null) {
      _insertAfterHelpText = 'લાઇનનો છેલ્લો ક્રમ $defaultSeq અપાશે';
    }

    // Initialize paper subscriptions
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
        _insertAfterHelpText = 'લાઇનનો છેલ્લો ક્રમ $nextSeq અપાશે';
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _seqCtrl.dispose();
    _mobileCtrl.dispose();
    _whatsappCtrl.dispose();
    _addressCtrl.dispose();
    _societyCtrl.dispose();
    _delChargeAmtCtrl.dispose();
    _fixedAmtCtrl.dispose();
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
      mobile: _mobileCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim().isNotEmpty ? _whatsappCtrl.text.trim() : _mobileCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      societyShort: _societyCtrl.text.trim(),
      routeId: _routeId,
      billingType: _billingType,
      delChargeEnabled: _delChargeEnabled,
      delChargeAmt: _delChargeEnabled ? (double.tryParse(_delChargeAmtCtrl.text) ?? 10.0) : 0.0,
      fixedMonthlyAmount: double.tryParse(_fixedAmtCtrl.text) ?? 0.0,
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

    // Auto lookup assigned Salesman and Collection Man for currently selected Line
    final selectedRoute = db.routes.cast<DeliveryRoute?>().firstWhere((r) => r?.id == _routeId, orElse: () => null);
    final autoSalesman = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == selectedRoute?.salesmanId, orElse: () => null);
    final autoCollectionMan = db.collectionMen.cast<CollectionMan?>().firstWhere((cm) => cm?.id == selectedRoute?.collectionManId, orElse: () => null);

    final routeCustomers = db.customers
        .where((c) => c.routeId == _routeId && c.id != widget.customer?.id)
        .toList()
      ..sort((a, b) => (int.tryParse(a.sequenceNo) ?? 0).compareTo(int.tryParse(b.sequenceNo) ?? 0));

    return Dialog(
      backgroundColor: const Color(0xFF1E2433),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 850,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Customer Code Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2A3447)),
                        ),
                        child: Text(
                          _codeCtrl.text.isNotEmpty ? _codeCtrl.text : 'નવો ગ્રાહક',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.customer == null ? '➕ નવો ગ્રાહક ઉમેરો' : '✏️ ગ્રાહકની વિગત બદલો',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (widget.customer != null) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.accentCyan),
                            foregroundColor: AppColors.accentCyan,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (ctx) => _SwitchPaperDialog(
                                customer: widget.customer!,
                                onSaved: widget.onSaved,
                              ),
                            );
                          },
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('🔄 પેપર બદલો', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      // Active/Inactive toggle inside form
                      Row(
                        children: [
                          Text(_isActive ? '🟢 સક્રિય' : '🔴 નિષ્ક્રિય', style: TextStyle(color: _isActive ? AppColors.successGreen : AppColors.dangerLight, fontWeight: FontWeight.bold, fontSize: 12)),
                          Switch(
                            value: _isActive,
                            activeColor: AppColors.successGreen,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Color(0xFF2A3447), height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Line Selection, Sequence & Auto-populated Salesman/Collection Display
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              value: _routeId,
                              dropdownColor: const Color(0xFF1E2433),
                              decoration: const InputDecoration(
                                labelText: 'ડિલિવરી લાઇન (Route)',
                                labelStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                              ),
                              items: db.routes.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.name} (${r.code})'))).toList(),
                              onChanged: (v) {
                                if (v != null) _onRouteChange(v);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _seqCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'ક્રમ નં.'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Insert After Dropdown (New feature!)
                      DropdownButtonFormField<int?>(
                        value: _insertAfterSeq,
                        dropdownColor: const Color(0xFF1E2433),
                        decoration: InputDecoration(
                          labelText: '📍 કોના પછી લાઇન ક્રમમાં ઉમેરવો? (Insert After)',
                          labelStyle: const TextStyle(color: AppColors.accentCyan, fontSize: 13, fontWeight: FontWeight.w600),
                          helperText: _insertAfterHelpText.isNotEmpty ? '💡 $_insertAfterHelpText' : null,
                          helperStyle: const TextStyle(color: AppColors.primaryTeal, fontSize: 11),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('-- લાઇનના અંતે ઉમેરો (Add to End of Route) --'),
                          ),
                          ...routeCustomers.map((rc) => DropdownMenuItem<int?>(
                                value: int.tryParse(rc.sequenceNo) ?? 0,
                                child: Text(
                                  '[ક્રમ ${rc.sequenceNo}] #${rc.custNo.isNotEmpty ? rc.custNo : rc.code} ${rc.societyShort.isNotEmpty ? "[" + rc.societyShort + "] " : ""}${rc.name}${rc.address.isNotEmpty ? " - " + rc.address : ""}',
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
                              _insertAfterHelpText = 'નવો ગ્રાહક ક્રમ $nextSeq પર મુકાશે (પાછળના બધા ગ્રાહકો આપોઆપ +1 ખસી જશે)';
                            } else {
                              final maxSeq = routeCustomers.fold<int>(0, (max, item) => (int.tryParse(item.sequenceNo) ?? 0) > max ? (int.tryParse(item.sequenceNo) ?? 0) : max);
                              final nextSeq = maxSeq + 1;
                              _seqCtrl.text = '$nextSeq';
                              _insertAfterHelpText = 'લાઇનનો છેલ્લો ક્રમ $nextSeq અપાશે';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      // Auto-populated Read-Only Staff info from Line Selection (Requirement 4)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B26),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2A3447)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.pedal_bike, color: AppColors.primaryTeal, size: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('નિયુક્ત વિતરક (Salesman):', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                      Text(
                                        autoSalesman != null ? '${autoSalesman.name} (${autoSalesman.mobile})' : 'કોઈ વિતરક નિયુક્ત નથી',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: const Color(0xFF2A3447)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.work_outline, color: AppColors.purpleLight, size: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('નિયુક્ત ઉઘરાણીદાર (Collection Man):', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                      Text(
                                        autoCollectionMan != null ? '${autoCollectionMan.name} (${autoCollectionMan.mobile})' : 'કોઈ ઉઘરાણીદાર નિયુક્ત નથી',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2. Customer Name & Billing Type
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(labelText: 'ગ્રાહકનું પૂરું નામ'),
                              validator: (v) => v?.trim().isEmpty == true ? 'નામ લખો' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _billingType,
                              dropdownColor: const Color(0xFF1E2433),
                              decoration: const InputDecoration(labelText: 'બિલિંગ પ્રકાર'),
                              items: const [
                                DropdownMenuItem(value: 'daily', child: Text('રોજિંદો ભાવ (દૈનિક ગણતરી)')),
                                DropdownMenuItem(value: 'fixed', child: Text('માસિક ફિક્સ ભાવ')),
                              ],
                              onChanged: (v) => setState(() => _billingType = v ?? 'daily'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 3. Delivery Charge (Y/N) with auto-disable charge field + Print Y/N (Requirement 4)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<bool>(
                              value: _delChargeEnabled,
                              dropdownColor: const Color(0xFF1E2433),
                              decoration: const InputDecoration(
                                labelText: 'Del.Charge(Y/N)',
                                labelStyle: TextStyle(color: AppColors.accentCyan, fontSize: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: false, child: Text('NO')),
                                DropdownMenuItem(value: true, child: Text('YES')),
                              ],
                              onChanged: (v) => setState(() => _delChargeEnabled = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _delChargeAmtCtrl,
                              enabled: _delChargeEnabled, // Disabled when Del.Charge is NO (Requirement 4)
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'ચાર્જ રકમ (₹)',
                                labelStyle: TextStyle(
                                  color: _delChargeEnabled ? AppColors.accentCyan : Colors.grey,
                                  fontSize: 12,
                                ),
                                fillColor: _delChargeEnabled ? null : const Color(0xFF141822),
                                filled: !_delChargeEnabled,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<bool>(
                              value: _printEnabled,
                              dropdownColor: const Color(0xFF1E2433),
                              decoration: const InputDecoration(
                                labelText: 'Print(Y/N)',
                                labelStyle: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: true, child: Text('Yes')),
                                DropdownMenuItem(value: false, child: Text('No')),
                              ],
                              onChanged: (v) => setState(() => _printEnabled = v ?? true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _balanceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'જૂની બાકી (₹)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 4. Mobile & WhatsApp Numbers
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mobileCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'મોબાઈલ નંબર'),
                              onChanged: (v) {
                                if (_whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _mobileCtrl.text.substring(0, _mobileCtrl.text.length > 0 ? _mobileCtrl.text.length - 1 : 0)) {
                                  _whatsappCtrl.text = v;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _whatsappCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'વૉટ્સએપ નંબર'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 5. Address & Society Short
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _addressCtrl,
                              decoration: const InputDecoration(labelText: 'સરનામું / મકાન નં.'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _societyCtrl,
                              decoration: const InputDecoration(labelText: 'સોસાયટી શોર્ટ'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 6. LAST SECTION: Newspaper Choice in 3-4 columns (Requirement 5)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '📰 ચાલુ પેપર્સ (સબસ્ક્રિપ્શન):',
                            style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'પસંદ કરેલ પેપર: ${_paperSubscriptions.length}',
                            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Dynamic 3-4 Column Grid of Newspapers
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          // 3 to 4 columns on larger displays, 2 on smaller displays
                          final crossCount = constraints.maxWidth >= 750 ? 3 : (constraints.maxWidth >= 500 ? 2 : 1);

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: db.items.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              // If checked -> expanded card (175 height), if unchecked -> compact single line tile (52 height)
                              mainAxisExtent: 170,
                            ),
                            itemBuilder: (ctx, idx) {
                              final item = db.items[idx];
                              final isSubscribed = _paperSubscriptions.containsKey(item.id);
                              final selectedDays = _paperSubscriptions[item.id] ?? {};

                              if (!isSubscribed) {
                                // Single line compact tile when unselected (Requirement 5)
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _paperSubscriptions[item.id] = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF161B26),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF2A3447)),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: false,
                                            side: const BorderSide(color: Color(0xFF5A6E8C), width: 1.5),
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _paperSubscriptions[item.id] = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.name.toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: Color(0xFF8B9CB5),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // Expanded card with days when selected (Requirement 5)
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161B26),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.accentCyan.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Paper Checkbox & Name
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _paperSubscriptions.remove(item.id);
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: true,
                                              activeColor: const Color(0xFF1D8CF8),
                                              onChanged: (val) {
                                                setState(() {
                                                  _paperSubscriptions.remove(item.id);
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.name.toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: AppColors.accentCyan,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(color: Color(0xFF2A3447), height: 8),

                                    // 2-Column Days Grid
                                    Expanded(
                                      child: GridView.count(
                                        crossAxisCount: 2,
                                        childAspectRatio: 3.2,
                                        physics: const NeverScrollableScrollPhysics(),
                                        children: _allDays.map((d) {
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
                                                  width: 18,
                                                  height: 18,
                                                  child: Checkbox(
                                                    value: isDayActive,
                                                    activeColor: const Color(0xFF1D8CF8),
                                                    side: const BorderSide(color: Color(0xFF5A6E8C), width: 1.2),
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
                                                const SizedBox(width: 4),
                                                Text(
                                                  dLabel,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: isDayActive ? FontWeight.bold : FontWeight.normal,
                                                    color: isDayActive ? Colors.white : const Color(0xFF8B9CB5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      side: const BorderSide(color: Color(0xFF3B4861)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('રદ કરો', style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D8CF8), Color(0xFF0072FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _save,
                      child: const Text(
                        'ગ્રાહક સાચવો',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchPaperDialog extends StatefulWidget {
  final Customer customer;
  final VoidCallback onSaved;

  const _SwitchPaperDialog({required this.customer, required this.onSaved});

  @override
  State<_SwitchPaperDialog> createState() => _SwitchPaperDialogState();
}

class _SwitchPaperDialogState extends State<_SwitchPaperDialog> {
  DateTime _effectiveDate = DateTime.now();
  int? _oldPaperId;
  int? _newPaperId;
  final Set<String> _selectedNewDays = {'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'};

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
    final subIds = widget.customer.subscriptionItemIds;
    if (subIds.isNotEmpty) {
      _oldPaperId = subIds.first;
    }
  }

  void _save() {
    if (_oldPaperId == null && _newPaperId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('કૃપા કરીને જૂનું અથવા નવું પેપર પસંદ કરો.')),
      );
      return;
    }

    final db = DatabaseService.instance;
    final effStr = DateFormat('yyyy-MM-dd').format(_effectiveDate);

    db.switchCustomerPaper(
      customerId: widget.customer.id,
      effectiveDate: effStr,
      oldPaperId: _oldPaperId,
      newPaperId: _newPaperId,
      newDays: _selectedNewDays.toList(),
    );

    widget.onSaved();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('સફળતાપૂર્વક પેપર બદલાઈ ગયું! ✅'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final subIds = widget.customer.subscriptionItemIds;
    final activePapers = db.items.where((i) => i.isActive).toList();

    final prevDay = _effectiveDate.subtract(const Duration(days: 1));
    final prevDayStr = DateFormat('dd/MM/yyyy').format(prevDay);
    final effStr = DateFormat('dd/MM/yyyy').format(_effectiveDate);

    final oldItem = db.items.cast<Item?>().firstWhere((i) => i?.id == _oldPaperId, orElse: () => null);
    final newItem = db.items.cast<Item?>().firstWhere((i) => i?.id == _newPaperId, orElse: () => null);

    return Dialog(
      backgroundColor: const Color(0xFF161B26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.swap_horiz, color: AppColors.accentCyan, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔄 પેપર બદલો વિઝાર્ડ (Switch Paper)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        Text(
                          '${widget.customer.name} (ક્રમ: #${widget.customer.sequenceNo})',
                          style: const TextStyle(fontSize: 12, color: AppColors.accentCyan),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xFF2A3447), height: 20),

            // Effective Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _effectiveDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _effectiveDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2433),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A3447)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppColors.accentCyan),
                        SizedBox(width: 8),
                        Text(
                          'અસરકારક તારીખ (નવું પેપર કઈ તારીખથી શરૂ કરવું?):',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_effectiveDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Old Paper Dropdown
            DropdownButtonFormField<int?>(
              value: _oldPaperId,
              dropdownColor: const Color(0xFF1E2433),
              decoration: const InputDecoration(
                labelText: '🔴 જૂનું પેપર (જે બંધ કરવું હોય)',
                labelStyle: TextStyle(color: AppColors.dangerLight, fontWeight: FontWeight.bold),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('➕ (કોઈ પેપર બંધ નથી કરવું - માત્ર નવું ઉમેરવું છે)'),
                ),
                ...subIds.map((id) {
                  final it = db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null);
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text('🔴 ${it?.name ?? "ID: $id"} (${it?.code ?? ""})'),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _oldPaperId = v),
            ),
            const SizedBox(height: 12),

            // New Paper Dropdown
            DropdownButtonFormField<int?>(
              value: _newPaperId,
              dropdownColor: const Color(0xFF1E2433),
              decoration: const InputDecoration(
                labelText: '🟢 નવું પેપર (જે શરૂ કરવું હોય)',
                labelStyle: TextStyle(color: AppColors.successLight, fontWeight: FontWeight.bold),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('🛑 (કોઈ નવું પેપર નથી લેવું - માત્ર જૂનું બંધ કરવું છે)'),
                ),
                ...activePapers.map((it) => DropdownMenuItem<int?>(
                  value: it.id,
                  child: Text('🟢 ${it.name} (${it.code}) - ₹${it.saleRate.toStringAsFixed(0)}'),
                )),
              ],
              onChanged: (v) => setState(() => _newPaperId = v),
            ),
            const SizedBox(height: 12),

            // Day checkboxes for New Paper
            if (_newPaperId != null) ...[
              const Text('નવા પેપરના વાર પસંદ કરો:', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _allDays.map((d) {
                  final isSelected = _selectedNewDays.contains(d['code']);
                  return FilterChip(
                    label: Text(d['label']!),
                    selected: isSelected,
                    selectedColor: AppColors.accentCyan.withOpacity(0.2),
                    checkmarkColor: AppColors.accentCyan,
                    labelStyle: TextStyle(color: isSelected ? AppColors.accentCyan : AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedNewDays.add(d['code']!);
                        } else {
                          _selectedNewDays.remove(d['code']!);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Live Preview Summary Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2A3447)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 આપમેળે થનાર ફેરફાર (Live Summary):', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  if (oldItem != null)
                    Text('• 🔴 ${oldItem.name} તારીખ $prevDayStr સુધી જ વિતરણ થશે અને બિલમાં ગણાશે.', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  if (newItem != null)
                    Text('• 🟢 ${newItem.name} તારીખ $effStr થી શરૂ થશે.', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  if (oldItem == null && newItem == null)
                    const Text('કૃપા કરીને જૂનું અથવા નવું પેપર પસંદ કરો.', style: TextStyle(color: AppColors.textMutedDark, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('રદ કરો', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCyan, foregroundColor: Colors.black),
                  onPressed: (_oldPaperId == null && _newPaperId == null) ? null : _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('પેપર બદલો સાચવો', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

