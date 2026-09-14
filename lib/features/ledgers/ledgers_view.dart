import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/customer.dart';
import '../../core/providers/app_providers.dart';

class LedgersView extends ConsumerStatefulWidget {
  const LedgersView({super.key});

  @override
  ConsumerState<LedgersView> createState() => _LedgersViewState();
}

class _LedgersViewState extends ConsumerState<LedgersView> {
  int? _selectedCustomerId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final db = ref.watch(databaseProvider);
    final firm = ref.watch(firmProvider);

    final filteredCustomers = customers.where((c) {
      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.trim().toLowerCase();
        return c.name.toLowerCase().contains(q) || c.custNo.toLowerCase().contains(q) || c.phone.contains(q);
      }
      return true;
    }).toList();

    // Auto select first customer
    if (_selectedCustomerId == null && filteredCustomers.isNotEmpty) {
      _selectedCustomerId = filteredCustomers.first.id;
    }

    final selectedCust = customers.cast<Customer?>().firstWhere((c) => c?.id == _selectedCustomerId, orElse: () => null);
    final ledgerEntries = selectedCust != null ? db.getCustomerLedger(selectedCust.id) : <CustomerLedgerEntry>[];

    final totalDebits = ledgerEntries.fold(0.0, (sum, e) => sum + e.debit);
    final totalCredits = ledgerEntries.fold(0.0, (sum, e) => sum + e.credit);
    final currentBalance = selectedCust?.currentBalance ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pane: Customer Selector List
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: AppColors.cardDark,
              border: Border(right: BorderSide(color: AppColors.cardBorderDark)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.menu_book, color: AppColors.primaryTeal, size: 20),
                          SizedBox(width: 8),
                          Text('ગ્રાહક ખાતાવહી (Khata)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'ગ્રાહક શોધો...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: AppColors.surfaceDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorderDark),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredCustomers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorderDark),
                    itemBuilder: (context, index) {
                      final c = filteredCustomers[index];
                      final isSelected = c.id == _selectedCustomerId;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryTeal.withOpacity(0.12),
                        title: Text(
                          c.name,
                          style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        ),
                        subtitle: Text(
                          '${c.custNo.isNotEmpty ? "#" + c.custNo + " | " : ""}${c.phone}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark),
                        ),
                        trailing: Text(
                          '₹${c.currentBalance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: c.currentBalance > 0 ? AppColors.errorRed : AppColors.successGreen,
                          ),
                        ),
                        onTap: () => setState(() => _selectedCustomerId = c.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Pane: Customer Statement
          Expanded(
            child: selectedCust == null
                ? const Center(child: Text('ગ્રાહક પસંદ કરો'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Profile & Actions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorderDark),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primaryTeal.withOpacity(0.2),
                                child: Text(selectedCust.name.isNotEmpty ? selectedCust.name[0] : 'G', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(selectedCust.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        if (selectedCust.custNo.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                            child: Text('કોડ #${selectedCust.custNo}', style: const TextStyle(fontSize: 11, color: AppColors.primaryTeal)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('મોબાઇલ: ${selectedCust.phone}  |  સરનામું: ${selectedCust.buildingAddress}', style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('કુલ બાકી લેણી રકમ', style: TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                                  Text(
                                    '₹${currentBalance.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.errorRed),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // WhatsApp Statement Button
                              ElevatedButton.icon(
                                onPressed: () => _sendWhatsAppStatement(context, selectedCust, ledgerEntries, firm),
                                icon: const Icon(Icons.chat, size: 16),
                                label: const Text('WhatsApp હિસાબ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.successGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Ledger Summary Cards
                        Row(
                          children: [
                            Expanded(child: _buildSummaryCard('કુલ બિલિંગ (Debits)', '₹${totalDebits.toStringAsFixed(0)}', Icons.add_circle, AppColors.accentGold)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSummaryCard('કુલ ચૂકવણી (Credits)', '₹${totalCredits.toStringAsFixed(0)}', Icons.remove_circle, AppColors.successGreen)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildSummaryCard('હાલની બાકી (Net Due)', '₹${currentBalance.toStringAsFixed(0)}', Icons.account_balance, AppColors.errorRed)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Ledger Statement Table
                        const Text('ખાતાવહી હિસાબ (Ledger Statement)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorderDark),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceDark,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 2, child: Text('તારીખ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                    Expanded(flex: 4, child: Text('વિગત (Description)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('રેફરન્સ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                    Expanded(flex: 2, child: Text('ઉધાર (Debit +)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGold))),
                                    Expanded(flex: 2, child: Text('જમા (Credit -)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successGreen))),
                                    Expanded(flex: 2, child: Text('બાકી રકમ (Balance)', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: AppColors.cardBorderDark),
                              if (ledgerEntries.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text('આ ગ્રાહક માટે કોઈ વ્યવહાર નોંધાયેલ નથી.'),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: ledgerEntries.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorderDark),
                                  itemBuilder: (context, idx) {
                                    final entry = ledgerEntries[idx];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 2, child: Text(entry.date, style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark))),
                                          Expanded(flex: 4, child: Text(entry.description, style: const TextStyle(fontSize: 13))),
                                          Expanded(flex: 2, child: Text(entry.referenceNo, style: const TextStyle(fontSize: 11, color: AppColors.primaryTeal))),
                                          Expanded(flex: 2, child: Text(entry.debit > 0 ? '₹${entry.debit.toStringAsFixed(0)}' : '-', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accentGold))),
                                          Expanded(flex: 2, child: Text(entry.credit > 0 ? '₹${entry.credit.toStringAsFixed(0)}' : '-', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.successGreen))),
                                          Expanded(flex: 2, child: Text('₹${entry.runningBalance.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                        ],
                                      ),
                                    );
                                  },
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
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderDark),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  void _sendWhatsAppStatement(BuildContext context, Customer cust, List<CustomerLedgerEntry> entries, dynamic firm) async {
    if (cust.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('આ ગ્રાહકનો મોબાઈલ નંબર ઉપલબ્ધ નથી.')));
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('📰 *${firm.name}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('નમસ્તે *${cust.name}*,');
    buffer.writeln('તમારા ન્યૂઝપેપર ખાતાનો હિસાબ નીચે મુજબ છે:');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    for (final e in entries.reversed.take(5)) {
      if (e.debit > 0) {
        buffer.writeln('• ${e.date}: ${e.description} = +₹${e.debit.toStringAsFixed(0)}');
      } else {
        buffer.writeln('• ${e.date}: ${e.description} = -₹${e.credit.toStringAsFixed(0)}');
      }
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *કુલ બાકી લેણી રકમ: ₹${cust.currentBalance.toStringAsFixed(0)}*');
    if (firm.upiId.isNotEmpty) {
      buffer.writeln('UPI ID: ${firm.upiId}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('આભાર સહ,');
    buffer.writeln('*${firm.name}*');

    final phoneClean = cust.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = phoneClean.length == 10 ? '91$phoneClean' : phoneClean;
    final url = Uri.parse('https://wa.me/$fullPhone?text=${Uri.encodeComponent(buffer.toString())}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
