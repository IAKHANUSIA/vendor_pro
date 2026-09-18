import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/item.dart';
import '../broadcast/broadcast_notice_dialog.dart';

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
        backgroundColor: const Color(0xFF1E2638),
        title: const Text('પેપર હટાવો?', style: TextStyle(color: Colors.white)),
        content: Text('શું તમે ખરેખર "${item.name}" હટાવવા માંગો છો?', style: const TextStyle(color: Color(0xFFB0BEC5))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('રદ કરો', style: TextStyle(color: Colors.white70)),
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
            child: const Text('હટાવો', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRateHistoryModal(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2638),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.history_toggle_off, color: Color(0xFF42A5F5)),
              const SizedBox(width: 10),
              Text('${item.name} - ભાવ સુધારા ઇતિહાસ', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: item.rateHistory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('કોઈ ભાવ સુધારો નોંધાયેલ નથી.', style: TextStyle(color: Color(0xFF90A4AE))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: item.rateHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final rev = item.rateHistory[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141A28),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_available, color: Color(0xFF64B5F6), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'લાગુ તારીખ: ${rev.effectiveDate} થી',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 16),
                                  splashRadius: 14,
                                  onPressed: () {
                                    setState(() {
                                      item.rateHistory.removeAt(idx);
                                    });
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFF222F46), height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'].map((d) {
                                final dr = rev.dayRates[d];
                                final dayNames = {'mon': 'સોમ', 'tue': 'મંગળ', 'wed': 'બુધ', 'thu': 'ગુરુ', 'fri': 'શુક્ર', 'sat': 'શનિ', 'sun': 'રવિ'};
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: d == 'sun' ? const Color(0xFF381E24) : const Color(0xFF1E283C),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${dayNames[d]}: ₹${dr?.sale ?? 0} (${dr?.purchase ?? 0})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: d == 'sun' ? const Color(0xFFEF5350) : const Color(0xFFB0BEC5),
                                      fontWeight: d == 'sun' ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('બંધ કરો', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRateSummary(Item item) {
    final mon = item.getRateForDay(1);
    final tue = item.getRateForDay(2);
    final wed = item.getRateForDay(3);
    final thu = item.getRateForDay(4);
    final fri = item.getRateForDay(5);
    final sat = item.getRateForDay(6);
    final sun = item.getRateForDay(0);

    return 'સોમ: ${mon.sale.toStringAsFixed(mon.sale.truncateToDouble() == mon.sale ? 0 : 2)} (${mon.purchase.toStringAsFixed(2)}) | '
        'મંગળ: ${tue.sale.toStringAsFixed(tue.sale.truncateToDouble() == tue.sale ? 0 : 2)} (${tue.purchase.toStringAsFixed(2)}) | '
        'બુધ: ${wed.sale.toStringAsFixed(wed.sale.truncateToDouble() == wed.sale ? 0 : 2)} (${wed.purchase.toStringAsFixed(2)}) | '
        'ગુરુ: ${thu.sale.toStringAsFixed(thu.sale.truncateToDouble() == thu.sale ? 0 : 2)} (${thu.purchase.toStringAsFixed(2)})\n'
        'શુક્ર: ${fri.sale.toStringAsFixed(fri.sale.truncateToDouble() == fri.sale ? 0 : 2)} (${fri.purchase.toStringAsFixed(2)}) | '
        'શનિ: ${sat.sale.toStringAsFixed(sat.sale.truncateToDouble() == sat.sale ? 0 : 2)} (${sat.purchase.toStringAsFixed(2)}) | '
        'રવિ: ${sun.sale.toStringAsFixed(sun.sale.truncateToDouble() == sun.sale ? 0 : 2)} (${sun.purchase.toStringAsFixed(2)})';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar matching Image 3
            Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.accentCyan, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'વસ્તુ માસ્ટર (પેપર્સ અને સામયિકો)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => BroadcastNoticeDialog.show(context),
                  icon: const Icon(Icons.campaign, size: 18),
                  label: const Text('📢 ભાવ વધારો / નોટિસ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentGold,
                    side: const BorderSide(color: AppColors.accentGold),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openItemDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('નવું પેપર ઉમેરો', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryDark, size: 18),
                  hintText: 'પેપર શોધો (નામ, કોડ)...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFF141A28),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A364F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A364F)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Table Container matching Image 3
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF222F46)),
                ),
                clipBehavior: Clip.antiAlias,
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'કોઈ પેપર મળ્યા નથી',
                          style: TextStyle(color: Color(0xFF78909C), fontSize: 16),
                        ),
                      )
                    : Column(
                        children: [
                          // Table Header
                          Container(
                            color: const Color(0xFF172033),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: const [
                                SizedBox(width: 80, child: Text('કોડ', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 3, child: Text('પેપર / વસ્તુનું નામ', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 13))),
                                SizedBox(width: 70, child: Text('પ્રકાર', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(flex: 6, child: Text('સાપ્તાહિક ભાવ (MRP / PTR)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 13))),
                                SizedBox(width: 120, child: Text('ફિક્સ માસિક ભાવ (₹)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 13))),
                                SizedBox(width: 80, child: Text('સ્થિતિ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 13))),
                                SizedBox(width: 80, child: Text('ક્રિયાઓ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 13))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFF222F46)),

                          // Table Body
                          Expanded(
                            child: ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1E283C)),
                              itemBuilder: (ctx, index) {
                                final item = items[index];

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  color: index.isEven ? Colors.transparent : const Color(0xFF161E2E).withOpacity(0.5),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Code Badge
                                      SizedBox(
                                        width: 80,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF102A45),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.4)),
                                            ),
                                            child: Text(
                                              item.code,
                                              style: const TextStyle(
                                                color: Color(0xFF64B5F6),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Name & Rate Revision Badge matching Image 1
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (item.rateHistory.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              InkWell(
                                                onTap: () => _showRateHistoryModal(context, item),
                                                borderRadius: BorderRadius.circular(4),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF1E88E5),
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                      child: const Icon(Icons.sync_alt, size: 10, color: Colors.white),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      '${item.rateHistory.length} ભાવ સુધારા (${item.rateHistory.last.effectiveDate} થી)',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF64B5F6),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Type
                                      SizedBox(
                                        width: 70,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF332A15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.4)),
                                            ),
                                            child: Text(
                                              item.type,
                                              style: const TextStyle(
                                                color: Color(0xFFFFD54F),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Weekly Rates (MRP / PTR)
                                      Expanded(
                                        flex: 6,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'વેચાણ (ખરીદ)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF90A4AE),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatRateSummary(item),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFCFD8DC),
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Fixed Monthly Rate
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          '₹${item.monthlyRate.toStringAsFixed(0)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),

                                      // Status
                                      SizedBox(
                                        width: 80,
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (item.isActive ? const Color(0xFF1B3830) : const Color(0xFF381E24)),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: item.isActive ? const Color(0xFF4CAF50).withOpacity(0.5) : const Color(0xFFEF5350).withOpacity(0.5),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  size: 8,
                                                  color: item.isActive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item.isActive ? 'ચાલુ' : 'બંધ',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: item.isActive ? const Color(0xFF81C784) : const Color(0xFFE57373),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Actions
                                      SizedBox(
                                        width: 80,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Color(0xFFFFA726), size: 18),
                                              splashRadius: 16,
                                              onPressed: () => _openItemDialog(item),
                                              tooltip: 'સુધારો (Edit)',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF5350), size: 18),
                                              splashRadius: 16,
                                              onPressed: () => _deleteItem(item),
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
// Add / Edit Paper Dialog matching Image 2
// -------------------------------------------------------------
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
  String _itemType = 'daily';
  String _itemStatus = 'active';

  DateTime? _rateRevisionDate;

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
    _itemType = it?.type ?? 'daily';
    _itemStatus = it?.status ?? 'active';

    for (final d in _days) {
      final dr = it?.dayRates[d];
      _saleCtrls[d] = TextEditingController(text: dr != null ? dr.sale.toString() : (d == 'sun' ? '6' : '5'));
      _purCtrls[d] = TextEditingController(text: dr != null ? dr.purchase.toString() : (d == 'sun' ? '3.99' : '3.32'));
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _monthlyRateCtrl.dispose();
    for (final c in _saleCtrls.values) {
      c.dispose();
    }
    for (final c in _purCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _copyMondayToAll() {
    final monSale = _saleCtrls['mon']?.text ?? '5';
    final monPur = _purCtrls['mon']?.text ?? '3.32';
    for (final d in ['tue', 'wed', 'thu', 'fri', 'sat']) {
      _saleCtrls[d]?.text = monSale;
      _purCtrls[d]?.text = monPur;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('સોમવારના ભાવ બધા દિવસ કોપી થઈ ગયા!')),
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

    List<RateRevision> history = widget.item?.rateHistory != null ? List.from(widget.item!.rateHistory) : [];

    if (_rateRevisionDate != null) {
      history.add(RateRevision(
        effectiveDate: DateFormat('yyyy-MM-dd').format(_rateRevisionDate!),
        dayRates: dayRates,
        defaultRate: dayRates['mon']?.sale ?? 5.0,
        sundayRate: dayRates['sun']?.sale ?? 6.0,
        monthlyRate: double.tryParse(_monthlyRateCtrl.text) ?? 0.0,
      ));
    }

    final newItem = Item(
      id: id,
      code: _codeCtrl.text.trim().toUpperCase(),
      name: _nameCtrl.text.trim(),
      type: _itemType,
      monthlyRate: double.tryParse(_monthlyRateCtrl.text) ?? 0.0,
      defaultRate: dayRates['mon']?.sale ?? 5.0,
      sundayRate: dayRates['sun']?.sale ?? 6.0,
      status: _itemStatus,
      dayRates: dayRates,
      rateHistory: history,
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

  Widget _buildRateField(TextEditingController ctrl, {bool isRed = false}) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF141A28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isRed ? const Color(0xFFD32F2F).withOpacity(0.7) : const Color(0xFF2D3B55),
        ),
      ),
      child: Center(
        child: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 650;

    return Dialog(
      backgroundColor: const Color(0xFF1E2638),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.item == null ? 'નવું પેપર ઉમેરો' : 'પેપરમાં ફેરફાર',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Top Fields: Code, Name, Type
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('કોડ', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _codeCtrl,
                            decoration: InputDecoration(
                              hintText: 'GS, SAN, DB...',
                              filled: true,
                              fillColor: const Color(0xFF141A28),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                            ),
                            validator: (v) => v?.trim().isEmpty == true ? 'કોડ લખો' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Paper Name
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('પેપર / વસ્તુનું નામ', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'ગુજરાત સમાચાર',
                              filled: true,
                              fillColor: const Color(0xFF141A28),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                            ),
                            validator: (v) => v?.trim().isEmpty == true ? 'નામ લખો' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Type
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('પ્રકાર', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _itemType,
                            dropdownColor: const Color(0xFF1A2336),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF141A28),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'daily', child: Text('રોજિંદુ દૈનિક પેપર', style: TextStyle(fontSize: 13, color: Colors.white))),
                              DropdownMenuItem(value: 'weekly', child: Text('સાપ્તાહિક (Weekly)', style: TextStyle(fontSize: 13, color: Colors.white))),
                              DropdownMenuItem(value: 'monthly', child: Text('માસિક (Monthly)', style: TextStyle(fontSize: 13, color: Colors.white))),
                              DropdownMenuItem(value: 'other', child: Text('અન્ય / સામયિક', style: TextStyle(fontSize: 13, color: Colors.white))),
                            ],
                            onChanged: (v) => setState(() => _itemType = v ?? 'daily'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 2: Monthly Fixed Rate & Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly Fixed Bill
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('માસિક ફિક્સ બિલ (₹)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _monthlyRateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF141A28),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Status Dropdown
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('સ્થિતિ (Status)', style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _itemStatus,
                            dropdownColor: const Color(0xFF1A2336),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF141A28),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2A364F))),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Row(
                                  children: [
                                    Icon(Icons.circle, color: Color(0xFF4CAF50), size: 12),
                                    SizedBox(width: 8),
                                    Text('સક્રિય (Active)', style: TextStyle(fontSize: 13, color: Colors.white)),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'inactive',
                                child: Row(
                                  children: [
                                    Icon(Icons.circle, color: Color(0xFFEF5350), size: 12),
                                    SizedBox(width: 8),
                                    Text('બંધ (Inactive)', style: TextStyle(fontSize: 13, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _itemStatus = v ?? 'active'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Spacer(flex: 3),
                  ],
                ),
                const SizedBox(height: 20),

                // Rate Matrix Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.calendar_month, color: Color(0xFFFFA726), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'સોમ થી રવિવાર સુધીના વેચાણ ભાવ (MRP) અને ખરીદ ભાવ (PTR)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF42A5F5), fontSize: 13),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _copyMondayToAll,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2D44),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.4)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.content_copy, color: Colors.white70, size: 14),
                            SizedBox(width: 6),
                            Text('સોમવારનો ભાવ બધા દિવસ કોપી કરો', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2-Column or Stacked 7-Day Matrix matching Image 2
                Builder(
                  builder: (context) {
                    final leftCol = Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A28),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF222F46)),
                      ),
                      child: Column(
                        children: [
                          // Header Row
                          Row(
                            children: const [
                              Expanded(flex: 4, child: Text('વાર (DAY)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(flex: 3, child: Center(child: Text('વેચાણ (₹)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12)))),
                              SizedBox(width: 8),
                              Expanded(flex: 3, child: Center(child: Text('ખરીદ (₹)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12)))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...['mon', 'tue', 'wed', 'thu'].map((d) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      _dayLabels[d]!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildRateField(_saleCtrls[d]!),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: _buildRateField(_purCtrls[d]!),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );

                    final rightCol = Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141A28),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF222F46)),
                      ),
                      child: Column(
                        children: [
                          // Header Row
                          Row(
                            children: const [
                              Expanded(flex: 4, child: Text('વાર (DAY)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(flex: 3, child: Center(child: Text('વેચાણ (₹)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12)))),
                              SizedBox(width: 8),
                              Expanded(flex: 3, child: Center(child: Text('ખરીદ (₹)', style: TextStyle(color: Color(0xFF90A4AE), fontWeight: FontWeight.bold, fontSize: 12)))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...['fri', 'sat'].map((d) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      _dayLabels[d]!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: _buildRateField(_saleCtrls[d]!),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: _buildRateField(_purCtrls[d]!),
                                  ),
                                ],
                              ),
                            );
                          }),
                          // Sunday Row (Highlighted in Red)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    _dayLabels['sun']!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350), fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: _buildRateField(_saleCtrls['sun']!, isRed: true),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _buildRateField(_purCtrls['sun']!, isRed: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Sunday note
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lightbulb_outline, color: Color(0xFFFFCA28), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'રવિવાર વિશેષ પૂર્તિ / સ્પેશિયલ ભાવ',
                                style: TextStyle(fontSize: 11, color: Color(0xFFFFCA28), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    if (isNarrow) {
                      return Column(
                        children: [
                          leftCol,
                          const SizedBox(height: 12),
                          rightCol,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: leftCol),
                        const SizedBox(width: 14),
                        Expanded(child: rightCol),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Rate Revision Bottom Box matching Image 2
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141F32),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E88E5).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.event_note, color: Color(0xFF42A5F5), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'મહિનાની વચ્ચેથી ભાવફેરફાર (Rate Revision)?',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF42A5F5), fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'જો મહિનાની અધવચ્ચેથી ભાવ બદલાયો હોય તો લાગુ તારીખ પસંદ કરો (જૂના દિવસો જૂના ભાવે અને નવા દિવસો નવા ભાવે આપોઆપ ગણાશે).',
                        style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('લાગુ તારીખ:  ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                          InkWell(
                            onTap: () async {
                              final p = await showDatePicker(
                                context: context,
                                initialDate: _rateRevisionDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (p != null) setState(() => _rateRevisionDate = p);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101726),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF2A3B57)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _rateRevisionDate != null ? DateFormat('dd/MM/yyyy').format(_rateRevisionDate!) : 'dd/mm/yyyy',
                                    style: TextStyle(
                                      color: _rateRevisionDate != null ? Colors.white : const Color(0xFF78909C),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.calendar_month, color: Color(0xFF78909C), size: 16),
                                ],
                              ),
                            ),
                          ),
                          if (_rateRevisionDate != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Colors.white54),
                              onPressed: () => setState(() => _rateRevisionDate = null),
                              tooltip: 'તારીખ રદ કરો',
                              splashRadius: 14,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF263238),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('રદ કરો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _save,
                      child: const Text('પેપર સાચવો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
