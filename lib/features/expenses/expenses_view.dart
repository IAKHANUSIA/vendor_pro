import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/expense.dart';
import '../../core/providers/app_providers.dart';

class ExpensesView extends ConsumerStatefulWidget {
  const ExpensesView({super.key});

  @override
  ConsumerState<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends ConsumerState<ExpensesView> {
  String _selectedCategory = 'all';

  final Map<String, String> _categoryLabels = {
    'all': 'બધા ખર્ચા',
    'hawker_salary': 'સેલ્સમેન / હોકર પગાર',
    'depot_tea_snack': 'ડેપો ચા-નાસ્તો',
    'fuel_transport': 'પેટ્રોલ / વાહન ખર્ચ',
    'stationary': 'સ્ટેશનરી / પ્રિન્ટિંગ',
    'misc': 'પરચુરણ ખર્ચ (Misc)',
  };

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);

    final filteredExpenses = expenses.where((e) {
      if (_selectedCategory != 'all' && e.category != _selectedCategory) return false;
      return true;
    }).toList();

    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final salaryExpense = expenses.where((e) => e.category == 'hawker_salary').fold(0.0, (sum, e) => sum + e.amount);
    final depotExpense = expenses.where((e) => e.category == 'depot_tea_snack').fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt, color: AppColors.errorRed, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'રોજિંદા ખર્ચાઓ (Expenses Tracker)',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        Text(
                          'હોકર પગાર, ડેપો ચા-નાસ્તો, પેટ્રોલ અને અન્ય એજન્સી ખર્ચ',
                          style: TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddExpenseModal(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('નવો ખર્ચ ઉમેરો'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;
                return GridView.count(
                  crossAxisCount: isNarrow ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isNarrow ? 1.8 : 2.6,
                  children: [
                    _buildKpiCard('કુલ માસિક ખર્ચ', '₹${totalExpense.toStringAsFixed(0)}', Icons.account_balance_wallet, AppColors.errorRed, '${expenses.length} એન્ટ્રીઓ'),
                    _buildKpiCard('હોકર / સેલ્સમેન પગાર', '₹${salaryExpense.toStringAsFixed(0)}', Icons.people, AppColors.accentGold, 'વિતરણ મહેનતાણું'),
                    _buildKpiCard('ડેપો / ચા-નાસ્તો', '₹${depotExpense.toStringAsFixed(0)}', Icons.coffee, AppColors.primaryTeal, 'રોજિંદો ખર્ચ'),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Category Filter Pills
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorderDark),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categoryLabels.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return ChoiceChip(
                    label: Text(entry.value, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: AppColors.errorRed.withOpacity(0.25),
                    backgroundColor: AppColors.surfaceDark,
                    onSelected: (_) => setState(() => _selectedCategory = entry.key),
                    side: BorderSide(color: isSelected ? AppColors.errorRed : Colors.transparent),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Expense Records List
            if (filteredExpenses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Column(
                  children: [
                    Icon(Icons.money_off, size: 64, color: AppColors.textMutedDark.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('કોઈ ખર્ચ નોંધાયેલ નથી.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('નવો ખર્ચ ઉમેરવા માટે ઉપર આપેલ બટન દબાવો.', style: TextStyle(color: AppColors.textMutedDark)),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredExpenses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorderDark),
                  itemBuilder: (context, index) {
                    final exp = filteredExpenses[index];
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_downward, color: AppColors.errorRed, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exp.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  'કેટેગરી: ${_categoryLabels[exp.category] ?? exp.category}  |  તારીખ: ${exp.date}  |  પદ્ધતિ: ${exp.paymentMode.toUpperCase()}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                                ),
                                if (exp.notes.isNotEmpty)
                                  Text('નોંધ: ${exp.notes}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMutedDark)),
                              ],
                            ),
                          ),
                          Text('₹${exp.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.errorRed)),
                        ],
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

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, String subtext) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(subtext, style: const TextStyle(fontSize: 10, color: AppColors.textMutedDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context) {
    String title = '';
    double amount = 0.0;
    String category = 'depot_tea_snack';
    String mode = 'cash';
    String notes = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Row(
            children: [
              Icon(Icons.add_shopping_cart, color: AppColors.errorRed),
              SizedBox(width: 10),
              Text('નવો ખર્ચ નોંધો'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'ખર્ચનું નામ / વિગત *', hintText: 'દા.ત. ડેપો સવારનો ચા-નાસ્તો'),
                  onChanged: (v) => title = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'ખર્ચ રકમ (₹) *'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => amount = double.tryParse(v) ?? 0.0,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'કેટેગરી પસંદ કરો', isDense: true),
                  dropdownColor: AppColors.cardDark,
                  items: const [
                    DropdownMenuItem(value: 'depot_tea_snack', child: Text('ડેપો ચા-નાસ્તો')),
                    DropdownMenuItem(value: 'hawker_salary', child: Text('સેલ્સમેન / હોકર પગાર')),
                    DropdownMenuItem(value: 'fuel_transport', child: Text('પેટ્રોલ / વાહન ખર્ચ')),
                    DropdownMenuItem(value: 'stationary', child: Text('સ્ટેશનરી / પ્રિન્ટિંગ')),
                    DropdownMenuItem(value: 'misc', child: Text('પરચુરણ ખર્ચ (Misc)')),
                  ],
                  onChanged: (v) => setModalState(() => category = v ?? 'misc'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: mode,
                  decoration: const InputDecoration(labelText: 'ચૂકવણી પદ્ધતિ (Mode)', isDense: true),
                  dropdownColor: AppColors.cardDark,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('રોકડ (Cash)')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI (GPay / PhonePe)')),
                    DropdownMenuItem(value: 'bank', child: Text('બેંક ટ્રાન્સફર / ચેક')),
                  ],
                  onChanged: (v) => setModalState(() => mode = v ?? 'cash'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'વધારાની નોંધ (Notes)'),
                  onChanged: (v) => notes = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton.icon(
              onPressed: () {
                if (title.isEmpty || amount <= 0) return;
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                db.expenses.add(Expense(
                  id: DateTime.now().millisecondsSinceEpoch,
                  date: DateTime.now().toIso8601String().split('T')[0],
                  category: category,
                  title: title,
                  amount: amount,
                  paymentMode: mode,
                  notes: notes,
                ));
                notifyDbChanged(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('₹${amount.toStringAsFixed(0)} નો ખર્ચ સફળતાપૂર્વક નોંધાઈ ગયો!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('નોંધ કરો'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            ),
          ],
        ),
      ),
    );
  }
}
