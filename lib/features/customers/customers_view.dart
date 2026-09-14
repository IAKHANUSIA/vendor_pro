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
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryDark),
                      hintText: 'નામ, લાઇન, મોબાઇલથી શોધો...',
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
                  ? Center(
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
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c.sequenceNo,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
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
                                          Text(
                                            c.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                          ),
                                          if (c.societyShort.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(c.societyShort, style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                                            ),
                                          ],
                                          if (c.billingType == 'fixed') ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.warning.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text('માસિક ₹${c.fixedMonthlyAmount}', style: const TextStyle(fontSize: 10, color: AppColors.warningLight)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'લાઇન: ${route?.name ?? "R1"} • 📞 ${c.mobile.isNotEmpty ? c.mobile : "-"}',
                                        style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: subPapers.map((p) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(p!, style: const TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),

                                // Balance & Actions
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isPending ? AppColors.danger.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '₹${c.currentBalance.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isPending ? AppColors.dangerLight : AppColors.successLight,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryLight),
                                          onPressed: () => _openCustomerDialog(c),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.dangerLight),
                                          onPressed: () => _deleteCustomer(c),
                                        ),
                                      ],
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
  late TextEditingController _seqCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _societyCtrl;
  late TextEditingController _fixedAmtCtrl;
  late TextEditingController _balanceCtrl;

  late int _routeId;
  String _billingType = 'daily';
  final Set<int> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    final db = DatabaseService.instance;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _seqCtrl = TextEditingController(text: c?.sequenceNo ?? '${db.customers.length + 1}');
    _mobileCtrl = TextEditingController(text: c?.mobile ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
    _societyCtrl = TextEditingController(text: c?.societyShort ?? '');
    _fixedAmtCtrl = TextEditingController(text: c?.fixedMonthlyAmount.toString() ?? '0');
    _balanceCtrl = TextEditingController(text: c?.currentBalance.toString() ?? '0');

    _routeId = c?.routeId ?? (db.routes.isNotEmpty ? db.routes.first.id : 1);
    _billingType = c?.billingType ?? 'daily';

    if (c != null) {
      _selectedItemIds.addAll(c.subscriptionItemIds);
    } else if (db.items.isNotEmpty) {
      _selectedItemIds.add(db.items.first.id);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _seqCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _societyCtrl.dispose();
    _fixedAmtCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final db = DatabaseService.instance;
    final id = widget.customer?.id ?? (db.customers.isEmpty ? 1 : db.customers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

    final newCust = Customer(
      id: id,
      name: _nameCtrl.text.trim(),
      sequenceNo: _seqCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      societyShort: _societyCtrl.text.trim(),
      routeId: _routeId,
      billingType: _billingType,
      fixedMonthlyAmount: double.tryParse(_fixedAmtCtrl.text) ?? 0.0,
      currentBalance: double.tryParse(_balanceCtrl.text) ?? 0.0,
      subscriptions: _selectedItemIds.toList(),
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
      backgroundColor: AppColors.bgCardDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Text(
                      widget.customer == null ? '➕ નવો ગ્રાહક ઉમેરો' : '✏️ ગ્રાહકની વિગત બદલો',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderDark),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _seqCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ક્રમ નં.'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'ગ્રાહકનું પૂરું નામ'),
                        validator: (v) => v?.trim().isEmpty == true ? 'નામ લખો' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _routeId,
                        dropdownColor: AppColors.bgCardDark,
                        decoration: const InputDecoration(labelText: 'ડિલિવરી લાઇન'),
                        items: db.routes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                        onChanged: (v) => setState(() => _routeId = v ?? _routeId),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _mobileCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'મોબાઈલ નંબર'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                const SizedBox(height: 16),

                // Subscribed Papers
                const Text('📰 ચાલુ પેપર્સ (સબ્સ્ક્રિપ્શન):', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: db.items.map((item) {
                    final isSelected = _selectedItemIds.contains(item.id);
                    return FilterChip(
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.25),
                      checkmarkColor: AppColors.primaryLight,
                      label: Text(item.name, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondaryDark)),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedItemIds.add(item.id);
                          } else {
                            _selectedItemIds.remove(item.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Billing Type & Balance
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _billingType,
                        dropdownColor: AppColors.bgCardDark,
                        decoration: const InputDecoration(labelText: 'બિલિંગ પ્રકાર'),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('દૈનિક ગણતરી (Daily)')),
                          DropdownMenuItem(value: 'fixed', child: Text('માસિક ફિક્સ કરાર')),
                        ],
                        onChanged: (v) => setState(() => _billingType = v ?? 'daily'),
                      ),
                    ),
                    if (_billingType == 'fixed') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _fixedAmtCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'ફિક્સ રકમ (₹/મહિને)'),
                        ),
                      ),
                    ],
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
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('રદ કરો')),
                    const SizedBox(width: 10),
                    ElevatedButton(onPressed: _save, child: const Text('સાચવો (Save)')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
