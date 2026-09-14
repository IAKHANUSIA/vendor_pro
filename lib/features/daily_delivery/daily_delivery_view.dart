import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/customer.dart';
import '../../core/models/item.dart';
import '../../core/models/salesman.dart';

class DailyDeliveryView extends StatefulWidget {
  const DailyDeliveryView({super.key});

  @override
  State<DailyDeliveryView> createState() => _DailyDeliveryViewState();
}

class _DailyDeliveryViewState extends State<DailyDeliveryView> {
  DateTime _selectedDate = DateTime.now();
  late int _selectedRouteId;
  final Set<int> _deliveredCustomerIds = {};

  final List<String> _dayNamesGu = [
    'રવિવાર', 'સોમવાર', 'મંગળવાર', 'બુધવાર', 'ગુરુવાર', 'શુક્રવાર', 'શનિવાર'
  ];

  @override
  void initState() {
    super.initState();
    final db = DatabaseService.instance;
    _selectedRouteId = db.routes.isNotEmpty ? db.routes.first.id : 1;
  }

  void _markAllDelivered(List<Customer> list) {
    setState(() {
      _deliveredCustomerIds.addAll(list.map((c) => c.id));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('આ લાઇનના બધા ગ્રાહકોને "પહોંચાડ્યા" માર્ક કરવામાં આવ્યા!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayOfWeek = _selectedDate.weekday % 7;
    final dayName = _dayNamesGu[dayOfWeek];

    final currentRoute = db.routes.cast<dynamic>().firstWhere((r) => r.id == _selectedRouteId, orElse: () => null);
    final currentSalesman = db.salesmen.cast<Salesman?>().firstWhere((s) => s?.id == currentRoute?.salesmanId, orElse: () => null);

    final lineCustomers = db.customers
        .where((c) => c.routeId == _selectedRouteId && c.status == 'active')
        .toList()
      ..sort((a, b) => (int.tryParse(a.sequenceNo) ?? 0).compareTo(int.tryParse(b.sequenceNo) ?? 0));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Line & Date Selector Row
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Route Selector
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _selectedRouteId,
                        dropdownColor: AppColors.bgCardDark,
                        decoration: const InputDecoration(isDense: true, labelText: 'ડિલિવરી લાઇન / રૂટ'),
                        items: db.routes.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.code} - ${r.name}'))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedRouteId = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Date Picker
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('dd/MM/yyyy').format(_selectedDate)} ($dayName)',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    ElevatedButton.icon(
                      onPressed: lineCustomers.isEmpty ? null : () => _markAllDelivered(lineCustomers),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('બધા પહોંચાડ્યા'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Hawker Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🚴‍♂️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'વિતરક: ${currentSalesman?.name ?? "કોઈ નહીં"} ${currentSalesman?.mobile.isNotEmpty == true ? "(📞 " + currentSalesman!.mobile + ")" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 13),
                      ),
                    ],
                  ),
                  Text(
                    'કુલ ગ્રાહકો: ${lineCustomers.length}',
                    style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Customers Delivery List
            Expanded(
              child: lineCustomers.isEmpty
                  ? Center(
                      child: Text(
                        'આ લાઇન પર કોઈ સક્રિય ગ્રાહક મળ્યા નથી',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: lineCustomers.length,
                      itemBuilder: (ctx, index) {
                        final c = lineCustomers[index];
                        final onVacation = db.vacations.any((v) => v.customerId == c.id && v.isActiveOn(dateStr));
                        final isDelivered = _deliveredCustomerIds.contains(c.id);

                        final todayPapers = c.subscriptionItemIds.where((id) {
                          return c.isSubscribedOnDay(id, dayOfWeek, dateStr);
                        }).map((id) {
                          return db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null)?.name;
                        }).where((n) => n != null).toList();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: onVacation ? AppColors.danger.withOpacity(0.06) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Sequence Number
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    c.sequenceNo,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Customer Details
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
                                            Text(
                                              '(${c.societyShort})',
                                              style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (onVacation)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.danger.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('🌴 રજા પર છે (Skipped)', style: TextStyle(color: AppColors.dangerLight, fontSize: 11, fontWeight: FontWeight.bold)),
                                        )
                                      else
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: todayPapers.isEmpty
                                              ? [const Text('આજે કોઈ પેપર નથી', style: TextStyle(fontSize: 11, color: AppColors.textMutedDark))]
                                              : todayPapers.map((p) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                                    ),
                                                    child: Text(p!, style: const TextStyle(fontSize: 11, color: AppColors.primaryLight)),
                                                  );
                                                }).toList(),
                                        ),
                                    ],
                                  ),
                                ),

                                // Status checkbox / button
                                InkWell(
                                  onTap: onVacation
                                      ? null
                                      : () {
                                          setState(() {
                                            if (isDelivered) {
                                              _deliveredCustomerIds.remove(c.id);
                                            } else {
                                              _deliveredCustomerIds.add(c.id);
                                            }
                                          });
                                        },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDelivered
                                          ? AppColors.success.withOpacity(0.18)
                                          : AppColors.bgSurfaceDark,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDelivered ? AppColors.success : AppColors.borderDark,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isDelivered ? Icons.check_circle : Icons.radio_button_unchecked,
                                          size: 16,
                                          color: isDelivered ? AppColors.successLight : AppColors.textSecondaryDark,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isDelivered ? 'પહોંચાડ્યું' : 'બાકી',
                                          style: TextStyle(
                                            color: isDelivered ? AppColors.successLight : AppColors.textSecondaryDark,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
