import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/printing/print_service.dart';

class DepotPurchaseView extends StatefulWidget {
  const DepotPurchaseView({super.key});

  @override
  State<DepotPurchaseView> createState() => _DepotPurchaseViewState();
}

class _DepotPurchaseViewState extends State<DepotPurchaseView> {
  DateTime _targetDate = DateTime.now().add(const Duration(days: 1));
  final Map<int, int> _customExtraCopies = {};

  final List<String> _dayNamesGu = [
    'રવિવાર', 'સોમવાર', 'મંગળવાર', 'બુધવાર', 'ગુરુવાર', 'શુક્રવાર', 'શનિવાર'
  ];

  void _onExtraCopiesChanged(int itemId, String val) {
    final count = int.tryParse(val) ?? 0;
    setState(() {
      _customExtraCopies[itemId] = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final dateStr = DateFormat('yyyy-MM-dd').format(_targetDate);
    final dayOfWeek = _targetDate.weekday % 7;
    final dayName = _dayNamesGu[dayOfWeek];

    final sheet = db.getDepotPurchaseSheet(dateStr, _customExtraCopies);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Date Selector & Info Row
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏬 આવતીકાલનું સેલ અને ડેપો ખરીદી હિસાબ',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ખરીદ ભાવ (PTR) મુજબ ડેપોને ચૂકવવાની રકમ અને નફાનો હિસાબ',
                            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _targetDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _targetDate = picked);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.warningLight),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('dd/MM/yyyy').format(_targetDate)} ($dayName)',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warningLight, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        PrintService.printDepotPurchaseSheetPdf(context, sheet, db.firm);
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('પ્રિન્ટ પત્રક'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                        side: const BorderSide(color: AppColors.primaryTeal),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Summary KPI Cards
            LayoutBuilder(
              builder: (ctx, constraints) {
                final count = constraints.maxWidth >= 1000 ? 5 : (constraints.maxWidth >= 600 ? 3 : 2);
                return GridView.count(
                  crossAxisCount: count,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _buildSummaryCard('કુલ ખરીદવાની નકલ', '${sheet.totalCopies} નકલ', AppColors.primaryLight),
                    _buildSummaryCard('ગ્રાહક માંગણી', '${sheet.totalCustomerCopies} નકલ', AppColors.textPrimaryDark),
                    _buildSummaryCard('કાઉન્ટર નકલ', '${sheet.totalExtraCopies} નકલ', AppColors.textSecondaryDark),
                    _buildSummaryCard('ડેપોને ચૂકવવાપાત્ર', '₹${sheet.totalPurchaseAmount.toStringAsFixed(2)}', AppColors.dangerLight),
                    _buildSummaryCard('અપેક્ષિત નફો/માર્જિન', '₹${sheet.totalProfit.toStringAsFixed(2)}', AppColors.successLight),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Item-wise Purchase Table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 પેપર મુજબ ખરીદી અને ચૂકવણી વિગત',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderDark),

                    // Table Headers
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('પેપરનું નામ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondaryDark))),
                          Expanded(flex: 1, child: Text('ગ્રાહક', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryLight))),
                          Expanded(flex: 2, child: Text('કાઉન્ટર', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondaryDark))),
                          Expanded(flex: 1, child: Text('કુલ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
                          Expanded(flex: 2, child: Text('ખરીદ ભાવ (PTR)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.dangerLight))),
                          Expanded(flex: 2, child: Text('કુલ રકમ (₹)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.dangerLight))),
                          Expanded(flex: 2, child: Text('વેચાણ (MRP)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryLight))),
                          Expanded(flex: 2, child: Text('નફો (₹)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.successLight))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Table Body
                    ...sheet.items.map((row) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('${row.name} (${row.code})', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('${row.customerCopies}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                            ),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 32,
                                child: TextFormField(
                                  initialValue: '${row.extraCopies}',
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                    isDense: true,
                                  ),
                                  onChanged: (v) => _onExtraCopiesChanged(row.id, v),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('${row.totalCopies}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('₹${row.purchaseRate.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.dangerLight, fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('₹${row.purchaseAmount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dangerLight, fontSize: 13)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('₹${row.saleRate.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('₹${row.profit.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successLight, fontSize: 13)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: AppColors.borderDark),

                    // Total Footer Row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 3,
                            child: Text('કુલ સરવાળો (TOTAL):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('${sheet.totalCustomerCopies}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight, fontSize: 14)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('${sheet.totalExtraCopies}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('${sheet.totalCopies}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                          ),
                          const Expanded(flex: 2, child: SizedBox()),
                          Expanded(
                            flex: 2,
                            child: Text('₹${sheet.totalPurchaseAmount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dangerLight, fontSize: 15)),
                          ),
                          const Expanded(flex: 2, child: SizedBox()),
                          Expanded(
                            flex: 2,
                            child: Text('₹${sheet.totalProfit.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successLight, fontSize: 15)),
                          ),
                        ],
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

  Widget _buildSummaryCard(String title, String value, Color valueColor) {
    return Card(
      color: AppColors.bgSurfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      ),
    );
  }
}
