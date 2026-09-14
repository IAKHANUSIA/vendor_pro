import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/item.dart';

class ItemsView extends StatefulWidget {
  const ItemsView({super.key});

  @override
  State<ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<ItemsView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Item> get _filteredItems {
    final db = DatabaseService.instance;
    if (_searchQuery.trim().isEmpty) return db.items;
    final q = _searchQuery.toLowerCase();
    return db.items.where((i) => i.name.toLowerCase().contains(q) || i.code.toLowerCase().contains(q)).toList();
  }

  void _openItemDialog([Item? item]) {
    showDialog(
      context: context,
      builder: (ctx) => _ItemFormDialog(
        item: item,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _deleteItem(Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('પેપર હટાવો?'),
        content: Text('શું તમે ખરેખર "${item.name}" હટાવવા માંગો છો?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('રદ કરો'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              DatabaseService.instance.items.removeWhere((i) => i.id == item.id);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('પેપર "${item.name}" હટાવી દેવામાં આવ્યું.')),
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
    final t = AppLocalizations.of(context);
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryDark),
                      hintText: t.translate('search'),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openItemDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.translate('add')),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'કોઈ પેપર મળ્યા નથી',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (ctx, index) {
                        final item = items[index];
                        final monRate = item.getRateForDay(1);
                        final sunRate = item.getRateForDay(0);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    item.code,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          Text(
                                            'સોમ-શનિ: MRP ₹${monRate.sale} | PTR ₹${monRate.purchase}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                                          ),
                                          Text(
                                            'રવિવાર: MRP ₹${sunRate.sale} | PTR ₹${sunRate.purchase}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.warningLight),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.primaryLight, size: 20),
                                  onPressed: () => _openItemDialog(item),
                                  tooltip: t.translate('edit'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.dangerLight, size: 20),
                                  onPressed: () => _deleteItem(item),
                                  tooltip: t.translate('delete'),
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

class _ItemFormDialog extends StatefulWidget {
  final Item? item;
  final VoidCallback onSaved;

  const _ItemFormDialog({this.item, required this.onSaved});

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _monthlyRateCtrl;

  final Map<String, TextEditingController> _saleCtrls = {};
  final Map<String, TextEditingController> _purCtrls = {};

  final _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  final _dayLabels = {
    'mon': 'સોમવાર (Mon)',
    'tue': 'મંગળવાર (Tue)',
    'wed': 'બુધવાર (Wed)',
    'thu': 'ગુરુવાર (Thu)',
    'fri': 'શુક્રવાર (Fri)',
    'sat': 'શનિવાર (Sat)',
    'sun': 'રવિવાર (Sun)',
  };

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _codeCtrl = TextEditingController(text: it?.code ?? '');
    _nameCtrl = TextEditingController(text: it?.name ?? '');
    _monthlyRateCtrl = TextEditingController(text: it?.monthlyRate.toString() ?? '0');

    for (final d in _days) {
      final dr = it?.dayRates[d];
      _saleCtrls[d] = TextEditingController(text: dr?.sale.toString() ?? (d == 'sun' ? '6.0' : '5.0'));
      _purCtrls[d] = TextEditingController(text: dr?.purchase.toString() ?? (d == 'sun' ? '3.99' : '3.32'));
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _monthlyRateCtrl.dispose();
    for (final c in _saleCtrls.values) c.dispose();
    for (final c in _purCtrls.values) c.dispose();
    super.dispose();
  }

  void _copyMondayToAll() {
    final monSale = _saleCtrls['mon']?.text ?? '5.0';
    final monPur = _purCtrls['mon']?.text ?? '3.32';
    for (final d in ['tue', 'wed', 'thu', 'fri', 'sat']) {
      _saleCtrls[d]?.text = monSale;
      _purCtrls[d]?.text = monPur;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('સોમવારના ભાવ શનિવાર સુધી કોપી થઈ ગયા!')),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final dayRates = <String, DayRate>{};
    for (final d in _days) {
      dayRates[d] = DayRate(
        sale: double.tryParse(_saleCtrls[d]?.text ?? '5.0') ?? 5.0,
        purchase: double.tryParse(_purCtrls[d]?.text ?? '3.32') ?? 3.32,
      );
    }

    final db = DatabaseService.instance;
    final id = widget.item?.id ?? (db.items.isEmpty ? 1 : db.items.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);

    final newItem = Item(
      id: id,
      code: _codeCtrl.text.trim().toUpperCase(),
      name: _nameCtrl.text.trim(),
      monthlyRate: double.tryParse(_monthlyRateCtrl.text) ?? 0.0,
      defaultRate: dayRates['mon']?.sale ?? 5.0,
      sundayRate: dayRates['sun']?.sale ?? 6.0,
      dayRates: dayRates,
    );

    if (widget.item == null) {
      db.items.add(newItem);
    } else {
      final idx = db.items.indexWhere((i) => i.id == widget.item!.id);
      if (idx != -1) db.items[idx] = newItem;
    }

    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.item == null ? '➕ નવું પેપર ઉમેરો' : '✏️ પેપરમાં ફેરફાર',
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
                        controller: _codeCtrl,
                        decoration: const InputDecoration(labelText: 'પેપર કોડ (દા.ત. GS)'),
                        validator: (v) => v?.trim().isEmpty == true ? 'કોડ લખો' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'પેપરનું નામ (દા.ત. ગુજરાત સમાચાર)'),
                        validator: (v) => v?.trim().isEmpty == true ? 'નામ લખો' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Day-wise rates section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📅 સોમ થી રવિ વેચાણ (MRP) અને ખરીદ ભાવ (PTR)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 13),
                    ),
                    TextButton.icon(
                      onPressed: _copyMondayToAll,
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('સોમવારનો ભાવ કોપી કરો', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    children: _days.map((d) {
                      final isSun = d == 'sun';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                _dayLabels[d]!,
                                style: TextStyle(
                                  fontWeight: isSun ? FontWeight.bold : FontWeight.w500,
                                  color: isSun ? AppColors.dangerLight : Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _saleCtrls[d],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixText: '₹',
                                  labelText: 'વેચાણ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _purCtrls[d],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixText: '₹',
                                  labelText: 'ખરીદ (PTR)',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('રદ કરો'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('સાચવો (Save)'),
                    ),
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
