import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/localization/app_localizations.dart';

class DashboardView extends StatefulWidget {
  final Function(int) onNavigate;

  const DashboardView({super.key, required this.onNavigate});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final String _todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final t = AppLocalizations.of(context);
    final todaySheet = db.getDepotPurchaseSheet(_todayStr);

    final activeCustCount = db.customers.where((c) => c.status == 'active').length;
    final activeVacationsCount = db.vacations.where((v) => v.isActiveOn(_todayStr)).length;
    final totalOutstanding = db.customers.fold(0.0, (sum, c) => sum + c.currentBalance);
    final totalCollected = db.payments.fold(0.0, (sum, p) => sum + p.amount);
    final totalBilled = db.bills.fold(0.0, (sum, b) => sum + b.billTotal);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions Bar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickAction('🛵 સવારનું સેલ', () => widget.onNavigate(1), AppColors.primary),
                _buildQuickAction('🏬 આવતીકાલની ખરીદી', () => widget.onNavigate(2), AppColors.warning),
                _buildQuickAction('👥 ગ્રાહક માસ્ટર', () => widget.onNavigate(3), AppColors.success),
                _buildQuickAction('🌴 રજા કેલેન્ડર', () => widget.onNavigate(4), AppColors.danger),
                _buildQuickAction('🧾 મહિનાનું બિલિંગ', () => widget.onNavigate(5), AppColors.purple),
                _buildQuickAction('💰 ઉઘરાણી / UPI', () => widget.onNavigate(6), AppColors.indigo),
              ],
            ),
            const SizedBox(height: 18),

            // Metrics Grid (6 KPI Cards)
            LayoutBuilder(
              builder: (ctx, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1000 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth >= 1000 ? 2.4 : 2.2,
                  children: [
                    _buildKpiCard(
                      'સવારે જોઈતા કુલ પેપર્સ',
                      '${todaySheet.totalCopies} નકલ',
                      'ગ્રાહક: ${todaySheet.totalCustomerCopies} + કાઉન્ટર: ${todaySheet.totalExtraCopies}',
                      Icons.newspaper,
                      AppColors.primary,
                    ),
                    _buildKpiCard(
                      'કુલ સક્રિય ગ્રાહકો',
                      '$activeCustCount ગ્રાહકો',
                      'કુલ લાઇન: ${db.routes.length}',
                      Icons.people_alt,
                      AppColors.success,
                    ),
                    _buildKpiCard(
                      'આજે રજા પર ગ્રાહકો',
                      '$activeVacationsCount ગ્રાહકો',
                      'આજના પેપર આપોઆપ રદ થયા',
                      Icons.beach_access,
                      AppColors.danger,
                    ),
                    _buildKpiCard(
                      'આ મહિનાનું કુલ બિલિંગ',
                      '₹${totalBilled.toStringAsFixed(0)}',
                      'કુલ જનરેટ થયેલા બિલ્સ',
                      Icons.receipt_long,
                      AppColors.purple,
                    ),
                    _buildKpiCard(
                      'કુલ જમા ઉઘરાણી',
                      '₹${totalCollected.toStringAsFixed(0)}',
                      'રોકડ અને UPI દ્વારા જમા',
                      Icons.account_balance_wallet,
                      AppColors.successLight,
                    ),
                    _buildKpiCard(
                      'કુલ બાકી રકમ (ઉઘરાણી)',
                      '₹${totalOutstanding.toStringAsFixed(0)}',
                      'બધા ગ્રાહકોની કુલ બાકી રકમ',
                      Icons.pending_actions,
                      AppColors.warning,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Today Demand Summary Table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.between,
                      children: [
                        Row(
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              t.translate('todayDemandSummary'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(DateTime.now()),
                            style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.borderDark),
                    const SizedBox(height: 8),

                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('પેપરનું નામ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                          Expanded(flex: 1, child: Text('નિયમિત નકલ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                          Expanded(flex: 1, child: Text('વધારાની નકલ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                          Expanded(flex: 1, child: Text('કુલ નકલ', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryDark))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Table Rows
                    if (todaySheet.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('આજે કોઈ પેપરની માંગણી નોંધાયેલ નથી')),
                      )
                    else
                      ...todaySheet.items.map((it) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text('${it.name} (${it.code})', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('${it.customerCopies}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('${it.extraCopies}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondaryDark)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text('${it.totalCopies}', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String title, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
