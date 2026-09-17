import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/customer.dart';
import '../../core/models/item.dart';
import '../../core/models/route.dart';
import '../../core/models/salesman.dart';
import '../../core/models/collection_man.dart';

class RouteOrderDialog extends StatefulWidget {
  final int? initialRouteId;
  final VoidCallback onSaved;

  const RouteOrderDialog({
    super.key,
    this.initialRouteId,
    required this.onSaved,
  });

  @override
  State<RouteOrderDialog> createState() => _RouteOrderDialogState();
}

class _RouteOrderDialogState extends State<RouteOrderDialog> {
  late int _selectedRouteId;
  List<Customer> _orderedCustomers = [];
  bool _syncCollectionSeq = true;
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    final db = DatabaseService.instance;
    _selectedRouteId = widget.initialRouteId ?? (db.routes.isNotEmpty ? db.routes.first.id : 1);
    _loadCustomers();
  }

  void _loadCustomers() {
    final db = DatabaseService.instance;
    _orderedCustomers = db.customers
        .where((c) => c.routeId == _selectedRouteId)
        .toList()
      ..sort((a, b) => (int.tryParse(a.sequenceNo) ?? 0).compareTo(int.tryParse(b.sequenceNo) ?? 0));
  }

  void _moveItem(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final Customer item = _orderedCustomers.removeAt(oldIndex);
      _orderedCustomers.insert(newIndex, item);
    });
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _orderedCustomers.removeAt(index);
        _orderedCustomers.insert(index - 1, item);
      });
    }
  }

  void _moveDown(int index) {
    if (index < _orderedCustomers.length - 1) {
      setState(() {
        final item = _orderedCustomers.removeAt(index);
        _orderedCustomers.insert(index + 1, item);
      });
    }
  }

  void _save() {
    final db = DatabaseService.instance;
    final orderedIds = _orderedCustomers.map((c) => c.id).toList();
    db.updateRouteSequence(_selectedRouteId, orderedIds, syncCollectionSeq: _syncCollectionSeq);
    widget.onSaved();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('લાઇનનો નવો ક્રમ સફળતાપૂર્વક સાચવી લેવાયો છે! (${orderedIds.length} ગ્રાહકો) ✅'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final currentRoute = db.routes.cast<DeliveryRoute?>().firstWhere((r) => r?.id == _selectedRouteId, orElse: () => null);
    final salesman = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == currentRoute?.salesmanId, orElse: () => null);
    final collectionMan = db.collectionMen.cast<CollectionMan?>().firstWhere((cm) => cm?.id == currentRoute?.collectionManId, orElse: () => null);

    return Dialog(
      backgroundColor: const Color(0xFF161B26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 860,
        height: 720,
        padding: const EdgeInsets.all(20),
        child: Column(
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.swap_vert, color: AppColors.accentCyan, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔀 લાઇન ક્રમ ગોઠવો (Street Sequence Reorder)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                        ),
                        Text(
                          'ગ્રાહકોને પકડીને ઉપર-નીચે ખસેડો જેથી સવારની ડિલિવરી શીટ શેરી ક્રમ મુજબ ગોઠવાય.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
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

            // Route Selector & Staff info banner
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    value: _selectedRouteId,
                    dropdownColor: const Color(0xFF1E2433),
                    decoration: const InputDecoration(
                      labelText: 'ડિલિવરી લાઇન પસંદ કરો',
                      isDense: true,
                    ),
                    items: db.routes.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.code} - ${r.name}'))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedRouteId = v;
                          _loadCustomers();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Staff info badge
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2433),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A3447)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🚴 ', style: TextStyle(fontSize: 14)),
                            Text(
                              salesman?.name ?? 'વિતરક: -',
                              style: const TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('💼 ', style: TextStyle(fontSize: 14)),
                            Text(
                              collectionMan?.name ?? 'ઉઘરાણી: -',
                              style: const TextStyle(fontSize: 11, color: AppColors.purpleLight, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'કુલ: ${_orderedCustomers.length}',
                            style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reorderable list header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2433),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 32, child: Text('ખસેડો', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 50, child: Text('ક્રમ', textAlign: TextAlign.center, style: TextStyle(color: AppColors.accentCyan, fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 70, child: Text('કોડ', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('ગ્રાહક નામ અને સરનામું', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('પેપર્સ (સબસ્ક્રિપ્શન)', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 80, child: Text('એક્શન', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),

            // Reorderable List
            Expanded(
              child: _orderedCustomers.isEmpty
                  ? Center(
                      child: Text(
                        'આ લાઇનમાં કોઈ ગ્રાહક નથી.',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: _orderedCustomers.length,
                      onReorder: _moveItem,
                      itemBuilder: (ctx, index) {
                        final c = _orderedCustomers[index];
                        final subPapers = c.subscriptionItemIds
                            .map((id) => db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null)?.code)
                            .where((n) => n != null)
                            .toList();

                        return Container(
                          key: ValueKey(c.id),
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: index.isEven ? const Color(0xFF161B26) : const Color(0xFF1A212E),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF242C3D)),
                          ),
                          child: Row(
                            children: [
                              // Drag Handle
                              const SizedBox(
                                width: 32,
                                child: Icon(Icons.drag_indicator, color: Color(0xFF5A6E8C), size: 20),
                              ),

                              // Sequence Number Badge
                              SizedBox(
                                width: 50,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentCyan.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Code
                              SizedBox(
                                width: 70,
                                child: Text(
                                  c.code.isNotEmpty ? c.code : '#${c.custNo}',
                                  style: const TextStyle(color: Color(0xFF8B9CB5), fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ),

                              // Name & Address
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (c.societyShort.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              c.societyShort,
                                              style: const TextStyle(fontSize: 10, color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Expanded(
                                          child: Text(
                                            c.name,
                                            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (c.address.isNotEmpty)
                                      Text(
                                        c.address,
                                        style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),

                              // Subscribed Papers
                              Expanded(
                                flex: 2,
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: subPapers.map((p) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(p!, style: const TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                ),
                              ),

                              // Move Up & Down Buttons
                              SizedBox(
                                width: 80,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_upward, size: 16),
                                      color: index > 0 ? AppColors.accentCyan : Colors.grey[700],
                                      onPressed: index > 0 ? () => _moveUp(index) : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      tooltip: 'ઉપર ખસેડો',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_downward, size: 16),
                                      color: index < _orderedCustomers.length - 1 ? AppColors.accentCyan : Colors.grey[700],
                                      onPressed: index < _orderedCustomers.length - 1 ? () => _moveDown(index) : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      tooltip: 'નીચે ખસેડો',
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
            const SizedBox(height: 12),

            // Bottom bar with Sync Collection Checkbox and Save button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _syncCollectionSeq,
                      activeColor: AppColors.accentCyan,
                      onChanged: (v) => setState(() => _syncCollectionSeq = v ?? true),
                    ),
                    const Text(
                      'ઉઘરાણી ક્રમ પણ આ મુજબ જ ગોઠવો (Sync Collection Sequence)',
                      style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        side: const BorderSide(color: Color(0xFF3B4861)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('રદ કરો', style: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: _orderedCustomers.isEmpty ? null : _save,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text(
                        'નવો ક્રમ સાચવો (Save Order)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
