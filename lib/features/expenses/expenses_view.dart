import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/expense.dart';
import '../../core/models/bank_account.dart';
import '../../core/providers/app_providers.dart';

class ExpensesView extends ConsumerStatefulWidget {
  const ExpensesView({super.key});

  @override
  ConsumerState<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends ConsumerState<ExpensesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  final Map<String, String> _categoryLabels = {
    'all': 'બધા ખર્ચા',
    'petrol': 'પેટ્રોલ / વાહન ખર્ચ',
    'tea_snacks': 'ડેપો / સ્ટાફ ચા-નાસ્તો',
    'salary': 'હોકર / સેલ્સમેન પગાર',
    'maintenance': 'રિપેરિંગ / મેઈન્ટેનન્સ',
    'rent': 'ઓફિસ ભાડું / લાઈટ બિલ',
    'misc': 'પરચુરણ ખર્ચ (Misc)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final bankAccounts = ref.watch(bankAccountsProvider);
    final bankTransactions = ref.watch(bankTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: AppColors.errorRed, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ખર્ચા અને બેંકિંગ વ્યવસ્થાપન',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        Text(
                          'રોજિંદા ખર્ચાઓ, હોકર પગાર, બેંક એકાઉન્ટ્સ અને પાસબુક લેજર',
                          style: TextStyle(fontSize: 13, color: AppColors.textMutedDark),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
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
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showAddBankModal(context),
                      icon: const Icon(Icons.account_balance, size: 18),
                      label: const Text('બેંક એકાઉન્ટ ઉમેરો'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryBlue,
                indicatorWeight: 3,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.textMutedDark,
                tabs: const [
                  Tab(icon: Icon(Icons.receipt_long), text: '૧. રોજિંદા ખર્ચાઓ (Expenses Tracker)'),
                  Tab(icon: Icon(Icons.account_balance), text: '૨. બેંક એકાઉન્ટ્સ અને પાસબુક (Banking & Ledger)'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Content
            SizedBox(
              height: 700,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExpensesTab(expenses),
                  _buildBankingTab(bankAccounts, bankTransactions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: EXPENSES ---
  Widget _buildExpensesTab(List<Expense> expenses) {
    final filteredExpenses = expenses.where((e) {
      if (_selectedCategory != 'all' && e.category != _selectedCategory) return false;
      return true;
    }).toList();

    final totalExpense = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final salaryExpense = expenses.where((e) => e.category == 'salary').fold<double>(0.0, (sum, e) => sum + e.amount);
    final fuelExpense = expenses.where((e) => e.category == 'petrol').fold<double>(0.0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        // KPI Summary Cards
        Row(
          children: [
            Expanded(child: _buildKpiCard('કુલ ખર્ચ', '₹${totalExpense.toStringAsFixed(0)}', AppColors.errorRed, Icons.money_off)),
            const SizedBox(width: 14),
            Expanded(child: _buildKpiCard('સેલ્સમેન / હોકર પગાર', '₹${salaryExpense.toStringAsFixed(0)}', AppColors.accentOrange, Icons.people)),
            const SizedBox(width: 14),
            Expanded(child: _buildKpiCard('પેટ્રોલ / વાહન ખર્ચ', '₹${fuelExpense.toStringAsFixed(0)}', AppColors.accentCyan, Icons.local_gas_station)),
          ],
        ),
        const SizedBox(height: 16),

        // Category Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categoryLabels.entries.map((entry) {
              final isSelected = _selectedCategory == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = entry.key);
                  },
                  selectedColor: AppColors.primaryBlue.withOpacity(0.25),
                  backgroundColor: AppColors.surfaceDark,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryBlue : AppColors.textLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Expenses Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: filteredExpenses.isEmpty
                ? const Center(child: Text('કોઈ ખર્ચ મળ્યો નથી.', style: TextStyle(color: AppColors.textMutedDark)))
                : ListView.separated(
                    itemCount: filteredExpenses.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.borderDark, height: 1),
                    itemBuilder: (context, idx) {
                      final exp = filteredExpenses[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.errorRed.withOpacity(0.15),
                          child: const Icon(Icons.receipt, color: AppColors.errorRed, size: 20),
                        ),
                        title: Text(exp.paidTo.isNotEmpty ? exp.paidTo : _categoryLabels[exp.category] ?? exp.category,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
                        subtitle: Text('${exp.date} • ${_categoryLabels[exp.category] ?? exp.category} • ${exp.remarks}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${exp.amount.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.errorRed),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMutedDark),
                              onPressed: () {
                                DatabaseService.instance.expenses.removeWhere((e) => e.id == exp.id);
                                notifyDbChanged(ref);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // --- TAB 2: BANKING & PASSBOOK ---
  Widget _buildBankingTab(List<BankAccount> bankAccounts, List<BankTransaction> bankTransactions) {
    final totalBalance = bankAccounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance);

    return Column(
      children: [
        // Bank KPI
        Row(
          children: [
            Expanded(
              child: _buildKpiCard('તમામ બેંક કુલ સિલક (Total Balance)', '₹${totalBalance.toStringAsFixed(0)}', AppColors.successGreen, Icons.account_balance),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              onPressed: () => _showAddTransactionModal(context),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('ડિપોઝિટ / ઉપાડ એન્ટ્રી'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bank Account Cards
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: bankAccounts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, idx) {
              final acc = bankAccounts[idx];
              return Container(
                width: 240,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(acc.bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight)),
                        const Icon(Icons.account_balance, size: 16, color: AppColors.primaryBlue),
                      ],
                    ),
                    Text(acc.accountNumber, style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark, fontFamily: 'monospace')),
                    Text('₹${acc.currentBalance.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Passbook Ledger History
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: bankTransactions.isEmpty
                ? const Center(child: Text('હજુ સુધી કોઈ બેંક ટ્રાન્ઝેક્શન નથી.', style: TextStyle(color: AppColors.textMutedDark)))
                : ListView.separated(
                    itemCount: bankTransactions.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.borderDark, height: 1),
                    itemBuilder: (context, idx) {
                      final tx = bankTransactions[idx];
                      final isDeposit = tx.type == 'deposit';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDeposit ? AppColors.successGreen.withOpacity(0.15) : AppColors.errorRed.withOpacity(0.15),
                          child: Icon(isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isDeposit ? AppColors.successGreen : AppColors.errorRed, size: 18),
                        ),
                        title: Text(tx.partyName.isNotEmpty ? tx.partyName : (isDeposit ? 'જમા (Deposit)' : 'ઉપાડ (Withdrawal)'),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
                        subtitle: Text('${tx.date} • ${tx.note} • Ref: ${tx.refNo}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                        trailing: Text(
                          '${isDeposit ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDeposit ? AppColors.successGreen : AppColors.errorRed,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  // --- MODALS ---
  void _showAddExpenseModal(BuildContext context) {
    final amountCtrl = TextEditingController();
    final paidToCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    String category = 'petrol';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('💸 નવો ખર્ચ ઉમેરો', style: TextStyle(color: AppColors.textLight)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: AppColors.surfaceDark,
                  decoration: const InputDecoration(labelText: 'ખર્ચ કેટેગરી'),
                  items: _categoryLabels.entries
                      .where((e) => e.key != 'all')
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (val) => setSt(() => category = val ?? 'petrol'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'રકમ (₹)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paidToCtrl,
                  decoration: const InputDecoration(labelText: 'કોને ચૂકવ્યા (Paid To)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarksCtrl,
                  decoration: const InputDecoration(labelText: 'નોંધ / વિગત (Remarks)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (amt > 0) {
                  DatabaseService.instance.expenses.add(Expense(
                    id: DateTime.now().millisecondsSinceEpoch,
                    date: DateTime.now().toIso8601String().split('T')[0],
                    category: category,
                    amount: amt,
                    paidTo: paidToCtrl.text.trim(),
                    paymentMode: 'cash',
                    remarks: remarksCtrl.text.trim(),
                  ));
                  notifyDbChanged(ref);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('સેવ કરો'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBankModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final accNoCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final balCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('🏦 નવું બેંક એકાઉન્ટ ઉમેરો', style: TextStyle(color: AppColors.textLight)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'બેંકનું નામ (દા.ત. SBI)')),
              const SizedBox(height: 12),
              TextField(controller: accNoCtrl, decoration: const InputDecoration(labelText: 'એકાઉન્ટ નંબર')),
              const SizedBox(height: 12),
              TextField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC કોડ')),
              const SizedBox(height: 12),
              TextField(controller: balCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'શરૂઆતની સિલક (₹)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
          ElevatedButton(
            onPressed: () {
              final bal = double.tryParse(balCtrl.text.trim()) ?? 0.0;
              if (nameCtrl.text.trim().isNotEmpty) {
                DatabaseService.instance.addBankAccount(BankAccount(
                  id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                  bankName: nameCtrl.text.trim(),
                  accountNumber: accNoCtrl.text.trim(),
                  ifsc: ifscCtrl.text.trim(),
                  initialBalance: bal,
                  currentBalance: bal,
                ));
                notifyDbChanged(ref);
                Navigator.pop(ctx);
              }
            },
            child: const Text('ઉમેરો'),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionModal(BuildContext context) {
    final amountCtrl = TextEditingController();
    final partyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'deposit';
    String selectedAccId = DatabaseService.instance.bankAccounts.isNotEmpty ? DatabaseService.instance.bankAccounts.first.id : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('🔄 બેંક ડિપોઝિટ / ઉપાડ એન્ટ્રી', style: TextStyle(color: AppColors.textLight)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  dropdownColor: AppColors.surfaceDark,
                  decoration: const InputDecoration(labelText: 'પ્રકાર (Type)'),
                  items: const [
                    DropdownMenuItem(value: 'deposit', child: Text('➕ જમા (Deposit)')),
                    DropdownMenuItem(value: 'withdrawal', child: Text('➖ ઉપાડ (Withdrawal)')),
                  ],
                  onChanged: (val) => setSt(() => type = val ?? 'deposit'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedAccId,
                  dropdownColor: AppColors.surfaceDark,
                  decoration: const InputDecoration(labelText: 'બેંક એકાઉન્ટ'),
                  items: DatabaseService.instance.bankAccounts
                      .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.bankName} (${a.accountNumber})')))
                      .toList(),
                  onChanged: (val) => setSt(() => selectedAccId = val ?? ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'રકમ (₹)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: partyCtrl,
                  decoration: const InputDecoration(labelText: 'પાર્ટીનું નામ / વિગત'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'નોંધ (Note)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                if (amt > 0 && selectedAccId.isNotEmpty) {
                  DatabaseService.instance.addBankTransaction(BankTransaction(
                    id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                    bankAccountId: selectedAccId,
                    date: DateTime.now().toIso8601String().split('T')[0],
                    type: type,
                    amount: amt,
                    partyName: partyCtrl.text.trim(),
                    note: noteCtrl.text.trim(),
                  ));
                  notifyDbChanged(ref);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('સબમિટ કરો'),
            ),
          ],
        ),
      ),
    );
  }
}
