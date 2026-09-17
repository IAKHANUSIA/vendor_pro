import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  DateTime _cashbookDate = DateTime.now();
  double _openingCash = 1500.0;
  String _selectedPlMonth = DateFormat('yyyy-MM').format(DateTime.now());

  final Map<String, String> _categoryLabels = {
    'all': 'બધા ખર્ચા',
    'petrol': 'પેટ્રોલ / વાહન ખર્ચ',
    'tea_snacks': 'ડેપો / સ્ટાફ ચા-નાસ્તો',
    'salary': 'વિતરક પગાર',
    'maintenance': 'રિપેરિંગ / મેઈન્ટેનન્સ',
    'rent': 'ઓફિસ ભાડું / લાઈટ બિલ',
    'misc': 'પરચુરણ ખર્ચ (Misc)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                          'ખર્ચા, બેંકિંગ અને કેશબુક વ્યવસ્થાપન',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        Text(
                          'રોજિંદા ખર્ચાઓ, વિતરક પગાર, બેંક એકાઉન્ટ્સ અને ડેઇલી ગલ્લા ક્લોઝિંગ મેળ',
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
                  Tab(icon: Icon(Icons.point_of_sale), text: '૩. ડેઇલી કેશ મેળ અને નફા-નુકસાન (Cashbook & P&L)'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Content
            SizedBox(
              height: 750,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExpensesTab(expenses),
                  _buildBankingTab(bankAccounts, bankTransactions),
                  _buildCashbookTab(),
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
            Expanded(child: _buildKpiCard('વિતરક પગાર', '₹${salaryExpense.toStringAsFixed(0)}', AppColors.accentOrange, Icons.people)),
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
  Widget _buildBankingTab(List<BankAccount> accounts, List<BankTransaction> transactions) {
    final totalBankBal = accounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance);

    return Column(
      children: [
        // Total Bank Balance Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B2B4A), Color(0xFF162033)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance, color: AppColors.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('કુલ બેંક બેલેન્સ (Total Bank Balance)',
                          style: TextStyle(fontSize: 13, color: AppColors.textMutedDark)),
                      Text(
                        '₹${totalBankBal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddTransactionModal(context),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('નવું ટ્રાન્ઝેક્શન (Deposit/Withdrawal)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Accounts List & Passbook Ledger Row
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Bank Accounts Cards
              Expanded(
                flex: 2,
                child: ListView.separated(
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final acc = accounts[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(acc.bankName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
                              const SizedBox(height: 4),
                              Text('A/C: ${acc.accountNumber} • ${acc.holderName}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                            ],
                          ),
                          Text(
                            '₹${acc.currentBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.successGreen),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Right: Recent Bank Transactions Passbook
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history, size: 18, color: AppColors.textMutedDark),
                          SizedBox(width: 8),
                          Text('બેંક પાસબુક સ્ટેટમેન્ટ (Recent Transactions)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: transactions.isEmpty
                            ? const Center(
                                child: Text('કોઈ ટ્રાન્ઝેક્શન નોંધાયેલ નથી.',
                                    style: TextStyle(color: AppColors.textMutedDark)))
                            : ListView.separated(
                                itemCount: transactions.length,
                                separatorBuilder: (_, __) => const Divider(color: AppColors.borderDark, height: 1),
                                itemBuilder: (context, idx) {
                                  final tx = transactions[idx];
                                  final isDeposit = tx.type == 'deposit';
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          (isDeposit ? AppColors.successGreen : AppColors.errorRed).withOpacity(0.15),
                                      child: Icon(
                                        isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isDeposit ? AppColors.successGreen : AppColors.errorRed,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(tx.partyName.isNotEmpty ? tx.partyName : (isDeposit ? 'જમા' : 'ઉપાડ'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight)),
                                    subtitle: Text('${tx.date} • ${tx.note}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                                    trailing: Text(
                                      '${isDeposit ? "+" : "-"}₹${tx.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDeposit ? AppColors.successGreen : AppColors.errorRed,
                                      ),
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
      ],
    );
  }

  // --- TAB 3: DAILY CASHBOOK & P&L ---
  Widget _buildCashbookTab() {
    final db = DatabaseService.instance;
    final dateStr = DateFormat('yyyy-MM-dd').format(_cashbookDate);
    final cashbook = db.getDailyCashbookSummary(dateStr, _openingCash);
    final pl = db.getMonthlyProfitLoss(_selectedPlMonth);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Controls: Date Picker & Opening Cash Editor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.point_of_sale, color: AppColors.accentGold, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💵 દૈનિક રોકડ મેળ (Daily Cashbook Closing)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            'તારીખ: ${DateFormat('dd/MM/yyyy').format(_cashbookDate)} ના ગલ્લાની શરૂઆત અને આખર રોકડ',
                            style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _cashbookDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _cashbookDate = picked);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.accentCyan),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd/MM/yyyy').format(_cashbookDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentGold),
                          foregroundColor: AppColors.accentGold,
                        ),
                        onPressed: () {
                          final ctrl = TextEditingController(text: _openingCash.toStringAsFixed(0));
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.bgCardDark,
                              title: const Text('✏️ સવારની શરૂઆતની રોકડ બદલો'),
                              content: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'શરૂઆતની રોકડ (₹)', prefixText: '₹'),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
                                ElevatedButton(
                                  onPressed: () {
                                    final val = double.tryParse(ctrl.text) ?? _openingCash;
                                    setState(() => _openingCash = val);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('સાચવો'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('શરૂઆતની રોકડ એડિટ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Daily Cash Flow KPI Cards
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
                  _buildKpiCard('સવારની શરૂઆત રોકડ', '₹${cashbook.openingCash.toStringAsFixed(2)}', AppColors.primaryLight, Icons.login),
                  _buildKpiCard('આજની રોકડ ઉઘરાણી (+)', '₹${cashbook.cashCollection.toStringAsFixed(2)}', AppColors.successGreen, Icons.add_circle_outline),
                  _buildKpiCard('આજના રોકડ ખર્ચા (-)', '₹${cashbook.cashExpenses.toStringAsFixed(2)}', AppColors.errorRed, Icons.remove_circle_outline),
                  _buildKpiCard('બેંકમાં જમા રોકડ (-)', '₹${cashbook.bankDeposits.toStringAsFixed(2)}', AppColors.accentCyan, Icons.account_balance),
                  _buildKpiCard('ગલ્લાની આખર રોકડ (Closing)', '₹${cashbook.closingCashInHand.toStringAsFixed(2)}', AppColors.accentGold, Icons.account_balance_wallet),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Inflow / Outflow Vouchers Breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Cash Collections Today
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_downward, color: AppColors.successGreen, size: 18),
                              SizedBox(width: 8),
                              Text('📥 આજની રોકડ આવક વાઉચર્સ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          Text('કુલ: ₹${cashbook.cashCollection.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      cashbook.todaysCashPayments.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('આ તારીખે કોઈ રોકડ ઉઘરાણી થયેલ નથી.', style: TextStyle(color: AppColors.textMutedDark))),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cashbook.todaysCashPayments.length,
                              separatorBuilder: (_, __) => const Divider(color: AppColors.borderDark, height: 1),
                              itemBuilder: (ctx, i) {
                                final p = cashbook.todaysCashPayments[i];
                                final cust = db.customers.cast<dynamic>().firstWhere((c) => c.id == p.customerId, orElse: () => null);
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(cust?.name ?? 'ગ્રાહક #${p.customerId}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                  subtitle: Text('પહોંચ નં. #${p.id} • ${p.notes}', style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                                  trailing: Text('+₹${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Right: Cash Expenses & Bank Deposits Today
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.arrow_upward, color: AppColors.errorRed, size: 18),
                              SizedBox(width: 8),
                              Text('📤 આજના રોકડ ખર્ચા અને બેંક જમા', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          Text('કુલ: ₹${cashbook.totalCashOutflow.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.errorRed)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      (cashbook.todaysCashExpenses.isEmpty && cashbook.todaysBankDeposits.isEmpty)
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text('આ તારીખે કોઈ રોકડ ખર્ચ થયેલ નથી.', style: TextStyle(color: AppColors.textMutedDark))),
                            )
                          : Column(
                              children: [
                                ...cashbook.todaysCashExpenses.map((e) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(e.paidTo.isNotEmpty ? e.paidTo : _categoryLabels[e.category] ?? e.category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                      subtitle: Text('${_categoryLabels[e.category] ?? e.category} • ${e.remarks}', style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                                      trailing: Text('-₹${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.errorRed)),
                                    )),
                                ...cashbook.todaysBankDeposits.map((t) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('બેંક જમા: ${t.partyName.isNotEmpty ? t.partyName : "Bank Deposit"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                                      subtitle: Text('બેંકમાં કેશ ડિપોઝિટ • ${t.note}', style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                                      trailing: Text('-₹${t.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)),
                                    )),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Monthly Profit & Loss Statement Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2838), Color(0xFF131A24)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.analytics, color: AppColors.accentGold, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 એજન્સી માસિક નફા-નુકસાન હિસાબ (Monthly P&L)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            Text(
                              'મહિનો: $_selectedPlMonth | ગ્રાહક બિલિંગ - પ્રેસ ખરીદી - સ્ટાફ પગાર - ખર્ચા = ચોખ્ખો નફો',
                              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),

                    DropdownButton<String>(
                      value: _selectedPlMonth,
                      dropdownColor: AppColors.bgCardDark,
                      items: [
                        DropdownMenuItem(value: DateFormat('yyyy-MM').format(DateTime.now()), child: Text('ચાલુ મહિનો (${DateFormat('MMMM yyyy').format(DateTime.now())})')),
                        DropdownMenuItem(value: DateFormat('yyyy-MM').format(DateTime.now().subtract(const Duration(days: 30))), child: Text('ગત મહિનો (${DateFormat('MMMM yyyy').format(DateTime.now().subtract(const Duration(days: 30)))})')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedPlMonth = v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // P&L Summary Cards
                Row(
                  children: [
                    Expanded(child: _buildKpiCard('કુલ ગ્રાહક બિલિંગ', '₹${pl.grossCustomerBilling.toStringAsFixed(0)}', AppColors.primaryLight, Icons.receipt)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildKpiCard('પ્રેસ ખરીદી ખર્ચ (-)', '₹${pl.netPressPurchaseCost.toStringAsFixed(0)}', AppColors.dangerLight, Icons.shopping_cart)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildKpiCard('વિતરક કમિશન/પગાર (-)', '₹${pl.totalSalesmanCommission.toStringAsFixed(0)}', AppColors.accentOrange, Icons.people)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildKpiCard('અન્ય એજન્સી ખર્ચા (-)', '₹${pl.totalOperatingExpenses.toStringAsFixed(0)}', AppColors.errorRed, Icons.money_off)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildKpiCard('ચોખ્ખો અંદાજિત નફો (Net)', '₹${pl.netEstimatedProfit.toStringAsFixed(0)}', AppColors.successLight, Icons.emoji_events)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String val, Color valColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMutedDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valColor)),
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
    String paymentMode = 'cash';
    String? selectedAccId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('➕ નવો ખર્ચ ઉમેરો', style: TextStyle(color: AppColors.textLight)),
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
                  decoration: const InputDecoration(labelText: 'રકમ (₹) *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paidToCtrl,
                  decoration: const InputDecoration(labelText: 'કોને ચૂકવ્યા (Paid To)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paymentMode,
                  dropdownColor: AppColors.surfaceDark,
                  decoration: const InputDecoration(labelText: 'ચુકવણી પદ્ધતિ (Mode)'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('💵 રોકડ (Cash Drawer)')),
                    DropdownMenuItem(value: 'bank', child: Text('🏦 બેંક ટ્રાન્સફર / UPI')),
                  ],
                  onChanged: (val) => setSt(() => paymentMode = val ?? 'cash'),
                ),
                if (paymentMode == 'bank') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedAccId,
                    dropdownColor: AppColors.surfaceDark,
                    decoration: const InputDecoration(labelText: 'બેંક એકાઉન્ટ પસંદ કરો'),
                    items: DatabaseService.instance.bankAccounts
                        .map((a) => DropdownMenuItem(value: a.id, child: Text('${a.bankName} (${a.accountNumber})')))
                        .toList(),
                    onChanged: (val) => setSt(() => selectedAccId = val),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: remarksCtrl,
                  decoration: const InputDecoration(labelText: 'નોંધ (Remarks)'),
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
                  final db = DatabaseService.instance;
                  final newId = db.expenses.isEmpty ? 1 : db.expenses.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
                  db.expenses.add(Expense(
                    id: newId,
                    date: DateTime.now().toIso8601String().split('T')[0],
                    category: category,
                    amount: amt,
                    paidTo: paidToCtrl.text.trim(),
                    paymentMode: paymentMode,
                    bankAccountId: paymentMode == 'bank' ? selectedAccId : null,
                    remarks: remarksCtrl.text.trim(),
                  ));
                  notifyDbChanged(ref);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('સાચવો'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'બેંકનું નામ (દા.ત. SBI, HDFC) *')),
            const SizedBox(height: 10),
            TextField(controller: accNoCtrl, decoration: const InputDecoration(labelText: 'એકાઉન્ટ નંબર *')),
            const SizedBox(height: 10),
            TextField(controller: ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC કોડ')),
            const SizedBox(height: 10),
            TextField(controller: balCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'શરૂઆતનું બેલેન્સ (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('રદ કરો')),
          ElevatedButton(
            onPressed: () {
              final bal = double.tryParse(balCtrl.text.trim()) ?? 0.0;
              if (nameCtrl.text.trim().isNotEmpty && accNoCtrl.text.trim().isNotEmpty) {
                DatabaseService.instance.bankAccounts.add(BankAccount(
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
