import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/bill.dart';
import '../../core/models/customer.dart';
import '../../core/models/firm.dart';
import '../../core/providers/app_providers.dart';

class WhatsAppExpressDialog extends ConsumerStatefulWidget {
  final List<Bill> monthBills;
  final Firm firm;
  final String monthYear;

  const WhatsAppExpressDialog({
    super.key,
    required this.monthBills,
    required this.firm,
    required this.monthYear,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Bill> monthBills,
    required Firm firm,
    required String monthYear,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WhatsAppExpressDialog(
        monthBills: monthBills,
        firm: firm,
        monthYear: monthYear,
      ),
    );
  }

  @override
  ConsumerState<WhatsAppExpressDialog> createState() => _WhatsAppExpressDialogState();
}

class _WhatsAppExpressDialogState extends ConsumerState<WhatsAppExpressDialog> {
  int? _selectedRouteId;
  String _statusFilter = 'pending_only'; // 'pending_only', 'all', 'sent_only'
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;
  final Set<int> _sentCustIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Bill> _getFilteredBills(Map<int, Customer> custMap) {
    return widget.monthBills.where((b) {
      if (_selectedRouteId != null && b.routeId != _selectedRouteId) return false;

      final isSent = _sentCustIds.contains(b.customerId);
      if (_statusFilter == 'pending_only' && isSent) return false;
      if (_statusFilter == 'sent_only' && !isSent) return false;

      if (_searchController.text.trim().isNotEmpty) {
        final q = _searchController.text.trim().toLowerCase();
        final cName = b.customerName.toLowerCase();
        final cNo = b.customerNo.toLowerCase();
        final bNo = b.billNo.toLowerCase();
        if (!cName.contains(q) && !cNo.contains(q) && !bNo.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  String _generateMessageText(Bill bill, Customer? cust, Firm firm) {
    final upiPayee = firm.name.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '').trim();
    final upiUrl = firm.upiId.isNotEmpty
        ? 'upi://pay?pa=${Uri.encodeComponent(firm.upiId)}&pn=${Uri.encodeComponent(upiPayee.isNotEmpty ? upiPayee : "VendorSoft")}&am=${bill.finalPayable.toStringAsFixed(0)}&cu=INR&tn=Bill-${bill.billNo}'
        : '';

    final paperItems = bill.paperBreakdown.values
        .map((p) => '${p.name} (${p.daysCount} d = ₹${p.totalCost.toStringAsFixed(0)})')
        .join(', ');

    final buffer = StringBuffer();
    buffer.writeln('📰 *${firm.name.toUpperCase()}*');
    if (firm.address.isNotEmpty) buffer.writeln('📍 ${firm.address}');
    if (firm.phone.isNotEmpty) buffer.writeln('📞 મો: ${firm.phone}');
    buffer.writeln('--------------------------------');
    buffer.writeln('🧾 *ગ્રાહક માસિક બિલ - ${bill.monthYear}*');
    buffer.writeln('👤 નામ: *${bill.customerName}* (કોડ #${bill.customerNo})');
    if (cust != null && cust.address.isNotEmpty) {
      buffer.writeln('🏠 સરનામું: ${cust.address}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('📦 વિતરણ દિવસ: ${bill.deliveryDays} દિવસ');
    if (paperItems.isNotEmpty) {
      buffer.writeln('📰 પેપર્સ: $paperItems');
    }
    buffer.writeln('💰 ચાલુ બિલ: ₹${bill.currentPaperCost.toStringAsFixed(0)}');
    if (bill.deliveryCharge > 0) {
      buffer.writeln('🛵 વિતરણ ચાર્જ: ₹${bill.deliveryCharge.toStringAsFixed(0)}');
    }
    if (bill.vacationDays > 0) {
      buffer.writeln('🌴 રજા કપાત (${bill.vacationDays} દિવસ): -₹${bill.vacationDeduction.toStringAsFixed(0)}');
    }
    if (bill.pastBalance > 0) {
      buffer.writeln('⏳ જૂની બાકી રકમ: ₹${bill.pastBalance.toStringAsFixed(0)}');
    }
    buffer.writeln('================================');
    buffer.writeln('💵 *કુલ ચૂકવવાપાત્ર રકમ: ₹${bill.finalPayable.toStringAsFixed(0)}*');
    buffer.writeln('================================');
    if (upiUrl.isNotEmpty) {
      buffer.writeln('📲 *Scan & 1-Tap UPI Payment Link:*');
      buffer.writeln(upiUrl);
      buffer.writeln('');
      buffer.writeln('💡 (GPay / PhonePe / Paytm / BHIM દ્વારા સીધું ચૂકવો)');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('✈️ પેમેન્ટ કર્યા પછી સ્ક્રીનશોટ અહીં મોકલવા વિનંતી. આભાર!');

    return buffer.toString();
  }

  void _sendCurrentBill(Bill bill, Customer? cust, String msg) async {
    final phone = cust?.phone ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${bill.customerName} નો મોબાઈલ નંબર મળ્યો નથી.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final uri = Uri.parse('https://wa.me/$fullPhone?text=${Uri.encodeComponent(msg)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() {
        _sentCustIds.add(bill.customerId);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp ખોલી શકાયું નથી.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ક્લિપબોર્ડમાં કોપી થઈ ગયું!'),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final routes = ref.watch(routesProvider);
    final custMap = {for (var c in customers) c.id: c};

    final filtered = _getFilteredBills(custMap);
    if (_currentIndex >= filtered.length && filtered.isNotEmpty) {
      _currentIndex = filtered.length - 1;
    }

    final totalBills = widget.monthBills.length;
    final sentCount = _sentCustIds.length;
    final progressPercent = totalBills > 0 ? (sentCount / totalBills) : 0.0;

    final currentBill = filtered.isNotEmpty && _currentIndex < filtered.length
        ? filtered[_currentIndex]
        : null;
    final currentCust = currentBill != null ? custMap[currentBill.customerId] : null;
    final currentMsg = currentBill != null
        ? _generateMessageText(currentBill, currentCust, widget.firm)
        : '';

    return Dialog(
      backgroundColor: AppColors.bgDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorderDark),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 1000,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Modal Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.rocket_launch, color: AppColors.successGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'WhatsApp Express બિલ ડિસ્પેચર',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ઓટો-ક્યૂ ⚡',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.monthYear} ના ગ્રાહકોને ક્રમશઃ માત્ર ૧-ક્લિકમાં બિલ મોકલો',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMutedDark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Toolbar: Filters, Route selector & Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border(bottom: BorderSide(color: AppColors.cardBorderDark)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Route Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorderDark),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _selectedRouteId,
                            hint: const Text('બધી લાઇનો', style: TextStyle(fontSize: 12)),
                            dropdownColor: AppColors.cardDark,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('બધી લાઇનો (All Routes)')),
                              ...routes.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text('${r.code} - ${r.name}'))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedRouteId = val;
                                _currentIndex = 0;
                              });
                            },
                          ),
                        ),
                      ),
                      // Status Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorderDark),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _statusFilter,
                            dropdownColor: AppColors.cardDark,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                            items: const [
                              DropdownMenuItem(value: 'pending_only', child: Text('⏳ માત્ર બાકી (Pending)')),
                              DropdownMenuItem(value: 'all', child: Text('📋 બધા ગ્રાહકો (All)')),
                              DropdownMenuItem(value: 'sent_only', child: Text('✅ મોકલાઈ ગયેલ (Sent)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _statusFilter = val;
                                  _currentIndex = 0;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      // Search field
                      SizedBox(
                        width: 140,
                        height: 36,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'શોધો...',
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 16),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            filled: true,
                            fillColor: AppColors.cardDark,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          onChanged: (_) => setState(() => _currentIndex = 0),
                        ),
                      ),
                    ],
                  ),
                  // Reset status button
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _sentCustIds.clear();
                        _currentIndex = 0;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('WhatsApp સેન્ટ સ્ટેટસ રીસેટ થઈ ગયું.')),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 14, color: AppColors.accentGold),
                    label: const Text('સ્ટેટસ રીસેટ', style: TextStyle(fontSize: 11, color: AppColors.accentGold)),
                  ),
                ],
              ),
            ),

            // Progress Bar Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: AppColors.cardDark.withOpacity(0.5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'પ્રગતિ: $sentCount / $totalBills મોકલાયા (${(progressPercent * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                      ),
                      Text(
                        'ક્યૂમાં બાકી: ${filtered.length}',
                        style: const TextStyle(fontSize: 12, color: AppColors.accentGold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: AppColors.cardBorderDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area (Left: Customer Details & Queue Control, Right: Live WhatsApp Text Preview)
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: AppColors.successGreen.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'બધા પસંદ કરેલા ગ્રાહકોને બિલ મોકલાઈ ગયા છે! 🎉',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'ફિલ્ટર બદલો અથવા ઉપરથી "સ્ટેટસ રીસેટ" કરો.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Panel: Current Customer Card & Fire Buttons
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Customer Info Card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardDark,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.cardBorderDark),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryTeal.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              'ક્રમ #${currentBill!.customerNo}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                                            ),
                                          ),
                                          Text(
                                            'ક્યૂ: ${_currentIndex + 1} / ${filtered.length}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        currentBill.customerName,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currentCust?.address ?? 'સરનામું ઉપલબ્ધ નથી',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.phone, size: 14, color: AppColors.successGreen),
                                              const SizedBox(width: 6),
                                              Text(
                                                currentCust?.phone.isNotEmpty == true ? currentCust!.phone : 'મોબાઈલ નથી',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'બિલ: ${currentBill.billNo}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      // Net Due Highlight Box
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.successGreen.withOpacity(0.15),
                                              AppColors.primaryTeal.withOpacity(0.15),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.successGreen.withOpacity(0.4)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'કુલ ભરવાપાત્ર રકમ (NET DUE)',
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMutedDark),
                                                ),
                                                Text(
                                                  '(પેપર્સ + જૂની બાકી + ડિલિવરી)',
                                                  style: TextStyle(fontSize: 9, color: AppColors.textMutedDark),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '₹${currentBill.finalPayable.toStringAsFixed(0)}',
                                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.successGreen),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Big Send Action Button
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _sendCurrentBill(currentBill, currentCust, currentMsg);
                                    if (_currentIndex < filtered.length - 1) {
                                      setState(() {
                                        _currentIndex++;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.send, size: 20),
                                  label: const Text(
                                    'હાલનું બિલ WhatsApp કરો & આગળ વધો (Next)',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.successGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Prev, Skip, Copy Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _currentIndex > 0
                                            ? () => setState(() => _currentIndex--)
                                            : null,
                                        icon: const Icon(Icons.skip_previous, size: 16),
                                        label: const Text('અગાઉનું (Prev)'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _currentIndex < filtered.length - 1
                                            ? () => setState(() => _currentIndex++)
                                            : null,
                                        icon: const Icon(Icons.skip_next, size: 16),
                                        label: const Text('સ્કીપ (Skip)'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _copyToClipboard(currentMsg, 'WhatsApp મેસેજ'),
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text('કોપી'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryTeal,
                                        side: const BorderSide(color: AppColors.primaryTeal),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Right Panel: Live Message Preview in WhatsApp Chat Bubble Style
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorderDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.successGreen),
                                          SizedBox(width: 6),
                                          Text(
                                            'WhatsApp મેસેજ પ્રિવ્યૂ',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      if (widget.firm.upiId.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryTeal.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('UPI Link Attached', style: TextStyle(fontSize: 9, color: AppColors.primaryTeal)),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 18, color: AppColors.cardBorderDark),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF075E54).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFF128C7E).withOpacity(0.3)),
                                      ),
                                      child: SingleChildScrollView(
                                        child: SelectableText(
                                          currentMsg,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.45,
                                            fontFamily: 'monospace',
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
