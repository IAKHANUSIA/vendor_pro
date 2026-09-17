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
  String _seqMode = 'delivery'; // 'delivery' or 'collection'
  List<Customer> _orderedCustomers = [];
  bool _syncBothSequences = true;

  @override
  void initState() {
    super.initState();
    final db = DatabaseService.instance;
    _selectedRouteId = widget.initialRouteId ?? (db.routes.isNotEmpty ? db.routes.first.id : 1);
    _loadCustomers();
  }

  void _loadCustomers() {
    final db = DatabaseService.instance;
    _orderedCustomers = db.customers.where((c) => c.routeId == _selectedRouteId).toList();
    if (_seqMode == 'delivery') {
      _orderedCustomers.sort((a, b) => (int.tryParse(a.sequenceNo) ?? 0).compareTo(int.tryParse(b.sequenceNo) ?? 0));
    } else {
      _orderedCustomers.sort((a, b) => a.collectionSequence.compareTo(b.collectionSequence));
    }
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

  void _copyDeliveryToCollection() {
    final db = DatabaseService.instance;
    final orderedIds = _orderedCustomers.map((c) => c.id).toList();
    db.updateCollectionSequence(_selectedRouteId, orderedIds, syncDeliverySeq: false);
    setState(() {
      _loadCustomers();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ઉઘરાણી ક્રમ = ડિલિવરી ક્રમ સેટ થઈ ગયો!')),
    );
  }

  void _copyCollectionToDelivery() {
    final db = DatabaseService.instance;
    final orderedIds = _orderedCustomers.map((c) => c.id).toList();
    db.updateRouteSequence(_selectedRouteId, orderedIds, syncCollectionSeq: false);
    setState(() {
      _loadCustomers();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ડિલિવરી ક્રમ = ઉઘરાણી ક્રમ સેટ થઈ ગયો!')),
    );
  }

  void _save() {
    final db = DatabaseService.instance;
    final orderedIds = _orderedCustomers.map((c) => c.id).toList();

    if (_seqMode == 'delivery') {
      db.updateRouteSequence(_selectedRouteId, orderedIds, syncCollectionSeq: _syncBothSequences);
    } else {
      db.updateCollectionSequence(_selectedRouteId, orderedIds, syncDeliverySeq: _syncBothSequences);
    }

    widget.onSaved();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('લાઇનનો નવો ક્રમ સફળતાપૂર્વક સાચવી લેવાયો છે! (${orderedIds.length} ગ્રાહકો) ✅'),
        backgroundColor: AppColors.successGreen,
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
      backgroundColor: const Color(0xFF161E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 880,
        height: 720,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header matching Image 3
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.shuffle, color: Color(0xFF42A5F5), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'લાઇન વિતરણ અને ઉઘરાણી ક્રમ ગોઠવો (Sequence Organizer)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'વિતરણ ક્રમ અને ઉઘરાણી ક્રમ અલગ-અલગ સેટ કરો અથવા બંને સરખા રાખો',
                      style: TextStyle(fontSize: 12, color: Color(0xFF90A4AE)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Top Mode Switcher Tabs matching Image 3
            Row(
              children: [
                // Delivery Seq Tab
                InkWell(
                  onTap: () {
                    setState(() {
                      _seqMode = 'delivery';
                      _loadCustomers();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _seqMode == 'delivery' ? const Color(0xFF00838F) : const Color(0xFF141A28),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _seqMode == 'delivery' ? const Color(0xFF00ACC1) : const Color(0xFF2A364F),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.pedal_bike, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '૧. વિતરક / ડિલિવરી ક્રમ (Delivery Seq)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Collection Seq Tab
                InkWell(
                  onTap: () {
                    setState(() {
                      _seqMode = 'collection';
                      _loadCustomers();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _seqMode == 'collection' ? const Color(0xFFE65100) : const Color(0xFF141A28),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _seqMode == 'collection' ? const Color(0xFFFF9800) : const Color(0xFF2A364F),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.work_outline, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '૨. ઉઘરાણી ક્રમ (Collection Seq)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Sync Buttons Row matching Image 3
            Row(
              children: [
                InkWell(
                  onTap: _copyDeliveryToCollection,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E283C),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2D3B55)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.copy, size: 13, color: Color(0xFFFFCA28)),
                        SizedBox(width: 6),
                        Text('ઉઘરાણી ક્રમ = ડિલિવરી ક્રમ કરો', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _copyCollectionToDelivery,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E283C),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2D3B55)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.copy, size: 13, color: Color(0xFF4FC3F7)),
                        SizedBox(width: 6),
                        Text('ડિલિવરી ક્રમ = ઉઘરાણી ક્રમ કરો', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Line Selector & Staff info row matching Image 3
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111722),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF222D3F)),
              ),
              child: Row(
                children: [
                  const Text('ડિલિવરી લાઇન:  ', style: TextStyle(color: Color(0xFF42A5F5), fontWeight: FontWeight.bold, fontSize: 13)),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedRouteId,
                        dropdownColor: const Color(0xFF1A2336),
                        isDense: true,
                        items: db.routes.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.code} - ${r.name}', style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
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
                  ),
                  const SizedBox(width: 12),
                  // Staff Badges
                  Row(
                    children: [
                      const Icon(Icons.pedal_bike, size: 14, color: Color(0xFFFFA726)),
                      const SizedBox(width: 4),
                      Text('વિતરક: ${salesman?.name ?? "-"}', style: const TextStyle(color: Color(0xFFFFA726), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      const Icon(Icons.work_outline, size: 14, color: Color(0xFFBA68C8)),
                      const SizedBox(width: 4),
                      Text('ઉઘરાણી સ્ટાફ: ${collectionMan?.name ?? "-"}', style: const TextStyle(color: Color(0xFFBA68C8), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  // Both sequences sync checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _syncBothSequences,
                          activeColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _syncBothSequences = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('બંને ક્રમ એકસરખા સાચવવા', style: TextStyle(color: Color(0xFFCFD8DC), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reorder Table Header matching Image 3
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1A2336),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              ),
              child: Row(
                children: const [
                  SizedBox(width: 40, child: Text('ખસેડો', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 50, child: Text('નવો ક્રમ', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF42A5F5), fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 80, child: Text('ગ્રાહક નં.', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 4, child: Text('ગ્રાહકનું નામ અને સોસાયટી / સરનામું', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('પેપર્સ', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11, fontWeight: FontWeight.bold))),
                  SizedBox(width: 90, child: Text('બટનથી ખસેડો', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11, fontWeight: FontWeight.bold))),
                ],
              ),
            ),

            // Reorderable List matching Image 3
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111722),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                  border: Border.all(color: const Color(0xFF222D3F)),
                ),
                child: _orderedCustomers.isEmpty
                    ? const Center(child: Text('આ લાઇનમાં કોઈ ગ્રાહક નથી.', style: TextStyle(color: Color(0xFF78909C))))
                    : Scrollbar(
                        thumbVisibility: true,
                        child: ReorderableListView.builder(
                          itemCount: _orderedCustomers.length,
                          onReorder: _moveItem,
                          itemBuilder: (context, index) {
                            final c = _orderedCustomers[index];
                            final subPapers = c.subscriptionItemIds
                                .map((id) => db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null)?.name)
                                .where((n) => n != null)
                                .toList();

                            return Container(
                              key: ValueKey(c.id),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: index.isEven ? Colors.transparent : const Color(0xFF161E2E).withOpacity(0.5),
                                border: const Border(bottom: BorderSide(color: Color(0xFF1E283C), width: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  // Drag Handle
                                  const SizedBox(
                                    width: 40,
                                    child: Icon(Icons.drag_indicator, color: Color(0xFF546E7A), size: 18),
                                  ),
                                  // New Sequence Number
                                  SizedBox(
                                    width: 50,
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF42A5F5)),
                                      ),
                                    ),
                                  ),
                                  // Customer Number
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      '#${c.custNo.isNotEmpty ? c.custNo : c.code}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF29B6F6),
                                      ),
                                    ),
                                  ),
                                  // Name and Address
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                        ),
                                        Text(
                                          c.address.isNotEmpty ? c.address : (c.societyShort.isNotEmpty ? c.societyShort : 'સરનામું નથી'),
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Papers
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      subPapers.isNotEmpty ? subPapers.join(', ') : '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFFB74D),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Up / Down Buttons matching Image 3
                                  SizedBox(
                                    width: 90,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: index > 0 ? () => _moveUp(index) : null,
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: index > 0 ? const Color(0xFF1E2D44) : const Color(0xFF151C2A),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFF2A3B57)),
                                            ),
                                            child: Icon(Icons.arrow_upward, size: 14, color: index > 0 ? const Color(0xFF64B5F6) : Colors.white24),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: index < _orderedCustomers.length - 1 ? () => _moveDown(index) : null,
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: index < _orderedCustomers.length - 1 ? const Color(0xFF1E2D44) : const Color(0xFF151C2A),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFF2A3B57)),
                                            ),
                                            child: Icon(Icons.arrow_downward, size: 14, color: index < _orderedCustomers.length - 1 ? const Color(0xFF64B5F6) : Colors.white24),
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
              ),
            ),
            const SizedBox(height: 14),

            // Footer Actions matching Image 3
            Row(
              children: [
                Text(
                  'કુલ: ${_orderedCustomers.length} ગ્રાહકો (આ લાઇનમાં)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFFB74D)),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF263238),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('રદ કરો', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _save,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('નવો ક્રમ સાચવો (Save Sequence)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
