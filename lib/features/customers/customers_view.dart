import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/customer.dart';
import '../../core/models/item.dart';

class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedRouteFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> get _filteredCustomers {
    final db = DatabaseService.instance;
    return db.customers.where((c) {
      if (_selectedRouteFilter != null && c.routeId != _selectedRouteFilter) return false;
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
    final t = AppLocalizations.of(context);
    final customers = _filteredCustomers;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Bar
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
                const SizedBox(width: 10),
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
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _openCustomerDialog(),
                  icon: const Icon(Icons.person_add, size: 18),
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
                        final route = db.routes.cast<dynamic>().firstWhere((r) => r.id == c.routeId, orElse: () => null);
                        final subPapers = c.subscriptionItemIds
                            .map((id) => db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null)?.name)
                            .where((n) => n != null)
                            .toList();

                        final isPending = c.currentBalance > 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Sequence badge
                                Container(
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    c.code.isNotEmpty ? c.code : c.sequenceNo,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 13),
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
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                            ),
                                          ),
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

                                      // Line, Mobile, Address
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          if (route != null)
                                            Text('🗺️ ${route.name}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
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

                                // Actions
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
  String _billingType = 'daily';
  bool _delChargeEnabled = false;
  bool _printEnabled = true;

  // Paper Subscription mapping: ItemId -> Set of selected day codes: {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'}
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

    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _codeCtrl = TextEditingController(text: c?.code.isNotEmpty == true ? c!.code : (c?.custNo ?? '${db.customers.length + 101}'));
    _seqCtrl = TextEditingController(text: c?.sequenceNo ?? '${db.customers.length + 1}');
    _mobileCtrl = TextEditingController(text: c?.mobile ?? '');
    _whatsappCtrl = TextEditingController(text: c?.whatsapp.isNotEmpty == true ? c!.whatsapp : (c?.mobile ?? ''));
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _societyCtrl = TextEditingController(text: c?.societyShort ?? '');
    _delChargeAmtCtrl = TextEditingController(text: (c?.delChargeAmt ?? 10.0).toStringAsFixed(0));
    _fixedAmtCtrl = TextEditingController(text: c?.fixedMonthlyAmount.toString() ?? '0');
    _balanceCtrl = TextEditingController(text: c?.currentBalance.toString() ?? '0');

    _routeId = c?.routeId ?? (db.routes.isNotEmpty ? db.routes.first.id : 1);
    _billingType = c?.billingType ?? 'daily';
    _delChargeEnabled = c?.delChargeEnabled ?? false;

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
      // Default select first item for new customer with all days
      _paperSubscriptions[db.items.first.id] = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
    }
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

    // Prepare subscriptions dictionary: {"1": ["mon", "tue", ...], "2": ["mon", ...]}
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
      delChargeAmt: double.tryParse(_delChargeAmtCtrl.text) ?? 10.0,
      fixedMonthlyAmount: double.tryParse(_fixedAmtCtrl.text) ?? 0.0,
      currentBalance: double.tryParse(_balanceCtrl.text) ?? 0.0,
      subscriptions: savedSubscriptions,
    );

    if (widget.customer == null) {
      db.customers.add(newCust);
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

    return Dialog(
      backgroundColor: const Color(0xFF1E2433),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 750),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Customer Code Badge (matching Image 2)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  Text(
                    widget.customer == null ? '➕ નવો ગ્રાહક' : '✏️ ગ્રાહક સુધારો',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Name & Line
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
                            child: DropdownButtonFormField<int>(
                              value: _routeId,
                              dropdownColor: const Color(0xFF1E2433),
                              decoration: const InputDecoration(labelText: 'ડિલિવરી લાઇન'),
                              items: db.routes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                              onChanged: (v) => setState(() => _routeId = v ?? _routeId),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Delivery Charge (Y/N), Charge Amount, Print Y/N (matching Image 2)
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
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'ચાર્જ રકમ (₹)',
                                labelStyle: TextStyle(color: AppColors.accentCyan, fontSize: 12),
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
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Mobile Number & WhatsApp Number (matching Image 2)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mobileCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'મોબાઈલ નંબર'),
                              onChanged: (v) {
                                if (_whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _mobileCtrl.text.substring(0, _mobileCtrl.text.length - 1)) {
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

                      // Billing Type Dropdown (matching Image 2)
                      DropdownButtonFormField<String>(
                        value: _billingType,
                        dropdownColor: const Color(0xFF1E2433),
                        decoration: const InputDecoration(
                          labelText: 'બિલિંગ પ્રકાર',
                          labelStyle: TextStyle(fontSize: 13),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('રોજિંદો ભાવ (દૈનિક ગણતરી)')),
                          DropdownMenuItem(value: 'fixed', child: Text('માસિક ફિક્સ ભાવ')),
                        ],
                        onChanged: (v) => setState(() => _billingType = v ?? 'daily'),
                      ),
                      const SizedBox(height: 16),

                      // Section Header: ચાલુ પેપર્સ (સબસ્ક્રિપ્શન) (matching Image 2)
                      const Text(
                        'ચાલુ પેપર્સ (સબસ્ક્રિપ્શન)',
                        style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 10),

                      // Paper Selection Grid (matching Image 2)
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          final crossCount = constraints.maxWidth >= 500 ? 2 : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: db.items.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              mainAxisExtent: 185,
                            ),
                            itemBuilder: (ctx, idx) {
                              final item = db.items[idx];
                              final isSubscribed = _paperSubscriptions.containsKey(item.id);
                              final selectedDays = _paperSubscriptions[item.id] ?? {};

                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161B26),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSubscribed ? AppColors.accentCyan.withOpacity(0.4) : const Color(0xFF2A3447),
                                    width: isSubscribed ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Paper Checkbox & Name
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
                                            width: 22,
                                            height: 22,
                                            child: Checkbox(
                                              value: isSubscribed,
                                              activeColor: const Color(0xFF1D8CF8),
                                              side: const BorderSide(color: Color(0xFF5A6E8C), width: 1.5),
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
                                                color: isSubscribed ? AppColors.accentCyan : const Color(0xFF8B9CB5),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Day Checkboxes (2 columns matching Image 2)
                                    if (isSubscribed) ...[
                                      const Divider(color: Color(0xFF2A3447), height: 8),
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
                                    ] else
                                      const Spacer(),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Address & Society details
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _addressCtrl,
                              decoration: const InputDecoration(labelText: 'સરનામું / મકાન નં.'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _societyCtrl,
                              decoration: const InputDecoration(labelText: 'સોસાયટી શોર્ટ'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Opening Balance & Sequence
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _seqCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'ડિલિવરી ક્રમ નં.'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _balanceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'જૂની બાકી રકમ (₹)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Action Buttons (matching Image 2)
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
